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
            print("Invalid URL: \(url)")
            completion(nil)
            return
        }
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        let task = URLSession.shared.downloadTask(with: videoURL) { location, response, error in
            if let error = error {
                print("Failed to download video: \(error.localizedDescription)")
                completion(nil)
            } else if let location = location {
                do {
                    try FileManager.default.moveItem(at: location, to: tempFileURL)
                    completion(tempFileURL.path)
                } catch {
                    print("Failed to move downloaded video: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                print("Unknown error downloading video")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func generateGifThumbnail(videoPath: String, thumbnailPath: String, width: Int?, height: Int?, frameCount: Int, delay: Int, repeatCount: Int) -> Bool {
        let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
        if asset.isPlayable == false {
            // print("Video asset is not playable.")
            return false
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let duration = CMTimeGetSeconds(asset.duration)
        let frameInterval = duration / Double(frameCount)
        
        let fileURL = URL(fileURLWithPath: thumbnailPath)
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypeGIF, frameCount, nil) else {
            print("Failed to create GIF destination")
            return false
        }
        
        let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: repeatCount]]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        for i in 0..<frameCount {
            let time = CMTimeMakeWithSeconds(Double(i) * frameInterval, preferredTimescale: 600)
            do {
                let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
                guard let resizedImage = resizeImage(imageRef, width: width, height: height) else {
                    // print("Failed to resize image at frame \(i)")
                    continue
                }
                let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay / 1000]]
                CGImageDestinationAddImage(destination, resizedImage, frameProperties as CFDictionary)
            } catch {
                print("Failed to get frame at time: \(time)")
            }
        }
        
        return CGImageDestinationFinalize(destination)
    }
    
    private func generateImageThumbnail(videoPath: String, thumbnailPath: String, timeMs: Int, width: Int?, height: Int?) -> Bool {
         let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
         if asset.isPlayable == false {
        // print("Video asset is not playable.")
            return false
         }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(Double(timeMs) / 1000.0, preferredTimescale: 600)
        
        do {
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            guard let resizedImage = resizeImage(imageRef, width: width, height: height) else {
                print("Failed to resize image")
                return false
            }
            let imageData = UIImage(cgImage: resizedImage).pngData()
            try imageData?.write(to: URL(fileURLWithPath: thumbnailPath))
            return true
        } catch {
            print("Failed to generate image thumbnail")
            return false
        }
    }

    private func resizeImage(_ image: CGImage, width: Int?, height: Int?) -> CGImage? {
        let originalWidth = image.width
        let originalHeight = image.height
        
        let newWidth = width ?? originalWidth
        let newHeight = height ?? originalHeight
        
        guard let context = CGContext(data: nil,
                                      width: newWidth,
                                      height: newHeight,
                                      bitsPerComponent: image.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: image.bitmapInfo.rawValue) else {
            print("Failed to create CGContext")
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        return context.makeImage()
    }
}
