import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_thumbnail_plugin/video_thumbnail_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelVideoThumbnailPlugin platform =
      MethodChannelVideoThumbnailPlugin();
  const MethodChannel channel = MethodChannel('video_thumbnail_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
