import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/domain/entities/scene_analysis_result.dart';

class SceneAnalysisRepository {
  final FirebaseFirestore _firestore;

  SceneAnalysisRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Fetch all scene analysis results
  Stream<List<SceneAnalysisResult>> getSceneAnalysisResults() {
    return _firestore
        .collection('scene_analysis_results')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SceneAnalysisResult.fromFirestore(doc))
            .toList());
  }

  // Fetch scene analysis results for a specific room
  Stream<List<SceneAnalysisResult>> getSceneAnalysisResultsByRoom(String room) {
    return _firestore
        .collection('scene_analysis_results')
        .where('room', isEqualTo: room)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SceneAnalysisResult.fromFirestore(doc))
            .toList());
  }

  // Get latest analysis for each room
  Stream<Map<String, SceneAnalysisResult>> getLatestAnalysisPerRoom() {
    return _firestore
        .collection('scene_analysis_results')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final results = snapshot.docs
          .map((doc) => SceneAnalysisResult.fromFirestore(doc))
          .toList();

      // Group by room and get the first (most recent) for each
      final Map<String, SceneAnalysisResult> latestByRoom = {};
      for (final result in results) {
        if (!latestByRoom.containsKey(result.room)) {
          latestByRoom[result.room] = result;
        }
      }
      return latestByRoom;
    });
  }

  // Get all unique rooms
  Stream<List<String>> getAllRooms() {
    return _firestore
        .collection('scene_analysis_results')
        .snapshots()
        .map((snapshot) {
      final Set<String> rooms = {};
      for (final doc in snapshot.docs) {
        final room = doc.data()['room'];
        if (room != null && room is String) {
          rooms.add(room);
        }
      }
      return rooms.toList()..sort();
    });
  }

  // Get total object count across all rooms
  Stream<int> getTotalObjectCount() {
    return _firestore
        .collection('scene_analysis_results')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final results = snapshot.docs
          .map((doc) => SceneAnalysisResult.fromFirestore(doc))
          .toList();

      // Group by room and get the first (most recent) for each
      final Map<String, SceneAnalysisResult> latestByRoom = {};
      for (final result in results) {
        if (!latestByRoom.containsKey(result.room)) {
          latestByRoom[result.room] = result;
        }
      }

      // Sum detection counts from the latest analysis for each room
      return latestByRoom.values
          .fold(0, (sum, result) => sum + result.detectionCount);
    });
  }
}
