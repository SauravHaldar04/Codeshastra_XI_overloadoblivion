import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../widgets/image_comparison_slider.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/data/services/scene_comparison_service.dart';

class SceneComparisonPage extends StatefulWidget {
  final String jobId;
  final String beforeRoom;
  final String beforeTimestamp;
  final String afterRoom;
  final String afterTimestamp;
  final Map<String, dynamic> results;

  const SceneComparisonPage({
    Key? key,
    required this.jobId,
    required this.beforeRoom,
    required this.beforeTimestamp,
    required this.afterRoom,
    required this.afterTimestamp,
    required this.results,
  }) : super(key: key);

  @override
  State<SceneComparisonPage> createState() => _SceneComparisonPageState();
}

class _SceneComparisonPageState extends State<SceneComparisonPage> {
  late final SceneComparisonService _comparisonService;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _graphData;
  Map<String, String>? _imageUrls;

  // Image data
  Uint8List? _beforeOriginalImage;
  Uint8List? _afterOriginalImage;
  Uint8List? _beforeDepthImage;
  Uint8List? _afterDepthImage;
  Uint8List? _beforeDetectionImage;
  Uint8List? _afterDetectionImage;

  @override
  void initState() {
    super.initState();
    _comparisonService = SceneComparisonService();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Extract data from results
      _statistics = widget.results['results']['statistics'];
      _graphData = widget.results['results']['graph_data'];
      _imageUrls = Map<String, String>.from(widget.results['image_urls']);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load comparison data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Comparison'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComparisonData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatistics(),
          const SizedBox(height: 24),
          _buildImageComparisons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final beforeDate = DateTime.parse(widget.beforeTimestamp);
    final afterDate = DateTime.parse(widget.afterTimestamp);
    final dateFormat = DateFormat('MMM d, y HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTimelineRow(
              'Before',
              widget.beforeRoom,
              dateFormat.format(beforeDate),
            ),
            const SizedBox(height: 8),
            _buildTimelineRow(
              'After',
              widget.afterRoom,
              dateFormat.format(afterDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(String label, String room, String time) {
    return Row(
      children: [
        Container(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    if (_statistics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Objects Added', _statistics!['additions']),
            _buildStatRow('Objects Removed', _statistics!['removals']),
            _buildStatRow('Objects Moved', _statistics!['movements']),
            _buildStatRow(
                'Before Detections', _statistics!['before_detections']),
            _buildStatRow('After Detections', _statistics!['after_detections']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComparisons() {
    if (_imageUrls == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageComparisonSection(
          'Original Images',
          _imageUrls!['before_image'],
          _imageUrls!['after_image'],
        ),
        const SizedBox(height: 24),
        _buildImageComparisonSection(
          'Detection Results',
          _imageUrls!['before_det_vis'],
          _imageUrls!['after_det_vis'],
        ),
        const SizedBox(height: 24),
        _buildImageComparisonSection(
          'Depth Analysis',
          _imageUrls!['before_depth_vis'],
          _imageUrls!['after_depth_vis'],
        ),
        const SizedBox(height: 24),
        _buildImageComparisonSection(
          'Changes Visualization',
          _imageUrls!['changes_vis'],
          _imageUrls!['movements_vis'],
          isSideBySide: true,
        ),
      ],
    );
  }

  Widget _buildImageComparisonSection(
    String title,
    String? beforeUrl,
    String? afterUrl, {
    bool isSideBySide = false,
  }) {
    if (beforeUrl == null || afterUrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (isSideBySide)
          Row(
            children: [
              Expanded(
                child: _buildImage(beforeUrl),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildImage(afterUrl),
              ),
            ],
          )
        else
          ImageComparisonSlider(
            beforeImageUrl: beforeUrl,
            afterImageUrl: afterUrl,
          ),
      ],
    );
  }

  Widget _buildImage(String url) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error_outline),
            ),
          );
        },
      ),
    );
  }
}
