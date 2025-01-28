import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_thumbnail_plugin_method_channel.dart';

abstract class VideoThumbnailPluginPlatform extends PlatformInterface {
  /// Constructs a VideoThumbnailPluginPlatform.
  VideoThumbnailPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoThumbnailPluginPlatform _instance = MethodChannelVideoThumbnailPlugin();

  /// The default instance of [VideoThumbnailPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoThumbnailPlugin].
  static VideoThumbnailPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoThumbnailPluginPlatform] when
  /// they register themselves.
  static set instance(VideoThumbnailPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
