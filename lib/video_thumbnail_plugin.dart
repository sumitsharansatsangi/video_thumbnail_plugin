import 'dart:async';

import 'package:flutter/services.dart';

class VideoThumbnailPlugin {
  static const MethodChannel _channel = MethodChannel('video_thumbnail_plugin');

  static Future<String?> generateImageThumbnail({
    required String videoPath,
    required String thumbnailPath,
    required String type,
    int? width,
    int? height,
    int? quality,
    String format = "jpg", // "png" or "jpeg" or "webp"
  }) async {
    final String? result =
        await _channel.invokeMethod('generateImageThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'format': format,
      'width': width,
      'height': height,
      'quality': quality,
    });
    return result;
  }

  static Future<String?> generateGifThumbnail({
    required String videoPath,
    required String thumbnailPath,
    int? width,
    int? height,
  }) async {
    final String? result = await _channel.invokeMethod('generateGifThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'width': width,
      'height': height,
      "multiProcess": true,
    });
    return result;
  }
}
