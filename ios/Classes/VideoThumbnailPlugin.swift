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
      let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)
        if call.method == "generateImageThumbnail" {
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let thumbnailPath = args["thumbnailPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments received", details: nil))
                return
            }
            let width = args["width"] as? CGFloat
            let height = args["height"] as? CGFloat
            let format = args["format"] as? Int ?? 0
            let quality = args["quality"] as? CGFloat ?? 1.0
            
            let thumbnail = generateImageThumbnail(videoPath: videoPath, thumbnailPath: thumbnailPath, width: width, height: height, format: format, quality: quality)
            result(thumbnail)
        } else if call.method == "generateGifThumbnail" {
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let thumbnailPath = args["thumbnailPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments received", details: nil))
                return
            }
            let width = args["width"] as? CGFloat
            let height = args["height"] as? CGFloat
            let frameCount = args["frameCount"] as? Int ?? 10
            let delay = args["delay"] as? Int ?? 100
            let repeatCount = args["repeat"] as? Int ?? 0
            
            let gifPath = generateGifThumbnail(videoPath: videoPath, thumbnailPath: thumbnailPath, width: width, height: height, frameCount: frameCount, delay: delay, repeatCount: repeatCount)
            result(gifPath)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func generateImageThumbnail(videoPath: String, thumbnailPath: String, width: CGFloat?, height: CGFloat?, format: Int, quality: CGFloat) -> String? {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try generator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 600), actualTime: nil)
            var image = UIImage(cgImage: cgImage)
            
            if let width = width, let height = height {
                image = image.resized(to: CGSize(width: width, height: height))
            }
            
            let imageData: Data?
            switch format {
            case 0: imageData = image.pngData()
            case 2: imageData = image.webpData(quality: CGFloat(quality) / 100.0) 
            default: imageData = image.jpegData(compressionQuality: quality)
            }
            
            if let data = imageData {
                try data.write(to: URL(fileURLWithPath: thumbnailPath))
                return thumbnailPath
            }
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        return nil
    }
    
    private func generateGifThumbnail(videoPath: String, thumbnailPath: String, width: CGFloat?, height: CGFloat?, frameCount: Int, delay: Int, repeatCount: Int) -> String? {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let frameInterval = CMTime(seconds: asset.duration.seconds / Double(frameCount), preferredTimescale: 600)
        let fileURL = URL(fileURLWithPath: thumbnailPath)

        let gifType: CFString

        if #available(iOS 14, *) {
          gifType = UTType.gif.identifier as CFString
        } else {
          gifType = kUTTypeGIF
        }
        
        guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, gifType, frameCount, nil) else {
            return nil
        }
        
        let properties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: repeatCount
            ]
        ] as CFDictionary
        CGImageDestinationSetProperties(destination, properties)
        
        for i in 0..<frameCount {
            let time = CMTimeMultiply(frameInterval, multiplier: Int32(i))
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                var image = UIImage(cgImage: cgImage)
                if let width = width, let height = height {
                    image = image.resized(to: CGSize(width: width, height: height))
                }
                
                let frameProperties = [
                    kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: Double(delay) / 1000.0
                    ]
                ] as CFDictionary
                CGImageDestinationAddImage(destination, image.cgImage!, frameProperties)
            } catch {
                print("Error extracting frame: \(error)")
            }
        }
        
        if CGImageDestinationFinalize(destination) {
            return thumbnailPath
        }
        return nil
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
    func webpData(quality: CGFloat) -> Data? {
        return SDImageWebPCoder.shared.encodedData(with: self, format: .webP, options: [.compressionQuality: quality])
    }
}
