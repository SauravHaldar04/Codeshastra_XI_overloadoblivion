import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/domain/entities/scene_analysis_result.dart';

class ImageViewPage extends StatefulWidget {
  final String imageUrl;
  final String title;
  final List<ImageItem>? galleryImages;
  final int initialIndex;

  const ImageViewPage({
    Key? key,
    required this.imageUrl,
    required this.title,
    this.galleryImages,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<ImageItem> _images;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // If gallery images are provided, use them
    // Otherwise create a single image from the provided URL and title
    _images =
        widget.galleryImages ?? [ImageItem(widget.imageUrl, widget.title)];

    // Print all image URLs for debugging
    for (var image in _images) {
      print('Image URL: ' + image.imageUrl);
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_images[_currentIndex].title),
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              // Toggle fullscreen mode
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use pinch to zoom the image')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Show download option
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Image download feature will be implemented in the next update')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main image viewer with page swiping
            PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildImageViewer(_images[index].imageUrl);
              },
            ),

            // Bottom information panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _images[_currentIndex].title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Swipe left/right to view more images',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    if (_images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: _buildImageThumbnails(),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

            // Image navigation arrows
            if (_images.length > 1)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (_currentIndex > 0)
                      GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          color: Colors.transparent,
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),

                    // Next button
                    if (_currentIndex < _images.length - 1)
                      GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 60,
                          color: Colors.transparent,
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.5),
                            size: 40,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $imageUrl');
            print('Error details: $error');

            return Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load image. Please check your internet connection or try again later.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'URL may be invalid or inaccessible. Please verify the URL.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {}); // Retry loading the image
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'URL: $imageUrl',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _loadPlaceholderImage(BuildContext context) {
    String roomName = _images[_currentIndex].title.split(' - ').first;
    String imageType = _images[_currentIndex].title.split(' - ').last;

    // Replace the current image with a placeholder
    setState(() {
      _images[_currentIndex] = ImageItem(
        'https://via.placeholder.com/800x600?text=$imageType+Not+Available',
        '$roomName - $imageType (Placeholder)',
      );
    });
  }

  Widget _buildImageThumbnails() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  _images[index].imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ImageItem {
  final String imageUrl;
  final String title;

  ImageItem(this.imageUrl, this.title);
}
