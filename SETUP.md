# Press Connect - Setup Guide

## Quick Start

### 1. Backend Setup (Node.js)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Edit .env with your YouTube API credentials
# You'll need:
# - YouTube Data API v3 key
# - OAuth 2.0 Client ID and Secret

# Start the server
npm start
```

The backend will be available at `http://localhost:3000`

### 2. Mobile App Setup (Flutter)

```bash
# Install Flutter dependencies
flutter pub get

# Run on connected device/simulator
flutter run
```

## YouTube API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable YouTube Data API v3
4. Create OAuth 2.0 credentials:
   - Application type: Web application
   - Authorized redirect URIs: `http://localhost:8080/auth/callback`
5. Copy the Client ID and Client Secret to your `.env` file

## Testing the App

1. **Login**: Use `admin` / `1234`
2. **YouTube Auth**: The app will simulate OAuth flow
3. **Streaming**: Camera preview with watermark overlay
4. **Controls**: Adjust watermark transparency, take snapshots, record

## Architecture Overview

### Mobile App (Flutter)
- **Login Screen**: Hardcoded authentication
- **YouTube Auth Screen**: OAuth2 integration
- **Streaming Screen**: Camera + RTMP + Watermark
- **Services**: Authentication, Streaming, API communication
- **Widgets**: Reusable components for watermark and controls

### Backend (Node.js)
- **Express Server**: RESTful API
- **YouTube Integration**: googleapis library
- **Endpoints**:
  - `POST /api/create-stream`: Create broadcast and stream
  - `POST /api/end-stream`: End active stream
  - `GET /api/streams`: List active streams
  - `GET /health`: Health check

### Key Features Implemented

✅ **Dual Login System**
- App login with hardcoded credentials
- YouTube OAuth2 for streaming access

✅ **Live Streaming**
- Camera preview with real-time display
- RTMP streaming setup (ready for flutter_rtmp_publisher)
- YouTube API integration for broadcast creation

✅ **Watermark Overlay**
- Full-screen centered watermark
- Adjustable transparency with slider
- Multiple overlay elements for comprehensive coverage

✅ **Recording & Snapshots**
- Local recording capability
- Snapshot capture during streaming
- Watermark included in all captures

✅ **Multiple Streams Support**
- Unique broadcast + stream key per session
- No stream merging between devices
- Backend manages separate streams

## Notes

- The RTMP streaming uses placeholder implementation
- In production, integrate `flutter_rtmp_publisher` package
- OAuth2 flow is simplified for demo purposes
- Add proper error handling and token refresh in production
- Store sensitive credentials securely