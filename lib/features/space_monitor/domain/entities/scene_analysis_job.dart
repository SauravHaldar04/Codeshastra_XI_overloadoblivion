class SceneAnalysisJob {
  final String jobId;
  final String room;
  final String status;
  final String message;
  final Map<String, dynamic>? results;
  final Map<String, dynamic>? cloudLinks;

  SceneAnalysisJob({
    required this.jobId,
    required this.room,
    required this.status,
    required this.message,
    this.results,
    this.cloudLinks,
  });

  factory SceneAnalysisJob.fromAnalyzeResponse(Map<String, dynamic> json) {
    return SceneAnalysisJob(
      jobId: json['job_id'] ?? '',
      room: json['room'] ?? '',
      status: json['status'] ?? 'Unknown',
      message: json['message'] ?? '',
    );
  }

  factory SceneAnalysisJob.fromStatusResponse(
      Map<String, dynamic> json, String room) {
    return SceneAnalysisJob(
      jobId: json['job_id'] ?? '',
      room: room,
      status: json['status'] ?? 'Unknown',
      message: json['message'] ?? '',
    );
  }

  SceneAnalysisJob copyWithResults(Map<String, dynamic> resultsJson) {
    return SceneAnalysisJob(
      jobId: jobId,
      room: room,
      status: 'Complete',
      message: 'Results retrieved successfully',
      results: resultsJson['results'],
      cloudLinks: cloudLinks,
    );
  }

  SceneAnalysisJob copyWithCloudLinks(Map<String, dynamic> linksJson) {
    return SceneAnalysisJob(
      jobId: jobId,
      room: room,
      status: status,
      message: message,
      results: results,
      cloudLinks: linksJson['cloud_links'],
    );
  }

  bool get isComplete => status == 'Complete';
  bool get isProcessing => status == 'Processing';
  bool get hasError => status == 'Error';
  bool get hasResults => results != null;
  bool get hasCloudLinks => cloudLinks != null;

  // Detection count from results
  int get detectionCount {
    if (results != null && results!.containsKey('detection_count')) {
      return results!['detection_count'] ?? 0;
    }
    return 0;
  }

  // Get class summary from results
  List<Map<String, dynamic>> get classSummary {
    if (results != null && results!.containsKey('class_summary')) {
      return List<Map<String, dynamic>>.from(results!['class_summary'] ?? []);
    }
    return [];
  }

  // Get image URLs
  Map<String, String> get imageUrls {
    if (results != null && results!.containsKey('image_urls')) {
      return Map<String, String>.from(results!['image_urls'] ?? {});
    }
    return {};
  }

  // Get summary text
  String get summary {
    if (results != null && results!.containsKey('summary')) {
      return results!['summary'] ?? 'No summary available';
    }
    return 'No summary available';
  }
}
