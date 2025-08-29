import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeAuthService {
  static const String _clientId = 'YOUR_YOUTUBE_CLIENT_ID';
  static const String _clientSecret = 'YOUR_YOUTUBE_CLIENT_SECRET';
  static const String _redirectUri = 'http://localhost:8080/auth/callback';
  static const String _scope = 'https://www.googleapis.com/auth/youtube';
  
  static const String _authTokenKey = 'youtube_auth_token';
  static const String _refreshTokenKey = 'youtube_refresh_token';
  static const String _userEmailKey = 'youtube_user_email';

  Future<bool> authenticate() async {
    try {
      // For demo purposes, we'll simulate OAuth flow
      // In a real app, you'd implement proper OAuth2 flow
      
      final authUrl = 'https://accounts.google.com/oauth/authorize'
          '?client_id=$_clientId'
          '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
          '&scope=${Uri.encodeComponent(_scope)}'
          '&response_type=code'
          '&access_type=offline';

      // Launch browser for authentication
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(Uri.parse(authUrl));
        
        // For demo purposes, simulate successful authentication
        await Future.delayed(const Duration(seconds: 3));
        
        // Store demo tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString(_refreshTokenKey, 'demo_refresh_token');
        await prefs.setString(_userEmailKey, 'demo@youtube.com');
        
        return true;
      }
      return false;
    } catch (e) {
      print('Authentication error: $e');
      return false;
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

      // In a real app, you'd call the token refresh endpoint
      // For demo, we'll just generate a new token
      await prefs.setString(_authTokenKey, 'refreshed_access_token_${DateTime.now().millisecondsSinceEpoch}');
      
      return true;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
}