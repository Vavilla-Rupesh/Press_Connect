import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/streaming_service.dart';
import '../services/youtube_auth_service.dart';
import '../widgets/watermark_overlay.dart';
import '../widgets/transparency_slider.dart';

class StreamingScreen extends StatefulWidget {
  const StreamingScreen({super.key});

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  CameraController? _cameraController;
  final StreamingService _streamingService = StreamingService();
  final YouTubeAuthService _authService = YouTubeAuthService();
  
  bool _isStreaming = false;
  bool _isLoading = false;
  bool _isRecording = false;
  double _watermarkOpacity = 0.5;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        setState(() {});
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _toggleStreaming() async {
    if (_isStreaming) {
      await _stopStreaming();
    } else {
      await _startStreaming();
    }
  }

  Future<void> _startStreaming() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if YouTube authentication is available
      final isYouTubeAuth = await _authService.isAuthenticated();
      if (!isYouTubeAuth) {
        throw Exception('YouTube authentication required. Please authenticate with YouTube first.');
      }

      // Show stream configuration dialog
      final streamConfig = await _showStreamConfigDialog();
      if (streamConfig == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final streamData = await _streamingService.createYouTubeStream(
        streamConfig['title']!,
        streamConfig['description']!,
        streamConfig['privacy']!,
      );
      
      if (streamData != null) {
        await _streamingService.startStreaming(
          streamData['ingestUrl']!,
          streamData['streamKey']!,
        );
        
        setState(() {
          _isStreaming = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Live streaming started!\nBroadcast URL: ${streamData['broadcastUrl']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start streaming: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<Map<String, String>?> _showStreamConfigDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPrivacy = 'public';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Stream'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Stream Title',
                  hintText: 'Enter stream title (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter stream description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPrivacy,
                decoration: const InputDecoration(
                  labelText: 'Privacy Setting',
                ),
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'unlisted', child: Text('Unlisted')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (value) => selectedPrivacy = value ?? 'public',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'title': titleController.text,
                'description': descriptionController.text,
                'privacy': selectedPrivacy,
              });
            },
            child: const Text('Start Stream'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopStreaming() async {
    try {
      await _streamingService.stopStreaming();
      setState(() {
        _isStreaming = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live streaming stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeSnapshot() async {
    try {
      final success = await _streamingService.takeSnapshot();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snapshot saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take snapshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        await _streamingService.stopRecording();
        setState(() {
          _isRecording = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording stopped and saved!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _streamingService.startRecording();
        setState(() {
          _isRecording = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording started!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    
    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );
    
    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isStreaming ? 'Live Streaming' : 'Press Connect'),
        backgroundColor: _isStreaming ? Colors.red : Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.switch_camera),
              tooltip: 'Switch Camera',
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview with Watermark Overlay
          Expanded(
            child: Stack(
              children: [
                // Camera Preview
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  Container(
                    width: double.infinity,
                    child: CameraPreview(_cameraController!),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                
                // Watermark Overlay
                WatermarkOverlay(opacity: _watermarkOpacity),
                
                // Live indicator
                if (_isStreaming)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Recording indicator
                if (_isRecording)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Watermark Transparency Slider (only when not streaming)
          if (!_isStreaming) 
            TransparencySlider(
              opacity: _watermarkOpacity,
              onChanged: (value) {
                setState(() {
                  _watermarkOpacity = value;
                });
              },
            ),
          
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Snapshot Button
                IconButton(
                  onPressed: _isStreaming ? _takeSnapshot : null,
                  icon: Icon(
                    Icons.camera_alt,
                    color: _isStreaming ? Colors.white : Colors.grey,
                    size: 30,
                  ),
                  tooltip: 'Take Snapshot',
                ),
                
                // Recording Button
                IconButton(
                  onPressed: _toggleRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    color: _isRecording ? Colors.red : Colors.white,
                    size: 30,
                  ),
                  tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
                ),
                
                // Go Live Button
                GestureDetector(
                  onTap: _isLoading ? null : _toggleStreaming,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isStreaming ? Colors.red : Colors.white,
                      border: Border.all(
                        color: Colors.red,
                        width: 3,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.red)
                        : Icon(
                            _isStreaming ? Icons.stop : Icons.play_arrow,
                            color: _isStreaming ? Colors.white : Colors.red,
                            size: 40,
                          ),
                  ),
                ),
                
                // Settings placeholder
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 30,
                  ),
                  tooltip: 'Settings',
                ),
                
                // Menu placeholder
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 30,
                  ),
                  tooltip: 'Menu',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}