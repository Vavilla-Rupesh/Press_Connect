# Configuration System Guide

This document explains how to configure backend URLs and environment variables for both the Flutter frontend and Node.js backend.

## Flutter Frontend Configuration

### AppConfig Service
The Flutter app uses a centralized configuration service located at `lib/config/app_config.dart`. This service manages all backend URLs and environment-specific settings.

### Supported Environments
- **Development** (default): Uses localhost URLs
- **Production**: Uses production URLs from build-time environment variables

### Build Configuration

#### Development (Default)
```bash
# Build for development (uses localhost URLs)
flutter build apk
```

#### Production
```bash
# Build for production with custom backend URL
flutter build apk --dart-define=ENVIRONMENT=production --dart-define=BACKEND_URL=https://api.pressconnect.com --dart-define=OAUTH_REDIRECT_URI=https://app.pressconnect.com/auth/callback
```

### Environment Variables Support
The Flutter app supports these build-time environment variables:

| Variable | Description | Default (Development) | Default (Production) |
|----------|-------------|----------------------|---------------------|
| `ENVIRONMENT` | Environment type | `development` | `production` |
| `BACKEND_URL` | Backend API base URL | `http://localhost:3000` | `https://api.pressconnect.com` |
| `OAUTH_REDIRECT_URI` | OAuth redirect URI | `http://localhost:8080/auth/callback` | `https://app.pressconnect.com/auth/callback` |

### Available Configuration Properties
```dart
import '../config/app_config.dart';

// Environment info
AppConfig.environment          // Current environment
AppConfig.isDevelopment       // true if development
AppConfig.isProduction        // true if production

// URLs
AppConfig.backendUrl          // Backend base URL
AppConfig.oauthRedirectUri    // OAuth redirect URI

// API Endpoints
AppConfig.authRegisterUrl     // /api/auth/register
AppConfig.authLoginUrl        // /api/auth/login
AppConfig.streamCreateUrl     // /api/create-stream
AppConfig.streamEndUrl        // /api/end-stream
AppConfig.streamsUrl          // /api/streams
AppConfig.healthUrl           // /health
AppConfig.authOauthStoreUrl   // /api/auth/oauth/store

// Dynamic endpoints
AppConfig.streamStartUrl(streamKey)  // /api/streams/{streamKey}/start

// Debug info
AppConfig.debugInfo           // Map with all config values
```

### Usage in Code
Replace hardcoded URLs with AppConfig references:

```dart
// OLD - Hardcoded
final response = await http.post(
  Uri.parse('http://localhost:3000/api/auth/login'),
  // ...
);

// NEW - Using AppConfig
final response = await http.post(
  Uri.parse(AppConfig.authLoginUrl),
  // ...
);
```

## Backend Configuration

### Environment Variables
The backend uses environment variables through `.env` files. Copy `.env.example` to `.env` and configure:

```bash
cp backend/.env.example backend/.env
```

### Environment Variables Reference

#### YouTube API Configuration
```bash
YOUTUBE_API_KEY=your_youtube_api_key_here
YOUTUBE_CLIENT_ID=your_youtube_client_id_here
YOUTUBE_CLIENT_SECRET=your_youtube_client_secret_here
YOUTUBE_REDIRECT_URI=http://localhost:8080/auth/callback
```

#### Server Configuration
```bash
PORT=3000
NODE_ENV=development
```

#### Security Configuration
```bash
JWT_SECRET=your_jwt_secret_here
SESSION_SECRET=your_session_secret_here
```

#### Database Configuration
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=press_connect_dev
DB_USER=press_connect_user
DB_PASSWORD=your_database_password
```

#### CORS Configuration
```bash
# Allowed origins for CORS (comma separated)
CORS_ORIGINS=http://localhost:8080,http://localhost:3000
```

#### Frontend Configuration
```bash
FRONTEND_URL=http://localhost:8080
```

### Production Configuration
For production, update environment variables:

```bash
NODE_ENV=production
YOUTUBE_REDIRECT_URI=https://app.pressconnect.com/auth/callback
FRONTEND_URL=https://app.pressconnect.com
CORS_ORIGINS=https://app.pressconnect.com
LOG_LEVEL=warn
```

### Usage in Backend Code
Environment variables are accessed via `process.env`:

```javascript
// Server port
const PORT = process.env.PORT || 3000;

// YouTube API configuration
const youtube = google.youtube({
  version: 'v3',
  auth: process.env.YOUTUBE_API_KEY
});

// OAuth2 client
const oauth2Client = new google.auth.OAuth2(
  process.env.YOUTUBE_CLIENT_ID,
  process.env.YOUTUBE_CLIENT_SECRET,
  process.env.YOUTUBE_REDIRECT_URI
);
```

## Deployment Examples

### Local Development
1. Backend:
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your YouTube API credentials
   npm install
   npm start
   ```

2. Flutter:
   ```bash
   flutter run
   # Uses development configuration automatically
   ```

### Production Deployment
1. Backend:
   ```bash
   # Set production environment variables
   export NODE_ENV=production
   export YOUTUBE_REDIRECT_URI=https://app.pressconnect.com/auth/callback
   # ... other production variables
   npm start
   ```

2. Flutter:
   ```bash
   flutter build apk --dart-define=ENVIRONMENT=production --dart-define=BACKEND_URL=https://api.pressconnect.com
   ```

## Migration from Hardcoded URLs

This configuration system replaces hardcoded URLs in these files:
- `lib/screens/login_screen.dart`
- `lib/services/youtube_auth_service.dart`
- `lib/services/streaming_service.dart`

All URL references now use the centralized AppConfig service for better maintainability and environment-specific configuration.