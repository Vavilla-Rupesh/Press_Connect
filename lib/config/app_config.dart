/// Configuration service for managing app-wide settings and URLs
/// Supports different environments (development, production) and centralizes
/// all backend URL configurations in one place.
class AppConfig {
  /// Private constructor to prevent instantiation
  AppConfig._();

  /// Environment types
  static const String _development = 'development';
  static const String _production = 'production';
  
  /// Current environment - can be configured at build time
  static const String _currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: _development,
  );

  /// Backend base URL configuration
  static const Map<String, String> _backendUrls = {
    _development: 'http://localhost:3000',
    _production: String.fromEnvironment('BACKEND_URL', defaultValue: 'https://api.pressconnect.com'),
  };

  /// OAuth redirect URI configuration  
  static const Map<String, String> _redirectUris = {
    _development: 'http://localhost:8080/auth/callback',
    _production: String.fromEnvironment('OAUTH_REDIRECT_URI', defaultValue: 'https://app.pressconnect.com/auth/callback'),
  };

  /// Get the backend base URL for the current environment
  static String get backendUrl {
    return _backendUrls[_currentEnvironment] ?? _backendUrls[_development]!;
  }

  /// Get the OAuth redirect URI for the current environment
  static String get oauthRedirectUri {
    return _redirectUris[_currentEnvironment] ?? _redirectUris[_development]!;
  }

  /// Get the current environment
  static String get environment => _currentEnvironment;

  /// Check if running in development mode
  static bool get isDevelopment => _currentEnvironment == _development;

  /// Check if running in production mode
  static bool get isProduction => _currentEnvironment == _production;

  /// API endpoints - constructed from base URL
  static String get authRegisterUrl => '$backendUrl/api/auth/register';
  static String get authLoginUrl => '$backendUrl/api/auth/login';
  static String get authYoutubeUrl => '$backendUrl/api/auth/youtube';
  static String get streamCreateUrl => '$backendUrl/api/create-stream';
  static String get streamEndUrl => '$backendUrl/api/end-stream';
  static String get streamsUrl => '$backendUrl/api/streams';
  static String get healthUrl => '$backendUrl/health';
  static String get authOauthStoreUrl => '$backendUrl/api/auth/oauth/store';
  
  /// Dynamic stream endpoint
  static String streamStartUrl(String streamKey) => '$backendUrl/api/streams/$streamKey/start';

  /// Debug information
  static Map<String, dynamic> get debugInfo => {
    'environment': environment,
    'backendUrl': backendUrl,
    'oauthRedirectUri': oauthRedirectUri,
    'isDevelopment': isDevelopment,
    'isProduction': isProduction,
  };
}