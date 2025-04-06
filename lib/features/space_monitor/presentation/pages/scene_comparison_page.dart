import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../widgets/image_comparison_slider.dart';

class SceneComparisonPage extends StatefulWidget {
  final String beforeRoom;
  final String beforeTimestamp;
  final String afterRoom;
  final String afterTimestamp;

  const SceneComparisonPage({
    Key? key,
    required this.beforeRoom,
    required this.beforeTimestamp,
    required this.afterRoom,
    required this.afterTimestamp,
  }) : super(key: key);

  @override
  State<SceneComparisonPage> createState() => _SceneComparisonPageState();
}

class _SceneComparisonPageState extends State<SceneComparisonPage> {
  bool _isLoading = true;
  String? _errorMessage;

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
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch before scan data
      final beforeData =
          await _fetchScanData(widget.beforeRoom, widget.beforeTimestamp);
      if (beforeData == null) {
        throw Exception('Failed to fetch before scan data');
      }

      // Fetch after scan data
      final afterData =
          await _fetchScanData(widget.afterRoom, widget.afterTimestamp);
      if (afterData == null) {
        throw Exception('Failed to fetch after scan data');
      }

      // Debug URLs
      debugPrint('Before Original URL: ${beforeData['original_image_url']}');
      debugPrint('After Original URL: ${afterData['original_image_url']}');

      // Load images in parallel
      final futures = [
        _loadImageFromUrl(beforeData['original_image_url']),
        _loadImageFromUrl(afterData['original_image_url']),
        _loadImageFromUrl(beforeData['depth_image_url']),
        _loadImageFromUrl(afterData['depth_image_url']),
        _loadImageFromUrl(beforeData['detection_image_url']),
        _loadImageFromUrl(afterData['detection_image_url']),
      ];

      final results = await Future.wait(futures);

      setState(() {
        _beforeOriginalImage = results[0];
        _afterOriginalImage = results[1];
        _beforeDepthImage = results[2];
        _afterDepthImage = results[3];
        _beforeDetectionImage = results[4];
        _afterDetectionImage = results[5];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading comparison: $e';
        _isLoading = false;
      });
      debugPrint('Error in _loadImages: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchScanData(
      String roomName, String timestamp) async {
    try {
      debugPrint('Fetching data for room: $roomName, timestamp: $timestamp');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('scene_analysis_result')
          .where('room_name', isEqualTo: roomName)
          .where('timestamp', isEqualTo: timestamp)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
            'No documents found for room: $roomName, timestamp: $timestamp');
        return null;
      }

      final data = querySnapshot.docs.first.data();
      debugPrint('Found data: ${data.keys.toString()}');
      return data;
    } catch (e) {
      debugPrint('Error fetching scan data: $e');
      return null;
    }
  }

  Future<Uint8List?> _loadImageFromUrl(String? url) async {
    if (url == null || url.isEmpty) {
      debugPrint('URL is null or empty');
      return null;
    }

    try {
      debugPrint('Loading image from URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        debugPrint(
            'Successfully loaded image from URL: $url (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      } else {
        debugPrint(
            'Failed to load image from URL: $url. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error loading image from URL: $url. Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format timestamps for display
    final beforeDate = DateTime.parse(widget.beforeTimestamp);
    final afterDate = DateTime.parse(widget.afterTimestamp);
    final dateFormat = DateFormat('MMM d, y HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Comparison'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child:
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with room and timestamp information
                      _buildComparisonHeader(
                        beforeRoom: widget.beforeRoom,
                        beforeTime: dateFormat.format(beforeDate),
                        afterRoom: widget.afterRoom,
                        afterTime: dateFormat.format(afterDate),
                      ),
                      const SizedBox(height: 24),

                      // Original images comparison
                      if (_beforeOriginalImage != null &&
                          _afterOriginalImage != null)
                        _buildImageComparisonSection(
                          title: 'Original Images',
                          beforeImage: _beforeOriginalImage!,
                          afterImage: _afterOriginalImage!,
                        ),

                      // Detection images comparison
                      if (_beforeDetectionImage != null &&
                          _afterDetectionImage != null)
                        _buildImageComparisonSection(
                          title: 'Detection Images',
                          beforeImage: _beforeDetectionImage!,
                          afterImage: _afterDetectionImage!,
                        ),

                      // Depth images comparison
                      if (_beforeDepthImage != null && _afterDepthImage != null)
                        _buildImageComparisonSection(
                          title: 'Depth Images',
                          beforeImage: _beforeDepthImage!,
                          afterImage: _afterDepthImage!,
                        ),

                      // No images available
                      if (_beforeOriginalImage == null ||
                          _afterOriginalImage == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Some images could not be loaded. Please check your internet connection and try again.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildComparisonHeader({
    required String beforeRoom,
    required String beforeTime,
    required String afterRoom,
    required String afterTime,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparing Room Scans',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Before:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(beforeRoom),
                      Text(beforeTime,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('After:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(afterRoom),
                      Text(afterTime,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageComparisonSection({
    required String title,
    required Uint8List beforeImage,
    required Uint8List afterImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ImageComparisonSlider(
              beforeImage: beforeImage,
              afterImage: afterImage,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
