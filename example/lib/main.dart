import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:video_thumbnail_plugin/video_thumbnail_plugin.dart';

void main() => runApp(MyApp());

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

  Future<void> generateThumbnails() async {
   
    setState(() { isGenerating = true;});
   
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      videoPath = result.files.single.path!;
      imageThumbnailPath = '${result.files.single.path}.jpg';
      gifThumbnailPath = '${result.files.single.path}.gif';

      // Generate image thumbnail
      String? imageThumbnail = await VideoThumbnailPlugin.generateThumbnail(
        videoPath: videoPath,
        thumbnailPath: imageThumbnailPath,
        type: 'image',
      );
      debugPrint('Image Thumbnail: $imageThumbnail');

      // Generate GIF thumbnail
      String? gifThumbnail = await VideoThumbnailPlugin.generateThumbnail(
        videoPath: videoPath,
        thumbnailPath: gifThumbnailPath,
        type: 'gif',
        format: 'png',
      );
      debugPrint('GIF Thumbnail: $gifThumbnail');
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No file selected'),
          ),
        );
      }
    }
    setState(() { isGenerating = false;});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Video Thumbnail Plugin Example'),
        ),
        body: isGenerating
            ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                        GifView.memory(
                            File(gifThumbnailPath).readAsBytesSync()),
                      ElevatedButton(
                          onPressed: generateThumbnails,
                          child: Text('Generate Thumbnails')),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
