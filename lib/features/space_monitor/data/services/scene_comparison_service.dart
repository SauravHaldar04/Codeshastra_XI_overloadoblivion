import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class SceneComparisonService {
  static const String baseUrl = 'https://fbba-34-138-119-213.ngrok-free.app';
  final Dio _dio = Dio();

  // Start a new comparison job
  Future<String> startComparison({
    required String beforeImageUrl,
    required String afterImageUrl,
    double? depthScale = 3.0,
    int? distanceThreshold = 7,
    int? minClusterSize = 50,
    double? confidence = 0.25,
    String? modelName = 'yolov8x.pt',
    bool? useMidas = true,
    bool? useSam = true,
  }) async {
    final beforeImageResponse = await http.get(Uri.parse(beforeImageUrl));
    final afterImageResponse = await http.get(Uri.parse(afterImageUrl));

    if (beforeImageResponse.statusCode != 200 ||
        afterImageResponse.statusCode != 200) {
      throw Exception('Failed to download images');
    }

    final uri = Uri.parse('$baseUrl/api/analyze');
    final request = http.MultipartRequest('POST', uri);

    // Add image files
    request.files.add(
      http.MultipartFile.fromBytes(
        'before_image',
        beforeImageResponse.bodyBytes,
        filename: 'before_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'after_image',
        afterImageResponse.bodyBytes,
        filename: 'after_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    // Add optional parameters
    request.fields['depth_scale'] = depthScale.toString();
    request.fields['distance_threshold'] = distanceThreshold.toString();
    request.fields['min_cluster_size'] = minClusterSize.toString();
    request.fields['confidence'] = confidence.toString();
    request.fields['model_name'] = modelName ?? 'yolov8x.pt';
    request.fields['use_midas'] = (useMidas ?? true).toString();
    request.fields['use_sam'] = (useSam ?? true).toString();

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode != 200) {
      throw Exception('Failed to start comparison: ${data['message']}');
    }

    return data['job_id'];
  }

  // Check job status
  Future<Map<String, dynamic>> getStatus(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/status/$jobId'));
    return jsonDecode(response.body);
  }

  // Get job results
  Future<Map<String, dynamic>> getResults(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/results/$jobId'));
    return jsonDecode(response.body);
  }

  // Get image from the API
  Future<List<int>> getImage(String jobId, String imageName) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/image/$jobId/$imageName'));
    if (response.statusCode != 200) {
      throw Exception('Failed to get image');
    }
    return response.bodyBytes;
  }

  // Get graph data
  Future<Map<String, dynamic>> getGraphData(String jobId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/graph_data/$jobId'));
    return jsonDecode(response.body);
  }
}
