import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_thumbnail_plugin_platform_interface.dart';

/// An implementation of [VideoThumbnailPluginPlatform] that uses method channels.
class MethodChannelVideoThumbnailPlugin extends VideoThumbnailPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_thumbnail_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
