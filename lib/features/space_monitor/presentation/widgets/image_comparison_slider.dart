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
  final double _imageHeight = 250.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _imageHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Stack(
            children: [
              // After image (full width)
              SizedBox(
                width: width,
                height: _imageHeight,
                child: Image.memory(
                  widget.afterImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading after image: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red[300]),
                          const Text('Error loading image'),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Before image (clipped to slider position)
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: _sliderPosition,
                  child: SizedBox(
                    width: width,
                    height: _imageHeight,
                    child: Image.memory(
                      widget.beforeImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading before image: $error');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red[300]),
                              const Text('Error loading image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Slider divider line
              Positioned(
                top: 0,
                bottom: 0,
                left: width * _sliderPosition - 1,
                child: Container(
                  width: 2,
                  color: Colors.white,
                ),
              ),

              // Slider handle
              Positioned(
                top: (_imageHeight / 2) - 15,
                left: width * _sliderPosition - 15,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderPosition += details.delta.dx / width;
                      // Clamp slider position to range 0.0 - 1.0
                      _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
                    });
                  },
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.compare_arrows,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ),

              // Before label
              const Positioned(
                top: 10,
                left: 10,
                child: Text(
                  'Before',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),

              // After label
              const Positioned(
                top: 10,
                right: 10,
                child: Text(
                  'After',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
