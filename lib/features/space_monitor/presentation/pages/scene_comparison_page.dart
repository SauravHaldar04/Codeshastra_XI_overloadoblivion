import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/cubits/scene_comparison_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/widgets/image_comparison_slider.dart';
import 'package:http/http.dart' as http;

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
  late final SceneComparisonCubit _comparisonCubit;
  bool _isLoading = true;
  String? _errorMessage;

  // Image data
  Uint8List? _beforeOriginalImage;
  Uint8List? _afterOriginalImage;
  Uint8List? _beforeDepthImage;
  Uint8List? _afterDepthImage;
  Uint8List? _beforeDetectionImage;

  @override
  void initState() {
    super.initState();
    _comparisonCubit = GetIt.instance<SceneComparisonCubit>();
    _loadScans();
  }

  Future<void> _loadScans() async {
    await _comparisonCubit.loadImagesForComparison(
      beforeRoom: widget.beforeRoom,
      beforeTimestamp: widget.beforeTimestamp,
      afterRoom: widget.afterRoom,
      afterTimestamp: widget.afterTimestamp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _comparisonCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scene Comparison'),
          actions: [
            BlocBuilder<SceneComparisonCubit, SceneComparisonState>(
              builder: (context, state) {
                if (state is SceneComparisonComplete) {
                  return IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save Comparison',
                    onPressed: () {
                      // TODO: Implement saving of comparison results
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comparison saved'),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<SceneComparisonCubit, SceneComparisonState>(
          listener: (context, state) {
            if (state is SceneComparisonError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return _buildBody(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SceneComparisonState state) {
    if (state is SceneComparisonLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(state.message),
          ],
        ),
      );
    } else if (state is SceneComparisonImagesLoaded) {
      return _buildComparisonPreview(context, state);
    } else if (state is SceneComparisonProcessing) {
      return _buildProcessingView(context, state);
    } else if (state is SceneComparisonComplete) {
      return _buildComparisonResults(context, state);
    } else if (state is SceneComparisonError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadScans,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Initial state
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildComparisonPreview(
    BuildContext context,
    SceneComparisonImagesLoaded state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compare Scans',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analyzing changes between ${widget.beforeRoom} and ${widget.afterRoom}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildImagePreviewCard(
            context,
            'Before: ${widget.beforeRoom}',
            _formatTimestamp(widget.beforeTimestamp),
            Image.memory(
              state.beforeImage,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),
          _buildImagePreviewCard(
            context,
            'After: ${widget.afterRoom}',
            _formatTimestamp(widget.afterTimestamp),
            Image.memory(
              state.afterImage,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Start Comparison'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                // Start the comparison process
                _comparisonCubit.startComparison(
                  beforeImage: state.beforeImage,
                  afterImage: state.afterImage,
                  beforeRoom: state.beforeRoom,
                  beforeTimestamp: state.beforeTimestamp,
                  afterRoom: state.afterRoom,
                  afterTimestamp: state.afterTimestamp,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildProcessingView(
    BuildContext context,
    SceneComparisonProcessing state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.beforeImage != null && state.afterImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        state.beforeImage!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.compare_arrows),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        state.afterImage!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          const Text(
            'Processing Comparison',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a minute...',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: state.progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text('${state.progress}%'),
        ],
      ),
    );
  }

  Widget _buildComparisonResults(
    BuildContext context,
    SceneComparisonComplete state,
  ) {
    final statistics =
        state.results['results']['statistics'] as Map<String, dynamic>;
    final movements = state.results['results']['movements'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Card
          _buildSectionCard(
            context: context,
            title: 'Analysis Results',
            icon: Icons.analytics,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                    'Additions', statistics['additions']?.toString() ?? '0'),
                _buildStatRow(
                    'Removals', statistics['removals']?.toString() ?? '0'),
                _buildStatRow(
                    'Movements', statistics['movements']?.toString() ?? '0'),
                _buildStatRow('Before Detections',
                    statistics['before_detections']?.toString() ?? '0'),
                _buildStatRow('After Detections',
                    statistics['after_detections']?.toString() ?? '0'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Comparison Images
          _buildSectionCard(
            context: context,
            title: 'Image Comparison',
            icon: Icons.compare,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.images.containsKey('before_image') &&
                    state.images.containsKey('after_image'))
                  ImageComparisonSlider(
                    beforeImage: state.images['before_image']!,
                    afterImage: state.images['after_image']!,
                  )
                else
                  const Center(
                    child: Text('Images not available'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detection Images
          _buildSectionCard(
            context: context,
            title: 'Detection Results',
            icon: Icons.find_in_page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.images.containsKey('before_det_vis') &&
                    state.images.containsKey('after_det_vis'))
                  Column(
                    children: [
                      _buildImageCard(
                        'Before - Object Detection',
                        state.images['before_det_vis']!,
                      ),
                      const SizedBox(height: 12),
                      _buildImageCard(
                        'After - Object Detection',
                        state.images['after_det_vis']!,
                      ),
                    ],
                  )
                else
                  const Center(
                    child: Text('Detection images not available'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Depth Images
          _buildSectionCard(
            context: context,
            title: 'Depth Maps',
            icon: Icons.map,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.images.containsKey('before_depth_vis') &&
                    state.images.containsKey('after_depth_vis'))
                  Column(
                    children: [
                      _buildImageCard(
                        'Before - Depth Map',
                        state.images['before_depth_vis']!,
                      ),
                      const SizedBox(height: 12),
                      _buildImageCard(
                        'After - Depth Map',
                        state.images['after_depth_vis']!,
                      ),
                    ],
                  )
                else
                  const Center(
                    child: Text('Depth maps not available'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Changes visualization
          if (state.images.containsKey('changes_vis'))
            _buildSectionCard(
              context: context,
              title: 'Changes Visualization',
              icon: Icons.difference,
              child: _buildImageCard(
                'Object Changes',
                state.images['changes_vis']!,
              ),
            ),

          const SizedBox(height: 16),

          // Movements visualization
          if (state.images.containsKey('movements_vis'))
            _buildSectionCard(
              context: context,
              title: 'Movements Visualization',
              icon: Icons.move_down,
              child: _buildImageCard(
                'Object Movements',
                state.images['movements_vis']!,
              ),
            ),

          const SizedBox(height: 16),

          // Movements List
          _buildSectionCard(
            context: context,
            title: 'Detected Movements',
            icon: Icons.swap_horiz,
            child: movements.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('No movements detected'),
                  )
                : Column(
                    children: movements.map((movement) {
                      return ListTile(
                        leading: const Icon(Icons.arrow_forward),
                        title: Text(
                          '${movement['object_class']} moved ${movement['distance']} units',
                        ),
                        subtitle: Text(
                          'From: (${movement['start_x']}, ${movement['start_y']}) To: (${movement['end_x']}, ${movement['end_y']})',
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewCard(
    BuildContext context,
    String title,
    String subtitle,
    Widget image,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: image,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String title, Uint8List imageBytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final parsedDate = DateTime.parse(timestamp);
      return DateFormat('MMM d, y HH:mm').format(parsedDate);
    } catch (e) {
      return timestamp;
    }
  }
}
