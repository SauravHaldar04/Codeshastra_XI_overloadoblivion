import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageComparisonSlider extends StatefulWidget {
  final Uint8List beforeImage;
  final Uint8List afterImage;

  const ImageComparisonSlider({
    Key? key,
    required this.beforeImage,
    required this.afterImage,
  }) : super(key: key);

  @override
  State<ImageComparisonSlider> createState() => _ImageComparisonSliderState();
}

class _ImageComparisonSliderState extends State<ImageComparisonSlider> {
  double _sliderPosition = 0.5;
  final double _imageHeight = 250;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _imageHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Stack(
            children: [
              // After image (full width)
              Container(
                width: maxWidth,
                height: _imageHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(widget.afterImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Before image (clipped to slider position)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _sliderPosition,
                  child: Container(
                    width: maxWidth,
                    height: _imageHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(widget.beforeImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // Slider divider
              Positioned(
                left: maxWidth * _sliderPosition - 12,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.white,
                ),
              ),

              // Slider handle
              Positioned(
                left: maxWidth * _sliderPosition - 16,
                top: (_imageHeight / 2) - 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.compare_arrows,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),

              // Labels
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Before',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'After',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Gesture detection for slider
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderPosition =
                          (_sliderPosition + details.delta.dx / maxWidth)
                              .clamp(0.0, 1.0);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
