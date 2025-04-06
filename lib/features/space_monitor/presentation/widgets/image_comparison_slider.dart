import 'package:flutter/material.dart';

class ImageComparisonSlider extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;

  const ImageComparisonSlider({
    Key? key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
  }) : super(key: key);

  @override
  State<ImageComparisonSlider> createState() => _ImageComparisonSliderState();
}

class _ImageComparisonSliderState extends State<ImageComparisonSlider> {
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // After image (full)
                Image.network(
                  widget.afterImageUrl,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  fit: BoxFit.cover,
                  loadingBuilder: _buildLoadingIndicator,
                  errorBuilder: _buildErrorWidget,
                ),

                // Before image (clipped)
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _sliderPosition,
                    child: Image.network(
                      widget.beforeImageUrl,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.cover,
                      loadingBuilder: _buildLoadingIndicator,
                      errorBuilder: _buildErrorWidget,
                    ),
                  ),
                ),

                // Slider
                Positioned(
                  left: constraints.maxWidth * _sliderPosition - 12,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _sliderPosition +=
                            details.delta.dx / constraints.maxWidth;
                        _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
                      });
                    },
                    child: Container(
                      width: 24,
                      height: constraints.maxHeight,
                      color: Colors.white.withOpacity(0.5),
                      child: const Center(
                        child: Icon(
                          Icons.drag_indicator,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Labels
                Positioned(
                  left: 8,
                  top: 8,
                  child: _buildLabel('Before'),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: _buildLabel('After'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.error_outline),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
