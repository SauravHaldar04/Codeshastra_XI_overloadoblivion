import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:get_it/get_it.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/cubit/space_optimization_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/data/services/scene_comparison_service.dart';
import 'scene_comparison_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  VideoPlayerController? _videoController;
  late SpaceOptimizationCubit _optimizationCubit;

  @override
  void initState() {
    super.initState();
    _optimizationCubit = GetIt.instance<SpaceOptimizationCubit>();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpaceOptimizationCubit>.value(
      value: _optimizationCubit,
      child: BlocConsumer<SpaceOptimizationCubit, SpaceOptimizationState>(
        listener: (context, state) {
          if (state is SpaceOptimizationSuccess && state.isVideo) {
            _videoController = VideoPlayerController.file(state.resultFile)
              ..initialize().then((_) {
                setState(() {});
                _videoController!.play();
              });
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Space Analysis',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track and analyze space changes over time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Space Optimization Card
                InkWell(
                  onTap: () => _showMediaOptionsBottomSheet(context, state),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Space Optimization',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Upload media to get optimization suggestions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),

                        // Show content based on state
                        if (state is SpaceOptimizationLoading) ...[
                          const SizedBox(height: 16),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],

                        if (state is SpaceOptimizationFailure) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Results - Image
                        if (state is SpaceOptimizationSuccess &&
                            !state.isVideo) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              state.resultFile,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _optimizationCubit.reset(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Another'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ],

                        // Results - Video
                        if (state is SpaceOptimizationSuccess &&
                            state.isVideo) ...[
                          const SizedBox(height: 16),
                          if (_videoController != null &&
                              _videoController!.value.isInitialized)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                      padding: const EdgeInsets.all(8.0),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 30,
                                      child: FloatingActionButton(
                                        mini: true,
                                        onPressed: () {
                                          setState(() {
                                            _videoController!.value.isPlaying
                                                ? _videoController!.pause()
                                                : _videoController!.play();
                                          });
                                        },
                                        child: Icon(
                                          _videoController!.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _optimizationCubit.reset(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Another'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Object Movement Analysis Card
                _buildAnalysisCard(
                  context: context,
                  title: 'Object Movement Analysis',
                  description: 'Track changes in object positions over time',
                  icon: Icons.move_up,
                  onTap: () {},
                ),

                const SizedBox(height: 16),

                // Compare Two Scans Card
                _buildAnalysisCard(
                  context: context,
                  title: 'Compare Two Scans',
                  description: 'Compare different scans to identify changes',
                  icon: Icons.compare_arrows,
                  onTap: () => _showCompareScansDialog(),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildAnalysisCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOptionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptionsBottomSheet(
      BuildContext context, SpaceOptimizationState state) {
    if (state is SpaceOptimizationSuccess ||
        state is SpaceOptimizationLoading) {
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Media Type',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMediaOptionCard(
                    context: context,
                    title: 'Image',
                    icon: Icons.image,
                    onTap: () {
                      Navigator.pop(context);
                      _showImageSourceDialog(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMediaOptionCard(
                    context: context,
                    title: 'Video',
                    icon: Icons.videocam,
                    onTap: () {
                      Navigator.pop(context);
                      _showVideoSourceDialog(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _optimizationCubit.pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _optimizationCubit.pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Video Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _optimizationCubit.pickVideoFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _optimizationCubit.pickVideoFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompareScansDialog() {
    bool isLoading = true;
    Map<String, List<String>> roomScans = {};
    String? selectedFirstRoom;
    String? selectedFirstScan;
    String? selectedSecondRoom;
    String? selectedSecondScan;

    Future<void> fetchAvailableScans() async {
      try {
        final sceneAnalysisCollection =
            FirebaseFirestore.instance.collection('scene_analysis_results');
        final querySnapshot = await sceneAnalysisCollection.get();

        // Process documents and organize by room name
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final roomName = data['cloud_links']['room'] as String?;
          final timestamp = data['timestamp'] as String?;

          if (roomName != null && timestamp != null) {
            if (!roomScans.containsKey(roomName)) {
              roomScans[roomName] = [];
            }
            roomScans[roomName]!.add(timestamp);
          }
        }

        // Sort timestamps for each room - most recent first
        for (var room in roomScans.keys) {
          roomScans[room]!.sort((a, b) => b.compareTo(a));
        }
      } catch (e) {
        debugPrint('Error fetching scans: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch scans when dialog opens
            if (isLoading) {
              fetchAvailableScans().then((_) {
                if (roomScans.isNotEmpty) {
                  setState(() {
                    selectedFirstRoom = roomScans.keys.first;
                    if (roomScans[selectedFirstRoom]!.isNotEmpty) {
                      selectedFirstScan = roomScans[selectedFirstRoom]![0];
                    }

                    selectedSecondRoom = roomScans.keys.first;
                    if (roomScans[selectedSecondRoom]!.length > 1) {
                      selectedSecondScan = roomScans[selectedSecondRoom]![1];
                    } else if (roomScans[selectedSecondRoom]!.length > 0) {
                      selectedSecondScan = roomScans[selectedSecondRoom]![0];
                    }

                    isLoading = false;
                  });
                } else {
                  setState(() {
                    isLoading = false;
                  });
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Compare Scans',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (roomScans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No scans available for comparison'),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'First Scan (Before):',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _buildScanSelector(
                                roomScans,
                                selectedFirstRoom,
                                selectedFirstScan,
                                (room) {
                                  setState(() {
                                    selectedFirstRoom = room;
                                    if (roomScans[room]!.isNotEmpty) {
                                      selectedFirstScan = roomScans[room]![0];
                                    } else {
                                      selectedFirstScan = null;
                                    }
                                  });
                                },
                                (scan) {
                                  setState(() {
                                    selectedFirstScan = scan;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Second Scan (After):',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _buildScanSelector(
                                roomScans,
                                selectedSecondRoom,
                                selectedSecondScan,
                                (room) {
                                  setState(() {
                                    selectedSecondRoom = room;
                                    if (roomScans[room]!.isNotEmpty) {
                                      selectedSecondScan = roomScans[room]![0];
                                    } else {
                                      selectedSecondScan = null;
                                    }
                                  });
                                },
                                (scan) {
                                  setState(() {
                                    selectedSecondScan = scan;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        if (!isLoading &&
                            roomScans.isNotEmpty &&
                            selectedFirstScan != null &&
                            selectedSecondScan != null)
                          ElevatedButton(
                            onPressed: () {
                              _performScanComparison(
                                selectedFirstRoom!,
                                selectedFirstScan!,
                                selectedSecondRoom!,
                                selectedSecondScan!,
                              );
                              Navigator.of(context).pop();
                            },
                            child: const Text('Compare'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScanSelector(
    Map<String, List<String>> roomScans,
    String? selectedRoom,
    String? selectedScan,
    Function(String) onRoomChanged,
    Function(String) onScanChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room selector
        DropdownButton<String>(
          isExpanded: true,
          value: selectedRoom,
          items: roomScans.keys.map((room) {
            return DropdownMenuItem<String>(
              value: room,
              child: Text(room),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onRoomChanged(value);
            }
          },
        ),

        // Scan selector with thumbnails
        if (selectedRoom != null && roomScans[selectedRoom]!.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: roomScans[selectedRoom]!.length,
              itemBuilder: (context, index) {
                final scan = roomScans[selectedRoom]![index];
                final dateTime = DateTime.parse(scan);
                final formattedDate =
                    DateFormat('MMM d, y\nHH:mm').format(dateTime);

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0),
                  child: InkWell(
                    onTap: () => onScanChanged(scan),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedScan == scan
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          width: selectedScan == scan ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          FutureBuilder<String?>(
                            future: _getImageUrl(selectedRoom, scan),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7)),
                                  child: Image.network(
                                    snapshot.data!,
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.error_outline),
                                      );
                                    },
                                  ),
                                );
                              }

                              return Container(
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),

                          // Timestamp
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: selectedScan == scan
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1)
                                    : Colors.grey.shade50,
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(7)),
                              ),
                              child: Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selectedScan == scan
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<String?> _getImageUrl(String room, String timestamp) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('scene_analysis_results')
          .where('room', isEqualTo: room)
          .where('timestamp', isEqualTo: timestamp)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final data = querySnapshot.docs.first.data();

      // Extract the original image URL from cloud_links
      if (data.containsKey('cloud_links') &&
          data['cloud_links'] is Map &&
          data['cloud_links'].containsKey('images') &&
          data['cloud_links']['images'] is Map &&
          data['cloud_links']['images'].containsKey('original') &&
          data['cloud_links']['images']['original'] is Map &&
          data['cloud_links']['images']['original'].containsKey('url')) {
        return data['cloud_links']['images']['original']['url'] as String;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting image URL: $e');
      return null;
    }
  }

  void _performScanComparison(
    String firstRoom,
    String firstTimestamp,
    String secondRoom,
    String secondTimestamp,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get image URLs for both scans
      final beforeImageUrl = await _getImageUrl(firstRoom, firstTimestamp);
      final afterImageUrl = await _getImageUrl(secondRoom, secondTimestamp);

      if (beforeImageUrl == null || afterImageUrl == null) {
        throw Exception('Failed to get image URLs');
      }

      // Initialize the comparison service
      final comparisonService = SceneComparisonService();

      // Start the comparison
      final jobId = await comparisonService.startComparison(
        beforeImageUrl: beforeImageUrl,
        afterImageUrl: afterImageUrl,
      );

      // Poll for completion
      bool isComplete = false;
      while (!isComplete) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await comparisonService.getStatus(jobId);
        if (status['status'] == 'Complete') {
          isComplete = true;
        } else if (status['status'] == 'Failed') {
          throw Exception('Comparison failed: ${status['message']}');
        }
      }

      // Get the results
      final results = await comparisonService.getResults(jobId);

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to comparison page with the results
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SceneComparisonPage(
            jobId: jobId,
            beforeRoom: firstRoom,
            beforeTimestamp: firstTimestamp,
            afterRoom: secondRoom,
            afterTimestamp: secondTimestamp,
            results: results,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to compare scans: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
