# Press Connect - Live Streaming Mobile App

A Flutter mobile application for live streaming to YouTube with watermark overlay functionality.

## Features

- **Dual Login System**: App login (admin/1234) + YouTube OAuth2
- **Live Streaming**: Direct RTMP streaming to YouTube
- **Watermark Overlay**: Customizable transparency overlay
- **Recording & Snapshots**: Local recording and snapshot capture
- **Multiple Streams**: Support for separate broadcast keys

## Setup Instructions

### Prerequisites

1. Flutter SDK 3.0+
2. Node.js 16+
3. YouTube Data API v3 credentials

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Copy environment file:
   ```bash
   cp .env.example .env
   ```

4. Update `.env` with your YouTube API credentials:
   ```
   YOUTUBE_API_KEY=your_api_key
   YOUTUBE_CLIENT_ID=your_client_id
   YOUTUBE_CLIENT_SECRET=your_client_secret
   ```

5. Start the backend server:
   ```bash
   npm start
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
- `flutter_rtmp_publisher` - RTMP streaming
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

The app uses `flutter_rtmp_publisher` for direct RTMP streaming to YouTube. Each stream session creates a unique broadcast and stream key to prevent conflicts.

## Security Notes

- Store API credentials securely
- Use HTTPS in production
- Implement proper token refresh logic
- Validate all API inputs

## License

MIT License - see LICENSE file for details.