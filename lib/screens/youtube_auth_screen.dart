import 'package:flutter/material.dart';
import '../services/youtube_auth_service.dart';
import 'streaming_screen.dart';

class YouTubeAuthScreen extends StatefulWidget {
  const YouTubeAuthScreen({super.key});

  @override
  State<YouTubeAuthScreen> createState() => _YouTubeAuthScreenState();
}

class _YouTubeAuthScreenState extends State<YouTubeAuthScreen> {
  final YouTubeAuthService _authService = YouTubeAuthService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      final email = await _authService.getUserEmail();
      setState(() {
        _isAuthenticated = true;
        _userEmail = email;
      });
    }
  }

  Future<void> _authenticateWithYouTube() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.authenticate();
      if (success) {
        final email = await _authService.getUserEmail();
        setState(() {
          _isAuthenticated = true;
          _userEmail = email;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully authenticated with YouTube!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to authenticate with YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _proceedToStreaming() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const StreamingScreen(),
      ),
    );
  }

  void _logout() async {
    await _authService.logout();
    setState(() {
      _isAuthenticated = false;
      _userEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Authentication'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isAuthenticated)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_camera_back,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 32),
            const Text(
              'YouTube Authentication',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isAuthenticated
                  ? 'You are connected to YouTube!'
                  : 'Connect your YouTube account to start live streaming',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            if (_isAuthenticated) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connected to YouTube',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (_userEmail != null)
                            Text(
                              _userEmail!,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _proceedToStreaming,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Proceed to Streaming',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _authenticateWithYouTube,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.video_camera_back),
                  label: Text(
                    _isLoading ? 'Connecting...' : 'Connect to YouTube',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Note: This will redirect you to YouTube OAuth for secure authentication.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}