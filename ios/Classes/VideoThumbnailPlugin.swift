import Flutter
import UIKit
import AVFoundation
import ImageIO

public class SwiftVideoThumbnailPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_thumbnail_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftVideoThumbnailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments received", details: nil))
        return
    }
    if call.method == "generateThumbnail" {
      guard let videoPath = args["videoPath"] as? String,
            let thumbnailPath = args["thumbnailPath"] as? String,
            let type = args["type"] as? String
            let format = args["format"] as? String  else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments received", details: nil))
          return
      }

      if type == "image" {
        result(generateImageThumbnail(videoPath: videoPath, thumbnailPath: thumbnailPath, format: format))
      } else if type == "gif" {
        result(generateGifThumbnail(videoPath: videoPath, thumbnailPath: thumbnailPath))
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  private func generateImageThumbnail(videoPath: String, thumbnailPath: String, format: String) -> String? {
    let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let time = CMTime(seconds: 1, preferredTimescale: 60)
    do {
      let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
      let uiImage = UIImage(cgImage: cgImage)
      let data: Data?
      switch format.lowercased() {
        case "png":
          data = uiImage.pngData()
        default:
          data = uiImage.jpegData(compressionQuality: 0.9)
      }
      try data?.write(to: URL(fileURLWithPath: thumbnailPath))
      return thumbnailPath
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }

  private func generateGifThumbnail(videoPath: String, thumbnailPath: String) -> String? {
    let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true

    let fileURL = URL(fileURLWithPath: thumbnailPath)
    guard let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, kUTTypeGIF, 0, nil) else {
        return nil
    }

    let properties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary
    CGImageDestinationSetProperties(destination, properties)

    let frameInterval = CMTime(seconds: 1, preferredTimescale: 60)
    var time = CMTime.zero

    while time < asset.duration {
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0.1]] as CFDictionary
            CGImageDestinationAddImage(destination, cgImage, frameProperties)
        } catch {
            print(error.localizedDescription)
        }
        time = CMTimeAdd(time, frameInterval)
    }

    if !CGImageDestinationFinalize(destination) {
        print("Failed to finalize the GIF destination")
        return nil
    }

    return thumbnailPath
  }
}
