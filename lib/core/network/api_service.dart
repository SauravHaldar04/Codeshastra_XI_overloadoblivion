import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/server_exception.dart';

class ApiService {
  final Dio _dio = Dio();
  
  // Configure the FastAPI base URL
  static const String baseUrl = 'YOUR_FASTAPI_BASE_URL'; // Replace with your actual FastAPI URL
  
  // Endpoint for space optimization analysis
  static const String spaceOptimizationEndpoint = '/analyze_space';
  
  // Method to analyze space with an image
  Future<File> analyzeSpaceWithImage(File imageFile) async {
    try {
      // Create form data with the image file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'image.jpg',
        ),
        'file_type': 'image',
      });
      
      // Make the POST request
      final response = await _dio.post(
        '$baseUrl$spaceOptimizationEndpoint',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      
      // Save the response data to a temporary file
      final tempDir = Directory.systemTemp;
      final outputFile = File('${tempDir.path}/optimized_image.jpg');
      await outputFile.writeAsBytes(response.data);
      
      return outputFile;
    } catch (e) {
      throw ServerException(message: 'Failed to analyze space: ${e.toString()}');
    }
  }
  
  // Method to analyze space with a video
  Future<File> analyzeSpaceWithVideo(File videoFile) async {
    try {
      // Create form data with the video file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: 'video.mp4',
        ),
        'file_type': 'video',
      });
      
      // Make the POST request
      final response = await _dio.post(
        '$baseUrl$spaceOptimizationEndpoint',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      
      // Save the response data to a temporary file
      final tempDir = Directory.systemTemp;
      final outputFile = File('${tempDir.path}/optimized_video.mp4');
      await outputFile.writeAsBytes(response.data);
      
      return outputFile;
    } catch (e) {
      throw ServerException(message: 'Failed to analyze space: ${e.toString()}');
    }
  }
} 