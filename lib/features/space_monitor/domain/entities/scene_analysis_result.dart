import 'package:cloud_firestore/cloud_firestore.dart';

class ObjectCount {
  final String objectClass;
  final int count;

  ObjectCount({
    required this.objectClass,
    required this.count,
  });

  factory ObjectCount.fromMap(Map<String, dynamic> map) {
    return ObjectCount(
      objectClass: map['class'] ?? '',
      count: map['count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class': objectClass,
      'count': count,
    };
  }
}

class CloudLink {
  final String format;
  final String publicId;
  final String secureUrl;
  final String url;

  CloudLink({
    required this.format,
    required this.publicId,
    required this.secureUrl,
    required this.url,
  });

  factory CloudLink.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CloudLink.empty();
    }

    return CloudLink(
      format: map['format'] ?? '',
      publicId: map['public_id'] ?? '',
      secureUrl: map['secure_url'] ?? '',
      url: map['url'] ?? '',
    );
  }

  // Create an empty CloudLink for cases where data is missing
  factory CloudLink.empty() {
    return CloudLink(
      format: '',
      publicId: '',
      secureUrl: '',
      url: '',
    );
  }

  // Check if this link is valid (has a non-empty secureUrl)
  bool get isValid => secureUrl.isNotEmpty;
}

class CloudImages {
  final CloudLink depth;
  final CloudLink detection;
  final CloudLink original;
  final CloudLink segmentation;

  CloudImages({
    required this.depth,
    required this.detection,
    required this.original,
    required this.segmentation,
  });

  factory CloudImages.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CloudImages.empty();
    }

    return CloudImages(
      depth: CloudLink.fromMap(map['depth']),
      detection: CloudLink.fromMap(map['detection']),
      original: CloudLink.fromMap(map['original']),
      segmentation: CloudLink.fromMap(map['segmentation']),
    );
  }

  // Create an empty CloudImages for cases where data is missing
  factory CloudImages.empty() {
    return CloudImages(
      depth: CloudLink.empty(),
      detection: CloudLink.empty(),
      original: CloudLink.empty(),
      segmentation: CloudLink.empty(),
    );
  }

  // Check if any images are valid
  bool get hasValidImages =>
      depth.isValid ||
      detection.isValid ||
      original.isValid ||
      segmentation.isValid;
}

class CloudData {
  final CloudLink graphData;
  final CloudLink results;
  final CloudLink summary;

  CloudData({
    required this.graphData,
    required this.results,
    required this.summary,
  });

  factory CloudData.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CloudData.empty();
    }

    return CloudData(
      graphData: CloudLink.fromMap(map['graph_data']),
      results: CloudLink.fromMap(map['results']),
      summary: CloudLink.fromMap(map['summary']),
    );
  }

  // Create an empty CloudData for cases where data is missing
  factory CloudData.empty() {
    return CloudData(
      graphData: CloudLink.empty(),
      results: CloudLink.empty(),
      summary: CloudLink.empty(),
    );
  }
}

class SceneAnalysisResult {
  final List<ObjectCount> classSummary;
  final CloudData cloudLinks;
  final CloudImages images;
  final String jobId;
  final String timestamp;
  final int detectionCount;
  final String room;
  final String summary;

  SceneAnalysisResult({
    required this.classSummary,
    required this.cloudLinks,
    required this.images,
    required this.jobId,
    required this.timestamp,
    required this.detectionCount,
    required this.room,
    required this.summary,
  });

  factory SceneAnalysisResult.fromMap(Map<String, dynamic> map) {
    List<ObjectCount> classSummaryList = [];
    if (map['class_summary'] != null) {
      classSummaryList = List<ObjectCount>.from((map['class_summary'] as List)
          .map((item) => ObjectCount.fromMap(item)));
    }

    return SceneAnalysisResult(
      classSummary: classSummaryList,
      cloudLinks: CloudData.fromMap(map['cloud_links']) ?? CloudData.empty(),
      images: CloudImages.fromMap(map['images']) ?? CloudImages.empty(),
      jobId: map['job_id'] ?? '',
      timestamp: map['timestamp'] ?? '',
      detectionCount: map['detection_count'] ?? 0,
      room: map['room'] ?? '',
      summary: map['summary'] ?? '',
    );
  }

  factory SceneAnalysisResult.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SceneAnalysisResult.fromMap(data);
  }

  DateTime get timestampDateTime =>
      DateTime.tryParse(timestamp) ?? DateTime.now();

  String get formattedDate {
    final date = timestampDateTime;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
