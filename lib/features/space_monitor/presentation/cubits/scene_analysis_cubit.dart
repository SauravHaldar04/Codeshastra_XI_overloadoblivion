import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/data/repositories/scene_analysis_repository.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/domain/entities/scene_analysis_result.dart';

// Define states
abstract class SceneAnalysisState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SceneAnalysisInitial extends SceneAnalysisState {}

class SceneAnalysisLoading extends SceneAnalysisState {}

class SceneAnalysisLoaded extends SceneAnalysisState {
  final Map<String, SceneAnalysisResult> latestAnalysisByRoom;
  final List<String> allRooms;
  final int totalObjectCount;

  SceneAnalysisLoaded({
    required this.latestAnalysisByRoom,
    required this.allRooms,
    required this.totalObjectCount,
  });

  @override
  List<Object?> get props => [latestAnalysisByRoom, allRooms, totalObjectCount];
}

class SceneAnalysisError extends SceneAnalysisState {
  final String message;

  SceneAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}

class SceneAnalysisRoomDetailLoaded extends SceneAnalysisState {
  final List<SceneAnalysisResult> roomAnalyses;
  final String room;

  SceneAnalysisRoomDetailLoaded({
    required this.roomAnalyses,
    required this.room,
  });

  @override
  List<Object?> get props => [roomAnalyses, room];
}

// Cubit
class SceneAnalysisCubit extends Cubit<SceneAnalysisState> {
  final SceneAnalysisRepository _repository;
  StreamSubscription? _latestAnalysisSubscription;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _totalObjectsSubscription;
  StreamSubscription? _roomDetailSubscription;

  SceneAnalysisCubit(this._repository) : super(SceneAnalysisInitial());

  // Load data for dashboard
  void loadDashboardData() {
    emit(SceneAnalysisLoading());

    Map<String, SceneAnalysisResult> latestAnalysisByRoom = {};
    List<String> allRooms = [];
    int totalObjectCount = 0;
    int loadedStreams = 0;

    try {
      // Subscribe to latest analysis per room
      _latestAnalysisSubscription?.cancel();
      _latestAnalysisSubscription =
          _repository.getLatestAnalysisPerRoom().listen(
        (data) {
          latestAnalysisByRoom = data;
          loadedStreams++;
          _checkAndEmitLoaded(
              latestAnalysisByRoom, allRooms, totalObjectCount, loadedStreams);
        },
        onError: (error) {
          emit(SceneAnalysisError('Error loading analysis data: $error'));
        },
      );

      // Subscribe to rooms list
      _roomsSubscription?.cancel();
      _roomsSubscription = _repository.getAllRooms().listen(
        (data) {
          allRooms = data;
          loadedStreams++;
          _checkAndEmitLoaded(
              latestAnalysisByRoom, allRooms, totalObjectCount, loadedStreams);
        },
        onError: (error) {
          emit(SceneAnalysisError('Error loading room data: $error'));
        },
      );

      // Subscribe to total object count
      _totalObjectsSubscription?.cancel();
      _totalObjectsSubscription = _repository.getTotalObjectCount().listen(
        (data) {
          totalObjectCount = data;
          loadedStreams++;
          _checkAndEmitLoaded(
              latestAnalysisByRoom, allRooms, totalObjectCount, loadedStreams);
        },
        onError: (error) {
          emit(SceneAnalysisError('Error loading total count data: $error'));
        },
      );
    } catch (e) {
      emit(SceneAnalysisError('Failed to load dashboard data: $e'));
    }
  }

  void _checkAndEmitLoaded(
    Map<String, SceneAnalysisResult> latestAnalysisByRoom,
    List<String> allRooms,
    int totalObjectCount,
    int loadedStreams,
  ) {
    // When all three streams have loaded data, emit the loaded state
    if (loadedStreams >= 3) {
      emit(SceneAnalysisLoaded(
        latestAnalysisByRoom: latestAnalysisByRoom,
        allRooms: allRooms,
        totalObjectCount: totalObjectCount,
      ));
    }
  }

  // Load detail data for a specific room
  void loadRoomDetail(String room) {
    emit(SceneAnalysisLoading());

    try {
      _roomDetailSubscription?.cancel();
      _roomDetailSubscription =
          _repository.getSceneAnalysisResultsByRoom(room).listen(
        (data) {
          emit(SceneAnalysisRoomDetailLoaded(
            roomAnalyses: data,
            room: room,
          ));
        },
        onError: (error) {
          emit(SceneAnalysisError('Error loading room detail: $error'));
        },
      );
    } catch (e) {
      emit(SceneAnalysisError('Failed to load room detail: $e'));
    }
  }

  @override
  Future<void> close() {
    _latestAnalysisSubscription?.cancel();
    _roomsSubscription?.cancel();
    _totalObjectsSubscription?.cancel();
    _roomDetailSubscription?.cancel();
    return super.close();
  }
}
