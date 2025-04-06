import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/domain/entities/scene_analysis_result.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';

class ResultDetailPage extends StatefulWidget {
  final SceneAnalysisResult result;

  const ResultDetailPage({super.key, required this.result});

  @override
  State<ResultDetailPage> createState() => _ResultDetailPageState();
}

class _ResultDetailPageState extends State<ResultDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isImageFullScreen = false;
  String? _fullScreenImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _imageUrls = {};
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadImagesFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImagesFromFirestore() async {
    try {
      print(
          'Loading images for room: ${widget.result.room}, timestamp: ${widget.result.timestamp}');

      final querySnapshot = await _firestore
          .collection('scene_analysis_results')
          .where('room', isEqualTo: widget.result.room)
          .where('timestamp', isEqualTo: widget.result.timestamp)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print(
            'No document found for room: ${widget.result.room}, timestamp: ${widget.result.timestamp}');
        setState(() {
          _imagesLoaded = true;
        });
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final Map<String, String> urls = {};

      // Extract image URLs from the data
      if (data.containsKey('cloud_links')) {
        final images = data['cloud_links']['images'] as Map<String, dynamic>?;
        print('Images: $images');

        if (images != null) {
          // Original image
          if (images.containsKey('original')) {
            // Direct access to "url" inside the original object
            final url = images['original']['url'] as String?;
            if (url != null) {
              urls['original'] = url;
              print('Original image URL: ${urls['original']}');
            }
          }

          // Detection image
          if (images.containsKey('detection')) {
            // Direct access to "url" inside the detection object
            final url = images['detection']['url'] as String?;
            if (url != null) {
              urls['detection'] = url;
              print('Detection image URL: ${urls['detection']}');
            }
          }

          // Depth image
          if (images.containsKey('depth')) {
            // Direct access to "url" inside the depth object
            final url = images['depth']['url'] as String?;
            if (url != null) {
              urls['depth'] = url;
              print('Depth image URL: ${urls['depth']}');
            }
          }
        }
      }

      setState(() {
        _imageUrls = urls;
        _imagesLoaded = true;
      });
    } catch (e) {
      print('Error fetching image data: $e');
      setState(() {
        _imagesLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.room),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: _isImageFullScreen ? null : _buildTabBar(),
      ),
      body: _isImageFullScreen ? _buildFullScreenImage() : _buildTabBarView(),
      floatingActionButton: _isImageFullScreen
          ? null
          : FloatingActionButton(
              onPressed: _shareAnalysisResult,
              child: const Icon(Icons.share),
            ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      indicatorColor: Colors.white,
      tabs: const [
        Tab(text: 'Images', icon: Icon(Icons.image)),
        Tab(text: 'Objects', icon: Icon(Icons.category)),
        Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildImagesTab(),
        _buildObjectsTab(),
        _buildAnalysisTab(),
      ],
    );
  }

  Widget _buildImagesTab() {
    if (!_imagesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Room Overview'),
          const SizedBox(height: 16),
          if (_imageUrls.containsKey('original'))
            _buildImageCard(
              'Original Image',
              _imageUrls['original']!,
              'The original image captured during the scan',
            ),
          const SizedBox(height: 24),
          if (_imageUrls.containsKey('detection'))
            _buildImageCard(
              'Detection Image',
              _imageUrls['detection']!,
              'AI-processed image showing detected objects',
            ),
          const SizedBox(height: 24),
          if (_imageUrls.containsKey('depth'))
            _buildImageCard(
              'Depth Map',
              _imageUrls['depth']!,
              'Visual representation of depth data for the scene',
            ),
          if (_imageUrls.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.image_not_supported,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No images available for this analysis',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _imagesLoaded = false;
                      });
                      _loadImagesFromFirestore();
                    },
                    child: const Text('Retry Loading Images'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer, size: 20),
              const SizedBox(width: 8),
              Text(
                'Scanned on: ${_formatDate(widget.result.timestampDateTime)}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.numbers, size: 20),
              const SizedBox(width: 8),
              Text('Job ID: ${widget.result.jobId}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectsTab() {
    final objectsByCategory = _groupObjectsByCategory();
    final items = widget.result.classSummary;
    final totalCount = widget.result.detectionCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Object Detection Results'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Pallete.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '$totalCount objects detected in ${widget.result.room}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Object count by category
          _buildSectionHeader('Objects by Category'),
          const SizedBox(height: 16),
          _buildObjectCategories(objectsByCategory),

          const SizedBox(height: 24),

          // Detailed object list
          _buildSectionHeader('Detailed Object List'),
          const SizedBox(height: 16),
          _buildObjectTable(items),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('AI Analysis Summary'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.result.summary
                  .split('\n')
                  .map((paragraph) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          paragraph.trim(),
                          style: const TextStyle(
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Usage Recommendations'),
          const SizedBox(height: 16),
          _buildRecommendationCards(),
          const SizedBox(height: 24),
          // Load graph data URL from Firestore
          FutureBuilder<String?>(
            future: _loadCloudLinkFromFirestore('graphData'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                return Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _openCloudLink(snapshot.data!),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('View Detailed Graph Data'),
                  ),
                );
              } else {
                // No graph data URL available
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _loadCloudLinkFromFirestore(String linkType) async {
    try {
      print('Loading cloud link for: $linkType');

      final querySnapshot = await _firestore
          .collection('scene_analysis_results')
          .where('room', isEqualTo: widget.result.room)
          .where('timestamp', isEqualTo: widget.result.timestamp)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No document found for cloud links');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Extract cloud link URL from the data
      if (data.containsKey('cloud_links')) {
        final cloudLinks = data['cloud_links'] as Map<String, dynamic>?;

        if (cloudLinks != null && cloudLinks.containsKey(linkType)) {
          // Direct access to "url" inside the cloudLinks object
          final url = cloudLinks[linkType]['url'] as String?;
          if (url != null) {
            print('$linkType URL: $url');
            return url;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error fetching cloud link data: $e');
      return null;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildImageCard(String title, String imageUrl, String description) {
    // DEBUG: Print the image URL
    print('DEBUG Detail: Loading image for $title: $imageUrl');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(imageUrl),
                  child: imageUrl.isEmpty || !imageUrl.startsWith('http')
                      ? _buildEmptyImagePlaceholder(220)
                      : Image.network(
                          imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Direct Image Error: $error');
                            return _buildEmptyImagePlaceholder(220);
                          },
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen),
                          onPressed: () => _showFullScreenImage(imageUrl),
                          tooltip: 'View fullscreen',
                        ),
                      ],
                    ),
                    if (imageUrl.isEmpty || !imageUrl.startsWith('http'))
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.amber,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Invalid image URL: $imageUrl',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyImagePlaceholder(double height) {
    return Container(
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
            const SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _retryLoadingImage(String url) {
    // Just reload the image
    setState(() {});

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying image load...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildObjectCategories(Map<String, int> objectsByCategory) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: objectsByCategory.length,
      itemBuilder: (context, index) {
        final category = objectsByCategory.keys.elementAt(index);
        final count = objectsByCategory[category];
        return SizedBox(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
        );
      },
    );
  }

  Widget _buildObjectTable(List<ObjectCount> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Object Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade300,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Icon(
                            _getIconForClass(item.objectClass),
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _capitalizeFirstLetter(item.objectClass),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.count}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showObjectInfo(item),
                        tooltip: 'More info',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCards() {
    // Generate relevant recommendations based on detected objects
    final recommendations = _generateRecommendations();

    return Column(
      children: recommendations.map((rec) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  rec.icon,
                  color: rec.color,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: const Duration(milliseconds: 300));
      }).toList(),
    );
  }

  Widget _buildFullScreenImage() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _exitFullScreenMode,
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: Image.network(
                  _fullScreenImageUrl!,
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
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading image...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Full Screen Image Error: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 50),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'URL: $_fullScreenImageUrl',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _exitFullScreenMode,
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: _exitFullScreenMode,
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String imageUrl) {
    setState(() {
      _isImageFullScreen = true;
      _fullScreenImageUrl = imageUrl;
    });
  }

  void _exitFullScreenMode() {
    setState(() {
      _isImageFullScreen = false;
      _fullScreenImageUrl = null;
    });
  }

  void _showObjectInfo(ObjectCount objectCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Row(
              children: [
                Icon(
                  _getIconForClass(objectCount.objectClass),
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  _capitalizeFirstLetter(objectCount.objectClass),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.numbers),
              title: const Text('Quantity'),
              subtitle: Text(
                '${objectCount.count} ${objectCount.count == 1 ? 'item' : 'items'} detected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.room),
              title: const Text('Location'),
              subtitle: Text(widget.result.room),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Object Information'),
              subtitle: Text(
                _getObjectDescription(objectCount.objectClass),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCloudLink(String url) {
    // Display the URL in a dialog for debugging purposes
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opening URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The following URL would be opened:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareAnalysisResult() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing analysis for ${widget.result.room}'),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(date);
  }

  IconData _getIconForClass(String className) {
    switch (className.toLowerCase()) {
      case 'chair':
        return Icons.chair;
      case 'table':
      case 'dining table':
        return Icons.table_restaurant;
      case 'sofa':
      case 'couch':
        return Icons.weekend;
      case 'bed':
        return Icons.bed;
      case 'laptop':
      case 'computer':
        return Icons.laptop;
      case 'tv':
      case 'television':
        return Icons.tv;
      case 'book':
        return Icons.book;
      case 'cup':
      case 'glass':
        return Icons.local_drink;
      case 'bottle':
        return Icons.liquor;
      case 'remote':
        return Icons.cast;
      case 'clock':
        return Icons.access_time;
      case 'vase':
        return Icons.local_florist;
      case 'sports ball':
      case 'ball':
        return Icons.sports_basketball;
      case 'backpack':
        return Icons.backpack;
      case 'potted plant':
        return Icons.local_florist;
      default:
        return Icons.category;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Map<String, int> _groupObjectsByCategory() {
    final categories = <String, int>{};

    for (final object in widget.result.classSummary) {
      final category = _getCategory(object.objectClass);
      categories[category] = (categories[category] ?? 0) + object.count;
    }

    return categories;
  }

  String _getCategory(String objectClass) {
    switch (objectClass.toLowerCase()) {
      case 'chair':
      case 'sofa':
      case 'couch':
      case 'bed':
        return 'Furniture';
      case 'table':
      case 'dining table':
      case 'desk':
        return 'Tables';
      case 'laptop':
      case 'computer':
      case 'tv':
      case 'remote':
        return 'Electronics';
      case 'book':
      case 'clock':
        return 'Accessories';
      case 'cup':
      case 'glass':
      case 'bottle':
        return 'Kitchenware';
      case 'potted plant':
      case 'vase':
        return 'Plants & Decor';
      default:
        return 'Other';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Furniture':
        return Icons.chair;
      case 'Tables':
        return Icons.table_restaurant;
      case 'Electronics':
        return Icons.devices;
      case 'Accessories':
        return Icons.watch;
      case 'Kitchenware':
        return Icons.kitchen;
      case 'Plants & Decor':
        return Icons.local_florist;
      default:
        return Icons.category;
    }
  }

  String _getObjectDescription(String objectClass) {
    switch (objectClass.toLowerCase()) {
      case 'chair':
        return 'A seat typically having four legs and a back for one person.';
      case 'sofa':
      case 'couch':
        return 'A long upholstered seat with a back and arms, for two or more people.';
      case 'table':
      case 'dining table':
        return 'A piece of furniture with a flat top and one or more legs, providing a surface for eating, writing, or playing games.';
      case 'tv':
      case 'television':
        return 'An electronic device for receiving and displaying broadcast or recorded images and sound.';
      case 'laptop':
        return 'A portable computer with a built-in screen and keyboard, designed for use on the go.';
      case 'potted plant':
        return 'A decorative plant grown in a container, adding greenery and improving air quality.';
      case 'cup':
        return 'A small container typically having a handle and used for drinking hot beverages.';
      default:
        return 'Common household object used for various purposes.';
    }
  }

  List<Recommendation> _generateRecommendations() {
    final List<Recommendation> recommendations = [];
    final hasElectronics = widget.result.classSummary.any((obj) =>
        ['tv', 'laptop', 'computer'].contains(obj.objectClass.toLowerCase()));
    final hasFurniture = widget.result.classSummary.any((obj) => [
          'chair',
          'sofa',
          'couch',
          'table',
          'bed'
        ].contains(obj.objectClass.toLowerCase()));
    final hasPlants = widget.result.classSummary
        .any((obj) => obj.objectClass.toLowerCase() == 'potted plant');

    if (hasElectronics) {
      recommendations.add(
        Recommendation(
          title: 'Electronics Placement',
          description:
              'Consider organizing cables and ensuring adequate ventilation for electronic devices to prevent overheating.',
          icon: Icons.cable,
          color: Colors.blue,
        ),
      );
    }

    if (hasFurniture) {
      recommendations.add(
        Recommendation(
          title: 'Furniture Arrangement',
          description:
              'The current furniture layout provides good functionality. Consider flow of movement when rearranging.',
          icon: Icons.straighten,
          color: Colors.brown,
        ),
      );
    }

    if (hasPlants) {
      recommendations.add(
        Recommendation(
          title: 'Plant Care',
          description:
              'Ensure plants receive adequate light based on their current placement. Consider rotating them occasionally for even growth.',
          icon: Icons.wb_sunny,
          color: Colors.green,
        ),
      );
    }

    // Always add space utilization recommendation
    recommendations.add(
      Recommendation(
        title: 'Space Utilization',
        description:
            'Based on object detection, this room has ${widget.result.detectionCount} items. Consider optimal placement to maximize space efficiency.',
        icon: Icons.aspect_ratio,
        color: Colors.purple,
      ),
    );

    return recommendations;
  }
}

class Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Recommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
