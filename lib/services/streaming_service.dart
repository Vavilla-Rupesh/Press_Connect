import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'youtube_auth_service.dart';
// Note: flutter_rtmp_publisher would be used in real implementation

class StreamingService {
  static const String _backendUrl = 'http://localhost:3000';
  
  String? _currentStreamKey;
  String? _currentIngestUrl;
  String? _currentBroadcastId;
  int? _currentStreamDbId;
  bool _isStreaming = false;
  bool _isRecording = false;

  final YouTubeAuthService _authService = YouTubeAuthService();

  Future<Map<String, String>?> createYouTubeStream(String title, String description, String privacyStatus) async {
    try {
      final appToken = await _authService.getAppToken();
      if (appToken == null) {
        throw Exception('App authentication required');
      }

      // Call our backend to create YouTube broadcast and stream
      final response = await http.post(
        Uri.parse('$_backendUrl/api/create-stream'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appToken',
        },
        body: jsonEncode({
          'title': title.isEmpty ? 'Live Stream from Press Connect - ${DateTime.now().toIso8601String()}' : title,
          'description': description.isEmpty ? 'Live streaming from Press Connect mobile app' : description,
          'privacyStatus': privacyStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentIngestUrl = data['ingestUrl'];
        _currentStreamKey = data['streamKey'];
        _currentBroadcastId = data['broadcastId'];
        _currentStreamDbId = data['streamDbId'];
        
        return {
          'ingestUrl': data['ingestUrl'],
          'streamKey': data['streamKey'],
          'broadcastId': data['broadcastId'],
          'broadcastUrl': data['broadcastUrl'] ?? '',
        };
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        if (errorData['requiresReauth'] == true) {
          throw Exception('YouTube authentication required. Please re-authenticate with YouTube.');
        }
        throw Exception('Authentication failed');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create stream');
      }
    } catch (e) {
      print('Error creating YouTube stream: $e');
      rethrow;
    }
  }

  Future<void> startStreaming(String ingestUrl, String streamKey) async {
    try {
      if (_isStreaming) {
        throw Exception('Already streaming');
      }

      // In a real implementation, you would use flutter_rtmp_publisher
      // Something like:
      // await FlutterRtmpPublisher.startStream(
      //   url: '$ingestUrl/$streamKey',
      //   width: 720,
      //   height: 1280,
      //   bitrate: 2500,
      //   fps: 30,
      // );
      
      _isStreaming = true;
      
      // Notify backend that streaming has started
      await _updateStreamStatus('active');
      
      print('Started streaming to: $ingestUrl with key: $streamKey');
    } catch (e) {
      print('Error starting stream: $e');
      _isStreaming = false;
      rethrow;
    }
  }

  Future<void> _updateStreamStatus(String status) async {
    try {
      if (_currentStreamKey == null) return;
      
      final appToken = await _authService.getAppToken();
      if (appToken == null) return;

      await http.patch(
        Uri.parse('$_backendUrl/api/streams/$_currentStreamKey/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appToken',
        },
      );
    } catch (e) {
      print('Error updating stream status: $e');
    }
  }

  Future<void> stopStreaming() async {
    try {
      if (!_isStreaming) {
        return;
      }

      // In a real implementation:
      // await FlutterRtmpPublisher.stopStream();
      
      _isStreaming = false;
      
      // Call backend to end the YouTube broadcast
      if (_currentStreamKey != null) {
        try {
          final appToken = await _authService.getAppToken();
          if (appToken != null) {
            await http.post(
              Uri.parse('$_backendUrl/api/end-stream'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $appToken',
              },
              body: jsonEncode({'streamKey': _currentStreamKey}),
            );
          }
        } catch (e) {
          print('Error ending stream on backend: $e');
        }
      }
      
      _currentStreamKey = null;
      _currentIngestUrl = null;
      _currentBroadcastId = null;
      _currentStreamDbId = null;
      
      print('Stopped streaming');
    } catch (e) {
      print('Error stopping stream: $e');
      rethrow;
    }
  }

  Future<bool> takeSnapshot() async {
    try {
      if (!_isStreaming) {
        throw Exception('Not currently streaming');
      }

      // In a real implementation, you would capture the current frame
      // from the camera/RTMP publisher with watermark overlay
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'snapshot_$timestamp.jpg';
      final filePath = '${directory.path}/$filename';
      
      // For production, this would capture the actual camera frame
      // For now, we'll create a placeholder to show the functionality
      final file = File(filePath);
      await file.writeAsString('Snapshot taken at ${DateTime.now()}');
      
      // In a real implementation, you would also:
      // 1. Store snapshot metadata in the backend database
      // 2. Optionally upload the snapshot to cloud storage
      // 3. Add watermark information to the snapshot
      
      print('Snapshot saved to: $filePath');
      return true;
    } catch (e) {
      print('Error taking snapshot: $e');
      return false;
    }
  }

  Future<void> startRecording() async {
    try {
      if (_isRecording) {
        throw Exception('Already recording');
      }

      if (!_isStreaming) {
        throw Exception('Must be streaming to start recording');
      }

      // In a real implementation, you would start local recording
      // with the watermark overlay included
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'recording_$timestamp.mp4';
      final filePath = '${directory.path}/$filename';
      
      // For production, this would start actual video recording
      // with the camera stream including watermark overlay
      
      _isRecording = true;
      
      // In a real implementation, you would also:
      // 1. Store recording metadata in the backend database
      // 2. Configure recording quality and format
      // 3. Handle storage space management
      
      print('Started recording to: $filePath');
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      if (!_isRecording) {
        return;
      }

      // In a real implementation, you would stop the recording
      // and finalize the video file
      
      _isRecording = false;
      
      // In a real implementation, you would also:
      // 1. Finalize the recording file
      // 2. Update database with final file size and duration
      // 3. Optionally upload to cloud storage
      // 4. Generate thumbnail from the recording
      
      print('Stopped recording');
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>?> getActiveStreams() async {
    try {
      final appToken = await _authService.getAppToken();
      if (appToken == null) {
        throw Exception('App authentication required');
      }

      final response = await http.get(
        Uri.parse('$_backendUrl/api/streams'),
        headers: {
          'Authorization': 'Bearer $appToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['streams']);
      } else {
        throw Exception('Failed to fetch streams');
      }
    } catch (e) {
      print('Error fetching active streams: $e');
      return null;
    }
  }

  bool get isStreaming => _isStreaming;
  bool get isRecording => _isRecording;
  String? get currentStreamKey => _currentStreamKey;
  String? get currentBroadcastId => _currentBroadcastId;
  String? get currentBroadcastUrl => _currentBroadcastId != null 
    ? 'https://www.youtube.com/watch?v=$_currentBroadcastId' 
    : null;
}