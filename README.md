# Press Connect - Production-Ready Live Streaming App

A Flutter mobile application for live streaming to YouTube with PostgreSQL database backend, user authentication, and watermark overlay functionality.

## Features

- **User Authentication**: Registration and login with JWT tokens
- **YouTube OAuth2**: Secure OAuth2 integration with token management
- **Live Streaming**: Direct RTMP streaming to YouTube with real-time controls
- **Watermark Overlay**: Customizable transparency overlay with professional branding
- **Recording & Snapshots**: Local recording and snapshot capture during streaming
- **Stream Management**: Database-backed stream lifecycle management
- **Multi-User Support**: Individual user accounts with isolated streams
- **Production Ready**: PostgreSQL database, proper error handling, security

## Architecture

### Backend (Node.js + PostgreSQL)
- Express.js API server with JWT authentication
- PostgreSQL database with proper schema
- YouTube Data API v3 integration
- OAuth2 token management
- Stream lifecycle management
- User management and registration

### Frontend (Flutter)
- User registration and login screens
- YouTube OAuth2 authentication flow
- Real-time camera preview with watermark
- Stream configuration and management
- Recording and snapshot functionality

## Production Setup

### Prerequisites

1. **PostgreSQL 12+** - Database server
2. **Node.js 16+** - Backend runtime
3. **Flutter SDK 3.0+** - Mobile app framework
4. **YouTube Data API v3 credentials** - From Google Cloud Console

### Quick Setup (Linux/macOS)

Run the automated setup script:

```bash
./setup_postgresql.sh
```

This script will:
- Create PostgreSQL database and user
- Install backend dependencies
- Generate secure JWT secrets
- Create environment configuration
- Run database migrations

### Manual Setup

#### 1. Database Setup

```bash
# Install PostgreSQL (Ubuntu/Debian)
sudo apt-get install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE DATABASE press_connect;
CREATE USER press_connect_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE press_connect TO press_connect_user;
\q
```

#### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy and configure environment
cp .env.production .env
# Edit .env with your database credentials and YouTube API keys

# Run database migrations
npm run migrate

# Start the server
npm start
```

#### 3. YouTube API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable **YouTube Data API v3**
4. Create credentials:
   - **API Key** for general API access
   - **OAuth 2.0 Client ID** for user authentication
5. Update `backend/.env` with your credentials:
   ```
   YOUTUBE_API_KEY=your_api_key_here
   YOUTUBE_CLIENT_ID=your_client_id_here
   YOUTUBE_CLIENT_SECRET=your_client_secret_here
   ```

#### 4. Mobile App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Update YouTube credentials in lib/services/youtube_auth_service.dart
# Replace YOUR_YOUTUBE_CLIENT_ID and YOUR_YOUTUBE_CLIENT_SECRET

# Run the app
flutter run
```

### Mobile App Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Login**: Use credentials `admin` / `1234`
2. **YouTube Auth**: Connect your YouTube account
3. **Streaming**: Tap "Go Live" to start streaming
4. **Watermark**: Adjust transparency with the slider
5. **Recording**: Use recording button for local saves
6. **Snapshots**: Capture moments during live streams

## API Endpoints

- `POST /api/create-stream` - Create YouTube broadcast and stream
- `POST /api/end-stream` - End active stream
- `GET /api/streams` - List active streams
- `GET /health` - Health check

## Architecture

```
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/               # UI screens
│   ├── services/              # Business logic
│   ├── widgets/               # Reusable components
│   └── models/                # Data models
├── backend/                   # Node.js API server
├── android/                   # Android configuration
└── ios/                       # iOS configuration
```

## Dependencies

### Flutter
- `camera` - Camera access
- `rtmp_broadcaster` - RTMP streaming
- `http` - API communication
- `shared_preferences` - Local storage
- `oauth2` - Authentication

### Backend
- `express` - Web framework
- `googleapis` - YouTube API client
- `cors` - Cross-origin requests

## Configuration

### YouTube API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable YouTube Data API v3
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs

### RTMP Streaming

The app uses `rtmp_broadcaster` for direct RTMP streaming to YouTube. Each stream session creates a unique broadcast and stream key to prevent conflicts.

## Security Notes

- Store API credentials securely
- Use HTTPS in production
- Implement proper token refresh logic
- Validate all API inputs

## License

MIT License - see LICENSE file for details.