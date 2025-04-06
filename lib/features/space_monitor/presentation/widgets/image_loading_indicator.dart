import 'package:flutter/material.dart';

// A widget that shows a loading indicator while the image is loading
class ImageLoadingIndicator extends StatefulWidget {
  final String imageUrl;

  const ImageLoadingIndicator({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<ImageLoadingIndicator> createState() => _ImageLoadingIndicatorState();
}

class _ImageLoadingIndicatorState extends State<ImageLoadingIndicator> {
  late ImageStream _imageStream;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    final image = NetworkImage(widget.imageUrl);
    _imageStream = image.resolve(const ImageConfiguration());
    _imageStream.addListener(ImageStreamListener(
      (_, __) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _isLoaded = true; // Even on error, we hide the loading indicator
          });
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
