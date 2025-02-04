import Flutter
import UIKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import MobileCoreServices
import SDWebImageWebPCoder

public class VideoThumbnailPlugin: NSObject, FlutterPlugin {
    
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "video_thumbnail_plugin", binaryMessenger: registrar.messenger())
        let instance = VideoThumbnailPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "generateImageThumbnail":
            handleImageThumbnail(call: call, result: result)
        case "generateGifThumbnail":
            handleGifThumbnail(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleImageThumbnail(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let videoPath = arguments["videoPath"] as? String,
              let thumbnailPath = arguments["thumbnailPath"] as? String,
              let width = arguments["width"] as? Int,
              let height = arguments["height"] as? Int,
              let format = arguments["format"] as? Int,
              let quality = arguments["quality"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required parameters", details: nil))
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let success = self.generateImageThumbnail(videoPath: videoPath, thumbnailPath: thumbnailPath, width: width, height: height, format: format, quality: quality)
            DispatchQueue.main.async {
                result(success)
            }
        }
    }
    
    private func handleGifThumbnail(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let videoPath = arguments["videoPath"] as? String,
              let thumbnailPath = arguments["thumbnailPath"] as? String,
              let width = arguments["width"] as? Int,
              let height = arguments["height"] as? Int,
              let frameCount = arguments["frameCount"] as? Int,
              let delay = arguments["delay"] as? Int,
              let repeatCount = arguments["repeat"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing required parameters", details: nil))
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let success = self.generateGifThumbnail(videoPath: videoPath, thumbnailPath: thumbnailPath, width: width, height: height, frameCount: frameCount, delay: delay, repeatCount: repeatCount)
            DispatchQueue.main.async {
                result(success)
            }
        }
    }
    
    private func generateImageThumbnail(videoPath: String, thumbnailPath: String, width: Int, height: Int, format: Int, quality: Int) -> Bool {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        
        do {
            let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            var image = UIImage(cgImage: cgImage)
            
            image = resizeImage(image: image, width: width, height: height)
            return saveImage(image: image, path: thumbnailPath, format: format, quality: quality)
        } catch {
            print("Error generating image thumbnail: \(error.localizedDescription)")
            return false
        }
    }
    
    private func generateGifThumbnail(videoPath: String, thumbnailPath: String, width: Int, height: Int, frameCount: Int, delay: Int, repeatCount: Int) -> Bool {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        
        let duration = asset.duration.seconds
        let frameInterval = duration / Double(frameCount)
        
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: delay / 1000.0,
                kCGImagePropertyGIFLoopCount as String: repeatCount
            ]
        ]
        
        let destinationURL = URL(fileURLWithPath: thumbnailPath)
        let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypeGIF, frameCount, nil)
        
        for i in 0..<frameCount {
            let time = CMTime(seconds: frameInterval * Double(i), preferredTimescale: 600)
            do {
                let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                var image = UIImage(cgImage: cgImage)
                
                image = resizeImage(image: image, width: width, height: height)
                CGImageDestinationAddImage(destination!, image.cgImage!, gifProperties as CFDictionary)
            } catch {
                print("Error generating GIF thumbnail: \(error.localizedDescription)")
                return false
            }
        }
        
        return CGImageDestinationFinalize(destination!)
    }
    
    private func resizeImage(image: UIImage, width: Int?, height: Int?) -> UIImage {
        var newWidth = width
        var newHeight = height
        
        if newWidth == nil && newHeight == nil {
            return image
        }
        
        if let newWidth = newWidth {
            let aspectRatio = image.size.height / image.size.width
            newHeight = Int(Double(newWidth) * aspectRatio)
        }
        
        if let newHeight = newHeight {
            let aspectRatio = image.size.width / image.size.height
            newWidth = Int(Double(newHeight) * aspectRatio)
        }
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth!, height: newHeight!))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth!, height: newHeight!))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func saveImage(image: UIImage, path: String, format: Int, quality: Int) -> Bool {
        guard let data = image.jpegData(compressionQuality: CGFloat(quality) / 100.0) else { return false }
        
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return false
        }
    }
}
