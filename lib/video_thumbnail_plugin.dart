import 'dart:async';
import 'package:flutter/services.dart';

/// A Flutter plugin for generating image and GIF thumbnails from videos.
class VideoThumbnailPlugin {
  // Channel used for communicating with the platform-specific code.
  static const MethodChannel _channel = MethodChannel('video_thumbnail_plugin');

  /// Generates an image thumbnail from a video.
  ///
  /// [videoPath] is the path to the video file.
  /// [thumbnailPath] is the path where the generated thumbnail image will be saved.
  /// [width] is the optional width for the thumbnail image.
  /// [height] is the optional height for the thumbnail image.
  /// [quality] is the optional quality for the thumbnail image (1-100).
  /// [format] is the format of the thumbnail image (default is PNG).
  static Future<void> generateImageThumbnail({
    required String videoPath,
    required String thumbnailPath,
    int? width,
    int? height,
    int? quality,
    Format format = Format.png, // Can be "png", "jpg", or "webp"
  }) async {
    await _channel.invokeMethod('generateImageThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'format': format.index,
      'width': width,
      'height': height,
      'quality': quality,
    });
  }

  /// Generates a GIF thumbnail from a video.
  ///
  /// [videoPath] is the path to the video file.
  /// [thumbnailPath] is the path where the generated GIF thumbnail will be saved.
  /// [width] is the optional width for the GIF thumbnail.
  /// [height] is the optional height for the GIF thumbnail.
  /// [frameCount] is the optional number of frames to include in the GIF.
  /// [quality] is the optional quality for the GIF frames.
  /// [delay] is the optional delay between frames in milliseconds.
  /// [repeat] is the optional number of times the GIF should repeat (0 means repeat forever, default is 0).
  /// [multiProcess] is a flag indicating whether to use multiprocessing for GIF generation (default is true).
  static Future<void> generateGifThumbnail({
    required String videoPath,
    required String thumbnailPath,
    int? width,
    int? height,
    int? frameCount,
    int? quality,
    int? delay,
    int? repeat = 0, // 0 means repeat forever
    bool multiProcess = true,
  }) async {
    await _channel.invokeMethod('generateGifThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'width': width,
      'height': height,
      'frameCount': frameCount,
      'quality': quality,
      'delay': delay,
      'repeat': repeat,
      'multiProcess': multiProcess,
    });
  }
}

/// An enumeration representing the supported image formats.
enum Format {
  png, // PNG format
  jpg, // JPG format
  webp // WEBP format
}
