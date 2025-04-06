import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/domain/entities/scene_analysis_result.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/cubits/scene_analysis_cubit.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/result_detail_page.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Load all results when the page is first opened
    context.read<SceneAnalysisCubit>().loadSceneAnalysisResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Analysis Results'),
      ),
      body: BlocBuilder<SceneAnalysisCubit, SceneAnalysisState>(
        builder: (context, state) {
          if (state is SceneAnalysisLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SceneAnalysisLoaded) {
            final results = state.results;

            if (results.isEmpty) {
              return const Center(
                child: Text('No results available'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return _buildResultCard(context, result);
              },
            );
          } else if (state is SceneAnalysisError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          } else {
            return const Center(
              child: Text('No data available'),
            );
          }
        },
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SceneAnalysisResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    result.room,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d, y').format(result.timestampDateTime),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Images (loaded directly from Firestore)
          FutureBuilder(
            future: _loadImagesFromFirestore(result.room, result.timestamp),
            builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                print('Error loading images: ${snapshot.error}');
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text('Error loading images: ${snapshot.error}'),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final imageUrls = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Images:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            if (imageUrls['original'] != null)
                              _buildImageWidget(
                                  context, 'Original', imageUrls['original']!),
                            if (imageUrls['detection'] != null)
                              _buildImageWidget(context, 'Detection',
                                  imageUrls['detection']!),
                            if (imageUrls['depth'] != null)
                              _buildImageWidget(
                                  context, 'Depth', imageUrls['depth']!),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('No images available'),
                );
              }
            },
          ),

          // Object counts
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Objects Detected:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.classSummary
                      .map((obj) => Chip(
                            label: Text('${obj.objectClass}: ${obj.count}'),
                            backgroundColor: Colors.grey[200],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Details button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultDetailPage(result: result),
                  ),
                );
              },
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _loadImagesFromFirestore(
      String room, String timestamp) async {
    print('Loading images for room: $room, timestamp: $timestamp');

    try {
      final querySnapshot = await _firestore
          .collection('scene_analysis_results')
          .where('room', isEqualTo: room)
          .where('timestamp', isEqualTo: timestamp)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No document found for room: $room, timestamp: $timestamp');
        return {};
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final Map<String, String> imageUrls = {};

      // Extract image URLs from the cloud_links.images structure
      if (data.containsKey('cloud_links')) {
        final cloudLinks = data['cloud_links'] as Map<String, dynamic>?;

        if (cloudLinks != null && cloudLinks.containsKey('images')) {
          final images = cloudLinks['images'] as Map<String, dynamic>?;
          print('Images: $images');

          if (images != null) {
            // Original image - direct access to url property
            if (images.containsKey('original')) {
              // Direct access to URL inside original object
              final url = images['original']['url'] as String?;
              if (url != null) {
                imageUrls['original'] = url;
                print('Original image URL: ${imageUrls['original']}');
              }
            }

            // Detection image - direct access to url property
            if (images.containsKey('detection')) {
              // Direct access to URL inside detection object
              final url = images['detection']['url'] as String?;
              if (url != null) {
                imageUrls['detection'] = url;
                print('Detection image URL: ${imageUrls['detection']}');
              }
            }

            // Depth image - direct access to url property
            if (images.containsKey('depth')) {
              // Direct access to URL inside depth object
              final url = images['depth']['url'] as String?;
              if (url != null) {
                imageUrls['depth'] = url;
                print('Depth image URL: ${imageUrls['depth']}');
              }
            }
          }
        }
      }

      return imageUrls;
    } catch (e) {
      print('Error fetching image data: $e');
      throw Exception('Failed to load images: $e');
    }
  }

  Widget _buildImageWidget(
      BuildContext context, String label, String imageUrl) {
    // Print URL for debugging
    print('Building image widget for $label: $imageUrl');

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Image error for $label: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red[300], size: 16),
                      const SizedBox(height: 4),
                      Text(
                        'Error',
                        style: TextStyle(fontSize: 10, color: Colors.red[300]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
