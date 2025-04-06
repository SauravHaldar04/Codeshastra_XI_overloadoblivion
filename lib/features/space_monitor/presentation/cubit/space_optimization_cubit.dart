import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:codeshastraxi_overload_oblivion/core/network/api_service.dart';
import 'package:get_it/get_it.dart';

// States
abstract class SpaceOptimizationState extends Equatable {
  const SpaceOptimizationState();
  
  @override
  List<Object?> get props => [];
}

class SpaceOptimizationInitial extends SpaceOptimizationState {}

class SpaceOptimizationLoading extends SpaceOptimizationState {}

class SpaceOptimizationUploading extends SpaceOptimizationState {
  final double progress;
  
  const SpaceOptimizationUploading(this.progress);
  
  @override
  List<Object?> get props => [progress];
}

class SpaceOptimizationSuccess extends SpaceOptimizationState {
  final File resultFile;
  final bool isVideo;
  
  const SpaceOptimizationSuccess({
    required this.resultFile,
    required this.isVideo,
  });
  
  @override
  List<Object?> get props => [resultFile, isVideo];
}

class SpaceOptimizationFailure extends SpaceOptimizationState {
  final String message;
  
  const SpaceOptimizationFailure(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Cubit
class SpaceOptimizationCubit extends Cubit<SpaceOptimizationState> {
  final ApiService _apiService = GetIt.instance<ApiService>();
  final ImagePicker _picker = ImagePicker();
  
  SpaceOptimizationCubit() : super(SpaceOptimizationInitial());
  
  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _analyzeImage(File(image.path));
      }
    } catch (e) {
      emit(SpaceOptimizationFailure('Failed to pick image: ${e.toString()}'));
    }
  }
  
  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _analyzeImage(File(image.path));
      }
    } catch (e) {
      emit(SpaceOptimizationFailure('Failed to capture image: ${e.toString()}'));
    }
  }
  
  // Pick video from gallery
  Future<void> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        await _analyzeVideo(File(video.path));
      }
    } catch (e) {
      emit(SpaceOptimizationFailure('Failed to pick video: ${e.toString()}'));
    }
  }
  
  // Pick video from camera
  Future<void> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        await _analyzeVideo(File(video.path));
      }
    } catch (e) {
      emit(SpaceOptimizationFailure('Failed to capture video: ${e.toString()}'));
    }
  }
  
  // Process image for space optimization
  Future<void> _analyzeImage(File imageFile) async {
    try {
      emit(SpaceOptimizationLoading());
      final resultFile = await _apiService.analyzeSpaceWithImage(imageFile);
      emit(SpaceOptimizationSuccess(resultFile: resultFile, isVideo: false));
    } catch (e) {
      emit(SpaceOptimizationFailure(e.toString()));
    }
  }
  
  // Process video for space optimization
  Future<void> _analyzeVideo(File videoFile) async {
    try {
      emit(SpaceOptimizationLoading());
      final resultFile = await _apiService.analyzeSpaceWithVideo(videoFile);
      emit(SpaceOptimizationSuccess(resultFile: resultFile, isVideo: true));
    } catch (e) {
      emit(SpaceOptimizationFailure(e.toString()));
    }
  }
  
  // Reset state
  void reset() {
    emit(SpaceOptimizationInitial());
  }
} 