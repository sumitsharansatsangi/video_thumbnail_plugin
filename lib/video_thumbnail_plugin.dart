import 'dart:async';

import 'package:flutter/services.dart';

class VideoThumbnailPlugin {
  static const MethodChannel _channel = MethodChannel('video_thumbnail_plugin');

  static Future<void> generateImageThumbnail({
    required String videoPath,
    required String thumbnailPath,
    int? width,
    int? height,
    int? quality,
    Format format = Format.png, // "png" or "jpg" or "webp"
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
      "multiProcess": multiProcess,
    });
  }
}

enum Format { png, jpg, webp }
