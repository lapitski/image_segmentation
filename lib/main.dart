import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Center(
      child: ElevatedButton(
        onPressed: _takePhoto,
        child: const Text('Take a photo'),
      ),
    ));
  }

  _takePhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return ImageSegmenter(image.path);
      }));
    }
  }
}

class ImageSegmenter extends StatelessWidget {
  final String imagePath;
  const ImageSegmenter(this.imagePath, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image segmentation'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300.0,
              child: Image.file(File(imagePath)),
            ),
            FutureBuilder<Widget?>(
                future: _segmentPhoto(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.data == null || snapshot.hasError) {
                    return const Center(child: Text('No data'));
                  }
                  return snapshot.data!;
                })
          ],
        ),
      ),
    );
  }

  Future<Widget?> _segmentPhoto() async {
    final image = InputImage.fromFile(File(imagePath));
    final segmenter = SelfieSegmenter(
      mode: SegmenterMode.stream,
      enableRawSizeMask: true,
    );
    final mask = await segmenter.processImage(image);

    segmenter.close();
    if (mask != null) {
      log('mask confidences:');
      log(mask.confidences.toString());
      //return await _convertSegmentationMaskToImage(mask);
    }
    return null;
  }

  Future<Widget> _convertSegmentationMaskToImage(
      SegmentationMask segmentationMask) async {
    // Convert segmentation mask to ui.Image
    final ui.Image maskImage = await _convertToImage(segmentationMask);

    // Return a widget that uses the custom painter
    return CustomPaint(
      size: Size(maskImage.width.toDouble(), maskImage.height.toDouble()),
      painter: SegmentationMaskPainter(maskImage),
    );
  }

  Future<ui.Image> _convertToImage(SegmentationMask segmentationMask) async {
    // Assuming segmentationMask contains a buffer of the pixel data and the dimensions of the mask
    final int width = segmentationMask.width;
    final int height = segmentationMask.height;
    final Uint8List pixelData = Uint8List.fromList([]);

    ///TODO convert
    // final Uint8List pixelData =
    //     Uint8List.fromList(segmentationMask.confidences);

    // Completer is used because the decodeImageFromPixels is asynchronous
    final Completer<ui.Image> completer = Completer();

    // Decode the pixel data to a ui.Image
    ui.decodeImageFromPixels(
      pixelData,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    return completer.future;
  }
}

class SegmentationMaskPainter extends CustomPainter {
  final ui.Image maskImage;

  SegmentationMaskPainter(this.maskImage);

  @override
  void paint(Canvas canvas, Size size) {
    // Create a paint object with blend mode to apply the mask
    Paint paint = Paint()..blendMode = BlendMode.dstIn;

    // Draw the mask image onto the canvas
    canvas.drawImage(maskImage, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
