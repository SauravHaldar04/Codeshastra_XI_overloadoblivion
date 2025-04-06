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
          final roomName = data['room_name'] as String?;
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
                    if (roomScans[selectedFirstRoom]!.length > 0) {
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

            return AlertDialog(
              title: const Text('Compare Scans'),
              content: isLoading
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : roomScans.isEmpty
                      ? const Text('No scans available for comparison')
                      : SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('First Scan (Before):'),
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
                              const SizedBox(height: 16),
                              const Text('Second Scan (After):'),
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                if (!isLoading && roomScans.isNotEmpty)
                  TextButton(
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
      children: [
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
        if (selectedRoom != null && roomScans[selectedRoom]!.isNotEmpty)
          DropdownButton<String>(
            isExpanded: true,
            value: selectedScan,
            items: roomScans[selectedRoom]!.map((scan) {
              // Format date for display
              final dateTime = DateTime.parse(scan);
              final formattedDate =
                  DateFormat('MMM d, y HH:mm').format(dateTime);
              return DropdownMenuItem<String>(
                value: scan,
                child: Text(formattedDate),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onScanChanged(value);
              }
            },
          ),
      ],
    );
  }

  void _performScanComparison(
    String firstRoom,
    String firstTimestamp,
    String secondRoom,
    String secondTimestamp,
  ) {
    // Determine which scan is earlier to set as "before"
    final firstDate = DateTime.parse(firstTimestamp);
    final secondDate = DateTime.parse(secondTimestamp);

    // Navigate to comparison page with the correct order of scans
    if (firstDate.isBefore(secondDate)) {
      // First scan is earlier, so it's the "before" scan
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SceneComparisonPage(
            beforeRoom: firstRoom,
            beforeTimestamp: firstTimestamp,
            afterRoom: secondRoom,
            afterTimestamp: secondTimestamp,
          ),
        ),
      );
    } else {
      // Second scan is earlier or same time, so it's the "before" scan
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SceneComparisonPage(
            beforeRoom: secondRoom,
            beforeTimestamp: secondTimestamp,
            afterRoom: firstRoom,
            afterTimestamp: firstTimestamp,
          ),
        ),
      );
    }
  }
}
