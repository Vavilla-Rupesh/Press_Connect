import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeAuthService {
  static const String _clientId = 'YOUR_YOUTUBE_CLIENT_ID';
  static const String _clientSecret = 'YOUR_YOUTUBE_CLIENT_SECRET';
  static const String _redirectUri = 'http://localhost:8080/auth/callback';
  static const String _scope = 'https://www.googleapis.com/auth/youtube';
  static const String _backendUrl = 'http://localhost:3000';
  
  static const String _authTokenKey = 'youtube_auth_token';
  static const String _refreshTokenKey = 'youtube_refresh_token';
  static const String _userEmailKey = 'youtube_user_email';
  static const String _appTokenKey = 'app_auth_token';

  Future<bool> authenticate() async {
    try {
      // Get the app auth token first
      final appToken = await getAppToken();
      if (appToken == null) {
        throw Exception('App authentication required');
      }

      // Construct proper OAuth2 URL
      final authUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
          '?client_id=$_clientId'
          '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
          '&scope=${Uri.encodeComponent(_scope)}'
          '&response_type=code'
          '&access_type=offline'
          '&prompt=consent';

      // Launch browser for authentication
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication
        );
        
        // In a real implementation, you would handle the callback
        // and exchange the authorization code for tokens
        return await _handleAuthCallback();
      }
      return false;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  Future<bool> _handleAuthCallback() async {
    // In a real implementation, this would:
    // 1. Listen for the callback URL
    // 2. Extract the authorization code
    // 3. Exchange it for access and refresh tokens
    // 4. Store the tokens securely
    
    // For now, we'll simulate waiting for the user to complete auth
    // and manually handle the token exchange
    await Future.delayed(const Duration(seconds: 5));
    
    // Return false to indicate manual token setup is needed
    return false;
  }

  Future<bool> exchangeCodeForTokens(String authorizationCode) async {
    try {
      final appToken = await getAppToken();
      if (appToken == null) {
        throw Exception('App authentication required');
      }

      // Exchange authorization code for tokens
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': authorizationCode,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store tokens locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, data['access_token']);
        if (data['refresh_token'] != null) {
          await prefs.setString(_refreshTokenKey, data['refresh_token']);
        }

        // Get user info
        final userResponse = await http.get(
          Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
          headers: {'Authorization': 'Bearer ${data['access_token']}'},
        );

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          await prefs.setString(_userEmailKey, userData['email'] ?? '');
        }

        // Store tokens in backend
        await _storeTokensInBackend(
          data['access_token'],
          data['refresh_token'],
          data['expires_in'],
          _scope
        );

        return true;
      }
      return false;
    } catch (e) {
      print('Token exchange error: $e');
      return false;
    }
  }

  Future<void> _storeTokensInBackend(String accessToken, String? refreshToken, int? expiresIn, String scope) async {
    try {
      final appToken = await getAppToken();
      if (appToken == null) return;

      await http.post(
        Uri.parse('$_backendUrl/api/auth/oauth/store'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appToken',
        },
        body: jsonEncode({
          'provider': 'youtube',
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': expiresIn,
          'scope': scope,
        }),
      );
    } catch (e) {
      print('Error storing tokens in backend: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAppToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_appTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> setAppToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appTokenKey, token);
    } catch (e) {
      print('Error setting app token: $e');
    }
  }

  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userEmailKey);
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString(_authTokenKey, data['access_token']);
        
        // Update backend tokens
        await _storeTokensInBackend(
          data['access_token'],
          refreshToken,
          data['expires_in'],
          _scope
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
}