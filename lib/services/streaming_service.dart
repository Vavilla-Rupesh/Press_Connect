import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
// Note: flutter_rtmp_publisher would be used in real implementation

class StreamingService {
  static const String _backendUrl = 'http://localhost:3000'; // Node.js backend
  
  String? _currentStreamKey;
  String? _currentIngestUrl;
  bool _isStreaming = false;
  bool _isRecording = false;

  Future<Map<String, String>?> createYouTubeStream(String accessToken) async {
    try {
      // Call our Node.js backend to create YouTube broadcast and stream
      final response = await http.post(
        Uri.parse('$_backendUrl/api/create-stream'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'title': 'Live Stream from Press Connect - ${DateTime.now().toIso8601String()}',
          'description': 'Live streaming from Press Connect mobile app',
          'privacyStatus': 'public', // or 'private', 'unlisted'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentIngestUrl = data['ingestUrl'];
        _currentStreamKey = data['streamKey'];
        
        return {
          'ingestUrl': data['ingestUrl'],
          'streamKey': data['streamKey'],
          'broadcastId': data['broadcastId'],
        };
      } else {
        print('Failed to create stream: ${response.statusCode} - ${response.body}');
        
        // Fallback for demo purposes
        _currentIngestUrl = 'rtmp://a.rtmp.youtube.com/live2';
        _currentStreamKey = 'demo-stream-key-${DateTime.now().millisecondsSinceEpoch}';
        
        return {
          'ingestUrl': _currentIngestUrl!,
          'streamKey': _currentStreamKey!,
          'broadcastId': 'demo-broadcast-id',
        };
      }
    } catch (e) {
      print('Error creating YouTube stream: $e');
      
      // Fallback for demo purposes
      _currentIngestUrl = 'rtmp://a.rtmp.youtube.com/live2';
      _currentStreamKey = 'demo-stream-key-${DateTime.now().millisecondsSinceEpoch}';
      
      return {
        'ingestUrl': _currentIngestUrl!,
        'streamKey': _currentStreamKey!,
        'broadcastId': 'demo-broadcast-id',
      };
    }
  }

  Future<void> startStreaming(String ingestUrl, String streamKey) async {
    try {
      // In a real implementation, you would use flutter_rtmp_publisher
      // Something like:
      // await FlutterRtmpPublisher.startStream(
      //   url: '$ingestUrl/$streamKey',
      //   width: 720,
      //   height: 1280,
      //   bitrate: 2500,
      //   fps: 30,
      // );
      
      // For demo purposes, we'll simulate starting the stream
      await Future.delayed(const Duration(seconds: 2));
      _isStreaming = true;
      
      print('Started streaming to: $ingestUrl with key: $streamKey');
    } catch (e) {
      print('Error starting stream: $e');
      rethrow;
    }
  }

  Future<void> stopStreaming() async {
    try {
      // In a real implementation:
      // await FlutterRtmpPublisher.stopStream();
      
      // For demo purposes
      await Future.delayed(const Duration(seconds: 1));
      _isStreaming = false;
      
      // Optionally, call backend to end the YouTube broadcast
      if (_currentStreamKey != null) {
        try {
          await http.post(
            Uri.parse('$_backendUrl/api/end-stream'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'streamKey': _currentStreamKey}),
          );
        } catch (e) {
          print('Error ending stream on backend: $e');
        }
      }
      
      _currentStreamKey = null;
      _currentIngestUrl = null;
      
      print('Stopped streaming');
    } catch (e) {
      print('Error stopping stream: $e');
      rethrow;
    }
  }

  Future<bool> takeSnapshot() async {
    try {
      // In a real implementation, you would capture the current frame
      // from the camera/RTMP publisher with watermark overlay
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'snapshot_$timestamp.jpg';
      final filePath = '${directory.path}/$filename';
      
      // For demo purposes, we'll create a placeholder file
      final file = File(filePath);
      await file.writeAsString('Snapshot taken at ${DateTime.now()}');
      
      print('Snapshot saved to: $filePath');
      return true;
    } catch (e) {
      print('Error taking snapshot: $e');
      return false;
    }
  }

  Future<void> startRecording() async {
    try {
      // In a real implementation, you would start local recording
      // with the watermark overlay included
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'recording_$timestamp.mp4';
      final filePath = '${directory.path}/$filename';
      
      // For demo purposes
      await Future.delayed(const Duration(milliseconds: 500));
      _isRecording = true;
      
      print('Started recording to: $filePath');
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      // In a real implementation, you would stop the recording
      
      await Future.delayed(const Duration(milliseconds: 500));
      _isRecording = false;
      
      print('Stopped recording');
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  bool get isStreaming => _isStreaming;
  bool get isRecording => _isRecording;
  String? get currentStreamKey => _currentStreamKey;
}