import 'dart:async';
import 'package:flutter/services.dart';

/// A Flutter plugin for generating image and GIF thumbnails from videos.
class VideoThumbnailPlugin {
  // Channel used for communicating with the platform-specific code.
  static const MethodChannel _channel = MethodChannel('video_thumbnail_plugin');

  /// Generates an image thumbnail from a video.
  ///
  /// This method generates a thumbnail image from a specified video file.
  ///
  /// [videoPath] specifies the path to the video file from which to generate the thumbnail.
  /// [thumbnailPath] specifies the path where the generated thumbnail image will be saved.
  /// [width] is an optional parameter that specifies the desired width of the thumbnail image. If null, the width will be proportional to the video's aspect ratio.
  /// [height] is an optional parameter that specifies the desired height of the thumbnail image. If null, the height will be proportional to the video's aspect ratio.
  /// [quality] is an optional parameter that specifies the quality of the thumbnail image, with a range from 1 to 100. Higher values indicate better quality.
  /// [format] specifies the format of the thumbnail image. The default format is PNG. Supported formats are PNG, JPG, and WEBP.
  ///
  /// Returns a [Future] that completes with `true` if the thumbnail is generated successfully, otherwise `false`.
  static Future<bool> generateImageThumbnail({
    required String videoPath,
    required String thumbnailPath,
    int? width,
    int? height,
    int? quality,
    Format format = Format.png, // Can be "png", "jpg", or "webp"
  }) async {
    return await _channel.invokeMethod<bool>('generateImageThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'format': format.index,
      'width': width,
      'height': height,
      'quality': quality,
    }) ?? false;
  }

  /// Generates a GIF thumbnail from a video.
  ///
  /// This method generates a GIF thumbnail from a specified video file by extracting multiple frames.
  ///
  /// [videoPath] specifies the path to the video file from which to generate the GIF thumbnail.
  /// [thumbnailPath] specifies the path where the generated GIF thumbnail will be saved.
  /// [width] is an optional parameter that specifies the desired width of the GIF thumbnail. If null, the width will be proportional to the video's aspect ratio.
  /// [height] is an optional parameter that specifies the desired height of the GIF thumbnail. If null, the height will be proportional to the video's aspect ratio.
  /// [frameCount] is an optional parameter that specifies the number of frames to include in the GIF. More frames result in a smoother GIF.
  /// [quality] is an optional parameter that specifies the quality of the GIF frames, with a range from 1 to 100. Higher values indicate better quality.
  /// [delay] is an optional parameter that specifies the delay between frames in milliseconds.
  /// [repeat] is an optional parameter that specifies the number of times the GIF should repeat. A value of 0 means repeat forever.
 ///
  /// Returns a [Future] that completes with `true` if the GIF thumbnail is generated successfully, otherwise `false`.
  static Future<bool> generateGifThumbnail({
    required String videoPath,
    required String thumbnailPath,
    int? width,
    int? height,
    int? frameCount,
    int? quality,
    int? delay,
    int? repeat = 0, // 0 means repeat forever
  }) async {
    return await _channel.invokeMethod<bool>('generateGifThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'width': width,
      'height': height,
      'frameCount': frameCount,
      'quality': quality,
      'delay': delay,
      'repeat': repeat,
    }) ?? false;
  }
}

/// An enumeration representing the supported image formats.
enum Format {
  png, // PNG format
  jpg, // JPG format
  webp // WEBP format
}
