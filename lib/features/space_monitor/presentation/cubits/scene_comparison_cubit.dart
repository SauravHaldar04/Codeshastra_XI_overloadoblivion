import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/data/services/scene_comparison_service.dart';

// Define states
abstract class SceneComparisonState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SceneComparisonInitial extends SceneComparisonState {}

class SceneComparisonLoading extends SceneComparisonState {
  final String message;

  SceneComparisonLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
}

class SceneComparisonImagesLoaded extends SceneComparisonState {
  final Uint8List beforeImage;
  final Uint8List afterImage;
  final String beforeRoom;
  final String beforeTimestamp;
  final String afterRoom;
  final String afterTimestamp;

  SceneComparisonImagesLoaded({
    required this.beforeImage,
    required this.afterImage,
    required this.beforeRoom,
    required this.beforeTimestamp,
    required this.afterRoom,
    required this.afterTimestamp,
  });

  @override
  List<Object?> get props => [
        beforeImage,
        afterImage,
        beforeRoom,
        beforeTimestamp,
        afterRoom,
        afterTimestamp
      ];
}

class SceneComparisonProcessing extends SceneComparisonState {
  final String jobId;
  final Uint8List? beforeImage;
  final Uint8List? afterImage;
  final int progress;

  SceneComparisonProcessing({
    required this.jobId,
    this.beforeImage,
    this.afterImage,
    this.progress = 0,
  });

  @override
  List<Object?> get props => [jobId, beforeImage, afterImage, progress];

  SceneComparisonProcessing copyWith({
    String? jobId,
    Uint8List? beforeImage,
    Uint8List? afterImage,
    int? progress,
  }) {
    return SceneComparisonProcessing(
      jobId: jobId ?? this.jobId,
      beforeImage: beforeImage ?? this.beforeImage,
      afterImage: afterImage ?? this.afterImage,
      progress: progress ?? this.progress,
    );
  }
}

class SceneComparisonComplete extends SceneComparisonState {
  final String jobId;
  final Map<String, dynamic> results;
  final Map<String, Uint8List> images;
  final Map<String, dynamic>? graphData;

  SceneComparisonComplete({
    required this.jobId,
    required this.results,
    required this.images,
    this.graphData,
  });

  @override
  List<Object?> get props => [jobId, results, images, graphData];
}

class SceneComparisonError extends SceneComparisonState {
  final String message;

  SceneComparisonError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SceneComparisonCubit extends Cubit<SceneComparisonState> {
  final FirebaseFirestore _firestore;
  final SceneComparisonService _comparisonService;
  Timer? _statusCheckTimer;

  SceneComparisonCubit({
    FirebaseFirestore? firestore,
    SceneComparisonService? comparisonService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _comparisonService = comparisonService ?? SceneComparisonService(),
        super(SceneComparisonInitial());

  // Load images from Firestore for comparison
  Future<void> loadImagesForComparison({
    required String beforeRoom,
    required String beforeTimestamp,
    required String afterRoom,
    required String afterTimestamp,
  }) async {
    emit(SceneComparisonLoading(message: 'Loading scan images...'));

    try {
      // Load before image from Firestore
      final beforeImageBytes =
          await _loadImageFromFirestore(beforeRoom, beforeTimestamp);
      if (beforeImageBytes == null) {
        emit(
            SceneComparisonError('Could not load before image from Firestore'));
        return;
      }

      // Load after image from Firestore
      final afterImageBytes =
          await _loadImageFromFirestore(afterRoom, afterTimestamp);
      if (afterImageBytes == null) {
        emit(SceneComparisonError('Could not load after image from Firestore'));
        return;
      }

      emit(SceneComparisonImagesLoaded(
        beforeImage: beforeImageBytes,
        afterImage: afterImageBytes,
        beforeRoom: beforeRoom,
        beforeTimestamp: beforeTimestamp,
        afterRoom: afterRoom,
        afterTimestamp: afterTimestamp,
      ));
    } catch (e) {
      emit(SceneComparisonError('Error loading images: $e'));
    }
  }

  // Start comparison process
  Future<void> startComparison({
    required String beforeImageUrl,
    required String afterImageUrl,
    required String beforeRoom,
    required String beforeTimestamp,
    required String afterRoom,
    required String afterTimestamp,
  }) async {
    emit(SceneComparisonLoading(message: 'Starting comparison process...'));

    try {
      // Start the comparison job
      final jobId = await _comparisonService.startComparison(
        beforeImageUrl: beforeImageUrl,
        afterImageUrl: afterImageUrl,
      );

      emit(SceneComparisonProcessing(
        jobId: jobId,
        beforeImage: null,
        afterImage: null,
      ));

      // Start periodically checking the job status
      _startStatusChecking(jobId);
    } catch (e) {
      emit(SceneComparisonError('Error starting comparison: $e'));
    }
  }

  // Retrieve results once the job is complete
  Future<void> retrieveResults(String jobId) async {
    emit(SceneComparisonLoading(message: 'Retrieving comparison results...'));

    try {
      // Get the job results
      final results = await _comparisonService.getResults(jobId);

      // Get the result images
      final imageUrls = results['image_urls'] as Map<String, dynamic>;
      final images = <String, Uint8List>{};

      // Download all the images
      for (final entry in imageUrls.entries) {
        final imageName = entry.key;
        final url = entry.value as String;

        // Extract just the filename from the URL path
        final filename = url.split('/').last;

        try {
          final imageBytes = await _comparisonService.getImage(jobId, filename);
          images[imageName] = Uint8List.fromList(imageBytes);
        } catch (e) {
          print('Error downloading image $imageName: $e');
          // Continue with other images even if one fails
        }
      }

      // Get the graph data
      Map<String, dynamic>? graphData;
      try {
        graphData = await _comparisonService.getGraphData(jobId);
      } catch (e) {
        print('Error getting graph data: $e');
        // Continue even if graph data fails
      }

      emit(SceneComparisonComplete(
        jobId: jobId,
        results: results,
        images: images,
        graphData: graphData,
      ));
    } catch (e) {
      emit(SceneComparisonError('Error retrieving results: $e'));
    }
  }

  // Helper method to start checking job status periodically
  void _startStatusChecking(String jobId) {
    _statusCheckTimer?.cancel();
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (state is! SceneComparisonProcessing) {
        timer.cancel();
        return;
      }

      try {
        final status = await _comparisonService.getStatus(jobId);

        if (status['status'].toString().toLowerCase() == 'complete') {
          timer.cancel();
          await retrieveResults(jobId);
        } else {
          // Update progress (estimated if not available)
          final currentState = state as SceneComparisonProcessing;
          final newProgress = (currentState.progress + 10).clamp(0, 95);
          emit(currentState.copyWith(progress: newProgress));
        }
      } catch (e) {
        print('Error checking job status: $e');
        // Don't emit error, just keep trying
      }
    });
  }

  // Helper method to load image from Firestore
  Future<Uint8List?> _loadImageFromFirestore(
      String room, String timestamp) async {
    try {
      final querySnapshot = await _firestore
          .collection('scene_analysis_results')
          .where('room', isEqualTo: room)
          .where('timestamp', isEqualTo: timestamp)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No document found for room: $room, timestamp: $timestamp');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      String? imageUrl;

      // Extract the original image URL from cloud_links
      if (data.containsKey('cloud_links') &&
          data['cloud_links'] is Map &&
          data['cloud_links'].containsKey('images') &&
          data['cloud_links']['images'] is Map &&
          data['cloud_links']['images'].containsKey('original') &&
          data['cloud_links']['images']['original'] is Map &&
          data['cloud_links']['images']['original'].containsKey('url')) {
        imageUrl = data['cloud_links']['images']['original']['url'] as String;
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        print('No image URL found for room: $room, timestamp: $timestamp');
        return null;
      }

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error downloading image: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading image from Firestore: $e');
      return null;
    }
  }

  @override
  Future<void> close() {
    _statusCheckTimer?.cancel();
    return super.close();
  }
}
