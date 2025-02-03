## 0.0.4

* Added support for generating GIF thumbnails and Image from video files or URL or Assets.
* Removed Parameter `multiProcess` from `generateGifThumbnail` method.
* Changed the return type of the `generateGifThumbnail` and `generateImageThumbnail` methods from void to bool, so that the method returns a boolean value indicating whether the thumbnail generation was successful or not.

## 0.0.3

* Removed `plugin_platform_interface` dependency.
* `format` parameter is now an enum instead of a string.
* `frameCount`, `quality`, `delay`, and `repeat` parameters are now added as optional parameters to the generateGifThumbnail method.
* Changed the return type of the generateImageThumbnail and generateGifThumbnail methods from String? to void.
* Bug Fixes.

## 0.0.2

* Updated Documentation.

## 0.0.1

* Initial release.
