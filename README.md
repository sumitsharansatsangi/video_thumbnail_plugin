# Video Thumbnail Plugin

A Flutter plugin to generate image and GIF thumbnails from video files. This plugin supports multiple image formats including JPEG, PNG, and WebP.

## Features

- Generate image thumbnails from video files in JPEG, PNG, and WebP formats.
- Generate GIF thumbnails from video files.
- Cross-platform support (Android and iOS).

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  video_thumbnail_plugin: ^0.0.2+1
```

If you want to use the latest version, add this instead:

```yaml
dependencies:
  video_thumbnail_plugin:
    git:
      url: https://github.com/sumitsharansatsangi/video_thumbnail_plugin.git
```

Then, run `flutter pub get` to fetch the package.

## Usage

Import the package in your Dart code:

```dart
import 'package:video_thumbnail_plugin/video_thumbnail_plugin.dart';
```

### Generating Image Thumbnail

```dart
String videoPath = '/path/to/your/video.mp4';
String imageThumbnailPath = '/path/to/your/image_thumbnail.jpg';

// Specify the format: 'jpg', 'png', or 'webp'
String format = 'jpg';

String? imageThumbnail = await VideoThumbnailPlugin.generateImageThumbnail(
  videoPath: videoPath,
  thumbnailPath: imageThumbnailPath,
  format: format,
  width: 100,
  height: 100,
  quality: 95,
);

print('Image Thumbnail: $imageThumbnail');
```

### Generating GIF Thumbnail

```dart
String videoPath = '/path/to/your/video.mp4';
String gifThumbnailPath = '/path/to/your/gif_thumbnail.gif';

String? gifThumbnail = await VideoThumbnailPlugin.generateGifThumbnail(
  videoPath: videoPath,
  thumbnailPath: gifThumbnailPath,
  width: 100,
  height: 100,
  multiProcess: true, // Multi-process is used for generating GIF thumbnails, default is true
);

print('GIF Thumbnail: $gifThumbnail');
```

## Platform-Specific Implementation

### Android

- Uses `MediaMetadataRetriever` to extract frames from the video.
- Encodes frames into GIF using `AnimatedGifEncoder`.

### iOS

- Uses `AVAssetImageGenerator` to extract frames from the video.
- Encodes frames into GIF using `ImageIO`.

## Contributions

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

MIT License

---

Feel free to customize the repository URL and add any additional sections or information you think might be useful. Let me know if you need any more help!