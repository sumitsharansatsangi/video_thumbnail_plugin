import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail_plugin/video_thumbnail_plugin.dart';

void main() =>
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int selectedIndex = 0;
  String imageThumbnailPath = '';
  String gifThumbnailPath = '';
  bool isGenerating = false;
  bool isGeneratedSuccessfully = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> generateImageThumbnail(String videoPath) async {
    // Generate image thumbnail
    final status = await VideoThumbnailPlugin.generateImageThumbnail(
      videoPath: videoPath,
      thumbnailPath: imageThumbnailPath,
      format: Format.jpg,
    );
    setState(() {
      isGeneratedSuccessfully = status;
    });
    debugPrint('Image Thumbnail: $imageThumbnailPath');
  }

  Future<void> generateGifThumbnail(String videoPath) async {
    // Generate GIF thumbnail
  final status = await VideoThumbnailPlugin.generateGifThumbnail(
      videoPath: videoPath,
      thumbnailPath: gifThumbnailPath,
      frameCount: 10, // Specify the number of frames here
    );
    setState(() {
      isGeneratedSuccessfully = status;
    });
    debugPrint('GIF Thumbnail: $gifThumbnailPath');
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
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      RadioMenuButton(
                        value: 0,
                        groupValue: selectedIndex,
                        onChanged: (value) {
                          imageThumbnailPath = '';
                          gifThumbnailPath = '';
                          if (value == null) return;
                          setState(() {
                            selectedIndex = value;
                          });
                        },
                        child: const Text('File'),
                      ),
                      RadioMenuButton(
                        value: 1,
                        groupValue: selectedIndex,
                        onChanged: (value) {
                          imageThumbnailPath = '';
                          gifThumbnailPath = '';
                          if (value == null) return;
                          setState(() {
                            selectedIndex = value;
                          });
                        },
                        child: const Text('Asset'),
                      ),
                      RadioMenuButton(
                        value: 2,
                        groupValue: selectedIndex,
                        onChanged: (value) {
                          imageThumbnailPath = '';
                          gifThumbnailPath = '';
                          if (value == null) return;
                          setState(() {
                            selectedIndex = value;
                          });
                        },
                        child: const Text('Network'),
                      ),
                    ]),
                    if (imageThumbnailPath.isNotEmpty)
                      Image.file(File(imageThumbnailPath)),
                    if (gifThumbnailPath.isNotEmpty)
                      Image.file(File(gifThumbnailPath)),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () async {
                          gifThumbnailPath = '';
                          setState(() {
                            isGenerating = true;
                          });
                          if (selectedIndex == 0) {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(type: FileType.video);
                            if (result != null &&
                                result.files.single.path != null) {
                              imageThumbnailPath =
                                  '${result.files.single.path!}.jpg';
                              await generateImageThumbnail(
                                  result.files.single.path!);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No file selected'),
                                  ),
                                );
                              }
                            }
                          } else if (selectedIndex == 1) {
                            final temp = await getTemporaryDirectory();
                            imageThumbnailPath =
                                (await File('${temp.path}/video.mp4.jpg')
                                        .create(recursive: true))
                                    .path;
                            generateImageThumbnail("assets/mov_bbb.mp4");
                          } else if (selectedIndex == 2) {
                            final temp = await getTemporaryDirectory();
                            imageThumbnailPath =
                                (await File('${temp.path}/video.mp4.jpg')
                                        .create(recursive: true))
                                    .path;
                            generateImageThumbnail(
                                "https://www.w3schools.com/html/mov_bbb.mp4");
                          }
                          setState(() {
                            isGenerating = false;
                          });
                        },
                        child: const Text('Generate Image Thumbnails')),
                    ElevatedButton(
                        onPressed: () async {
                          imageThumbnailPath = '';
                          setState(() {
                            isGenerating = true;
                          });

                          if (selectedIndex == 0) {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(type: FileType.video);
                            if (result != null &&
                                result.files.single.path != null) {
                              gifThumbnailPath =
                                  '${result.files.single.path!}.gif';
                              await generateGifThumbnail(
                                  result.files.single.path!);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No file selected'),
                                  ),
                                );
                              }
                            }
                          } else if (selectedIndex == 1) {
                            final temp = await getTemporaryDirectory();
                            gifThumbnailPath =
                                (await File('${temp.path}/video.mp4.gif')
                                        .create(recursive: true))
                                    .path;
                            generateGifThumbnail("assets/mov_bbb.mp4");
                          } else if (selectedIndex == 2) {
                            final temp = await getTemporaryDirectory();
                            gifThumbnailPath =
                                (await File('${temp.path}/video.mp4.gif')
                                        .create(recursive: true))
                                    .path;
                            generateGifThumbnail(
                                "https://www.w3schools.com/html/mov_bbb.mp4");
                          }
                          setState(() {
                            isGenerating = false;
                          });
                        },
                        child: const Text('Generate Gif Thumbnails')),
                  ],
                ),
              ),
            ),
    );
  }
}
