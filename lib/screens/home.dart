import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_segmentation/router.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _MainAppState();
}

class _MainAppState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: ElevatedButton(
        onPressed: _takePhoto,
        child: const Text('Take a photo'),
      ),
    ));
  }

  _takePhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      context
          .go(Routes.home + Routes.segmenter, extra: {'imagePath': image.path});
    }
  }
}