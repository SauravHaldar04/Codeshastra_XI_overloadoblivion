import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class SceneComparisonService {
  final String baseUrl = 'https://00c9-34-55-157-59.ngrok-free.app';
  final Dio _dio = Dio();

  // Start a new comparison job
  Future<String> startComparisonJob({
    required Uint8List beforeImageBytes,
    required Uint8List afterImageBytes,
    int distanceThreshold = 7,
    String modelName = 'yolov8x.pt',
    bool useMidas = true,
    bool useSam = true,
    double confidence = 0.25,
    double depthScale = 3.0,
    int minClusterSize = 50,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // Save bytes to temp files to use FormData
      final beforeImageFile = File('${tempDir.path}/before_image.png');
      final afterImageFile = File('${tempDir.path}/after_image.png');

      await beforeImageFile.writeAsBytes(beforeImageBytes);
      await afterImageFile.writeAsBytes(afterImageBytes);

      // Create form data
      final formData = FormData.fromMap({
        'before_image': await MultipartFile.fromFile(
          beforeImageFile.path,
          filename: 'before_image.png',
        ),
        'after_image': await MultipartFile.fromFile(
          afterImageFile.path,
          filename: 'after_image.png',
        ),
        'distance_threshold': distanceThreshold,
        'model_name': modelName,
        'use_midas': useMidas,
        'use_sam': useSam,
        'confidence': confidence,
        'depth_scale': depthScale,
        'min_cluster_size': minClusterSize,
      });

      final response = await _dio.post(
        '$baseUrl/api/analyze',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['job_id'] as String;
      } else {
        throw Exception(
            'Failed to start comparison job: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to start comparison job: $e');
    }
  }

  // Check job status
  Future<String> checkJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/status/$jobId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] as String;
      } else {
        throw Exception(
            'Failed to check job status: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to check job status: $e');
    }
  }

  // Get job results
  Future<Map<String, dynamic>> getJobResults(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/results/$jobId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to get job results: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get job results: $e');
    }
  }

  // Get image from the API
  Future<Uint8List> getImage(String jobId, String imageName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/image/$jobId/$imageName'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to get image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get image: $e');
    }
  }

  // Get graph data
  Future<Map<String, dynamic>> getGraphData(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/graph_data/$jobId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to get graph data: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get graph data: $e');
    }
  }
}
