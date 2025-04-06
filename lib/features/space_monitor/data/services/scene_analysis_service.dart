import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Global constant for the API base URL
const String sceneAnalysisApiBaseUrl =
    'https://4b1c-35-227-135-58.ngrok-free.app';

class SceneAnalysisService {
  static final SceneAnalysisService _instance =
      SceneAnalysisService._internal();

  // Singleton pattern
  factory SceneAnalysisService() {
    return _instance;
  }

  SceneAnalysisService._internal();

  /// Analyzes an image using the scene analysis API
  Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    required String room,
    double confidence = 0.25,
    String modelName = 'yolov8x.pt',
    bool useMidas = true,
    bool useSam = true,
  }) async {
    var uri = Uri.parse('$sceneAnalysisApiBaseUrl/api/analyze');

    // Create a multipart request
    var request = http.MultipartRequest('POST', uri);

    // Add file to the request
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    // Add other fields
    request.fields['room'] = room;
    request.fields['confidence'] = confidence.toString();
    request.fields['model_name'] = modelName;
    request.fields['use_midas'] = useMidas.toString();
    request.fields['use_sam'] = useSam.toString();

    try {
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image: $e');
    }
  }

  /// Checks the status of a processing job
  Future<Map<String, dynamic>> checkStatus(String jobId) async {
    var uri = Uri.parse('$sceneAnalysisApiBaseUrl/api/status/$jobId');

    try {
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking status: $e');
    }
  }

  /// Gets the results of a completed job
  Future<Map<String, dynamic>> getResults(String jobId) async {
    var uri = Uri.parse('$sceneAnalysisApiBaseUrl/api/results/$jobId');

    try {
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get results: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting results: $e');
    }
  }

  /// Gets the cloud links for a completed job
  Future<Map<String, dynamic>> getCloudLinks(String jobId) async {
    var uri = Uri.parse('$sceneAnalysisApiBaseUrl/api/cloud/$jobId');

    try {
      var response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get cloud links: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting cloud links: $e');
    }
  }

  /// Gets the image URL for a specific image from the results
  String getImageUrl(String jobId, String imageName) {
    return '$sceneAnalysisApiBaseUrl/api/image/$jobId/$imageName';
  }
}
