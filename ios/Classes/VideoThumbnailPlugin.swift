import Flutter
import UIKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import MobileCoreServices
import SDWebImageWebPCoder

public class VideoThumbnailPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "video_thumbnail_plugin", binaryMessenger: registrar.messenger())
        let instance = VideoThumbnailPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "generateGifThumbnail":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let thumbnailPath = args["thumbnailPath"] as? String,
                  let frameCount = args["frameCount"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required parameters", details: nil))
                return
            }
            
            let width = args["width"] as? Int
            let height = args["height"] as? Int
            let delay = args["delay"] as? Int ?? 100
            let repeatCount = args["repeat"] as? Int ?? 0
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.handleVideoInput(videoPath: videoPath) { localPath in
                    if let localPath = localPath {
                        let success = self.generateGifThumbnail(videoPath: localPath, thumbnailPath: thumbnailPath, width: width, height: height, frameCount: frameCount, delay: delay, repeatCount: repeatCount)
                        DispatchQueue.main.async {
                            result(success)
                        }
                    } else {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "DOWNLOAD_FAILED", message: "Failed to download video", details: nil))
                        }
                    }
                }
            }
        case "generateImageThumbnail":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let thumbnailPath = args["thumbnailPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required parameters", details: nil))
                return
            }
            
            let timeMs = args["timeMs"] as? Int ?? 1000
            let width = args["width"] as? Int
            let height = args["height"] as? Int
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.handleVideoInput(videoPath: videoPath) { localPath in
                    if let localPath = localPath {
                        let success = self.generateImageThumbnail(videoPath: localPath, thumbnailPath: thumbnailPath, timeMs: timeMs, width: width, height: height)
                        DispatchQueue.main.async {
                            result(success)
                        }
                    } else {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "DOWNLOAD_FAILED", message: "Failed to download video", details: nil))
                        }
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleVideoInput(videoPath: String, completion: @escaping (String?) -> Void) {
        if videoPath.starts(with: "http") {
            downloadVideo(from: videoPath, completion: completion)
        } else {
            completion(videoPath)
        }
    }
    
    private func downloadVideo(from url: String, completion: @escaping (String?) -> Void) {
        guard let videoURL = URL(string: url) else {
            completion(nil)
            return
        }
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        let task = URLSession.shared.downloadTask(with: videoURL) { location, response, error in
            if let location = location {
                do {
                    try FileManager.default.moveItem(at: location, to: tempFileURL)
                    completion(tempFileURL.path)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func generateGifThumbnail(videoPath: String, thumbnailPath: String, width: Int?, height: Int?, frameCount: Int, delay: Int, repeatCount: Int) -> Bool {
        guard let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath)) else { return false }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let duration = CMTimeGetSeconds(asset.duration)
        let frameInterval = duration / Double(frameCount)
        
        let fileURL = URL(fileURLWithPath: thumbnailPath)
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypeGIF, frameCount, nil) else { return false }
        
        let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: repeatCount]]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        for i in 0..<frameCount {
            let time = CMTimeMakeWithSeconds(Double(i) * frameInterval, preferredTimescale: 600)
            do {
                let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
                let resizedImage = resizeImage(imageRef, width: width, height: height)
                let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay / 1000.0]]
                CGImageDestinationAddImage(destination, resizedImage, frameProperties as CFDictionary)
            } catch {
                print("Failed to get frame at time: \(time)")
            }
        }
        
        return CGImageDestinationFinalize(destination)
    }
    
    private func generateImageThumbnail(videoPath: String, thumbnailPath: String, timeMs: Int, width: Int?, height: Int?) -> Bool {
        guard let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath)) else { return false }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(Double(timeMs) / 1000.0, preferredTimescale: 600)
        
        do {
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            let resizedImage = resizeImage(imageRef, width: width, height: height)
            let imageData = UIImage(cgImage: resizedImage).pngData()
            try imageData?.write(to: URL(fileURLWithPath: thumbnailPath))
            return true
        } catch {
            print("Failed to generate image thumbnail")
            return false
        }
    }
}

