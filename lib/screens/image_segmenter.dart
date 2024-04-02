import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';



class ImageSegmenter extends StatelessWidget {
  final String imagePath;
  const ImageSegmenter(this.imagePath, {super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
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
                future: _segmentPhoto(size),
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

  Future<Widget?> _segmentPhoto(Size size) async {
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
      return await _convertSegmentationMaskToImage(mask, size);
    }
    return null;
  }

  Future<Widget> _convertSegmentationMaskToImage(
      SegmentationMask segmentationMask, Size size) async {
  
    return CustomPaint(
      painter: SegmentationPainter(
        mask: segmentationMask,
        size: size,
        imageSize: size,
        rotation: InputImageRotation.rotation0deg,
        color: Colors.purple,
      ),
      child: Container(
        width: size.width,
        height: size.height,
      ),
    );
  }
}

class SegmentationPainter extends CustomPainter {
  final SegmentationMask mask;
  final Size size;
  final Size imageSize;
  final Color color;
  final InputImageRotation rotation;

  SegmentationPainter({
    required this.mask,
    required this.size,
    required this.imageSize,
    required this.color,
    this.rotation = InputImageRotation.rotation0deg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    final width = mask.width;
    final height = mask.height;
    final confidences = mask.confidences;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int tx = transformX(x.toDouble(), size).round();
        int ty = transformY(y.toDouble(), size).round();

        double opacity = confidences[(y * width) + x] * 0.25;
        paint..color = color.withOpacity(opacity);
        canvas.drawCircle(Offset(tx.toDouble(), ty.toDouble()), 1, paint);
      }
    }
  }

  double transformX(double x, Size size) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / imageSize.height;
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / imageSize.height;
      default:
        return x * size.width / imageSize.width;
    }
  }

  double transformY(double y, Size size) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / imageSize.width;
      default:
        return y * size.height / imageSize.height;
    }
  }

  @override
  bool shouldRepaint(SegmentationPainter oldPainter) {
    return oldPainter.mask != mask;
  }
}
