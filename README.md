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
  video_thumbnail_plugin: ^0.0.5
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
String format = ImageFormat.jpg;

final status = await VideoThumbnailPlugin.generateImageThumbnail(
  videoPath: videoPath, // Specify the path or url to the video file from which to generate the thumbnail.
  thumbnailPath: imageThumbnailPath, // Specify the path where the generated thumbnail image will be saved.
  format: format, // Specify the format: 'jpg', 'png', or 'webp'
  width: 100, // Specify the width of the thumbnail
  height: 100, // Specify the height of the thumbnail
  quality: 95, // Specify the quality of the thumbnail image, with a range from 1 to 100. Higher values indicate better quality.
);

if(status) {
  print('Image Thumbnail: $imageThumbnailPath');
} else {
  print('Image Thumbnail generation failed');
}
```

### Generating GIF Thumbnail

```dart
String videoPath = '/path/to/your/video.mp4';
String gifThumbnailPath = '/path/to/your/gif_thumbnail.gif';

final status = await VideoThumbnailPlugin.generateGifThumbnail(
  videoPath: videoPath, // Specify the path or url to the video file from which to generate the GIF thumbnail.
  thumbnailPath: gifThumbnailPath, // Specify the path where the generated GIF thumbnail will be saved.
  width: 100, // Specify the width of the thumbnail
  height: 100, // Specify the height of the thumbnail
  frameCount: 10, // Specify the number of frames here
  delay: 100, // Specify the delay between frames in milliseconds
);
if(status) {
  print('GIF Thumbnail: $gifThumbnailPath');
} else {
  print('GIF Thumbnail generation failed');
}
```

## Platform-Specific Implementation

### Android

- Uses `MediaMetadataRetriever` to extract frames from the video.
- Encodes frames into GIF using `AnimatedGifEncoder`.

### iOS

- Uses `AVAssetImageGenerator` to extract frames from the video.
- Encodes frames into GIF using `ImageIO`.

## Author

- [**Sumit Kumar**](https://github.com/sumitsharansatsangi)

  <a href="https://github.com/sumitsharansatsangi">
  <img src="https://avatars.githubusercontent.com/u/45959281?v=4" width="100px;" alt=""/>
  </a>

## Support this project

Please ⭐️ this repository if this project helped you!

If you find any bugs or issues while using the plugin, please register an issues on GitHub. You can also contact us at sharansumitkumar@gmail.com.

## Contributions

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## License

MIT License