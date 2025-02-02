import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:video_thumbnail_plugin/video_thumbnail_plugin.dart';

void main() =>
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String videoPath = '';
  String imageThumbnailPath = '';
  String gifThumbnailPath = '';
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> generateImageThumbnail() async {
    setState(() {
      isGenerating = true;
    });

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      videoPath = result.files.single.path!;
      imageThumbnailPath = '${result.files.single.path}.jpg';

      // Generate image thumbnail
      await VideoThumbnailPlugin.generateImageThumbnail(
        videoPath: videoPath,
        thumbnailPath: imageThumbnailPath,
        format: Format.jpg,
      );
      debugPrint('Image Thumbnail: $imageThumbnailPath');
      setState(() {});
    } else {
      Future.delayed(Duration.zero, () {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
            ),
          );
        }
      });
    }

    setState(() {
      isGenerating = false;
    });
  }

  Future<void> generateGifThumbnail() async {
    setState(() {
      isGenerating = true;
    });

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      videoPath = result.files.single.path!;
      gifThumbnailPath = '${result.files.single.path}.gif';

      // Generate GIF thumbnail
      await VideoThumbnailPlugin.generateGifThumbnail(
        videoPath: videoPath,
        thumbnailPath: gifThumbnailPath,
        frameCount: 10, // Specify the number of frames here
      );
      debugPrint('GIF Thumbnail: $gifThumbnailPath');

      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected'),
          ),
        );
      }
    }

    setState(() {
      isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Thumbnail Plugin Example'),
      ),
      body: isGenerating
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                Text('Generating Thumbnails...'),
                Text("Please wait..."),
              ],
            ))
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (imageThumbnailPath.isNotEmpty)
                      Image.file(File(imageThumbnailPath)),
                    if (gifThumbnailPath.isNotEmpty)
                      GifView.memory(File(gifThumbnailPath).readAsBytesSync()),
                    ElevatedButton(
                        onPressed: generateImageThumbnail,
                        child: const Text('Generate Image Thumbnails')),
                    ElevatedButton(
                        onPressed: generateGifThumbnail,
                        child: const Text('Generate Gif Thumbnails')),
                  ],
                ),
              ),
            ),
    );
  }
}
