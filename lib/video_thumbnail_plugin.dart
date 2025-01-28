import 'dart:async';

import 'package:flutter/services.dart';

class VideoThumbnailPlugin {
  static const MethodChannel _channel = MethodChannel('video_thumbnail_plugin');

  static Future<String?> generateThumbnail({
    required String videoPath,
    required String thumbnailPath,
    required String type, // "image" or "gif"
    String format = "jpg", // "png" or "jpeg" or "webp"
  }) async {
    final String? result = await _channel.invokeMethod('generateThumbnail', {
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'type': type,
      'format': format,
    });
    return result;
  }
}
