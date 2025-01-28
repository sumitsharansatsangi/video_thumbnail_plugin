import 'package:flutter_test/flutter_test.dart';
// import 'package:video_thumbnail_plugin/video_thumbnail_plugin.dart';
import 'package:video_thumbnail_plugin/video_thumbnail_plugin_platform_interface.dart';
import 'package:video_thumbnail_plugin/video_thumbnail_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoThumbnailPluginPlatform
    with MockPlatformInterfaceMixin
    implements VideoThumbnailPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VideoThumbnailPluginPlatform initialPlatform = VideoThumbnailPluginPlatform.instance;

  test('$MethodChannelVideoThumbnailPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVideoThumbnailPlugin>());
  });

  test('getPlatformVersion', () async {
    // VideoThumbnailPlugin videoThumbnailPlugin = VideoThumbnailPlugin();
    MockVideoThumbnailPluginPlatform fakePlatform = MockVideoThumbnailPluginPlatform();
    VideoThumbnailPluginPlatform.instance = fakePlatform;

  });
}
