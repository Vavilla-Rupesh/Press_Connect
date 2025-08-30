# Flutter Environment Configuration Examples

# Development build (default - uses localhost URLs)
flutter build apk

# Development build with explicit environment
flutter build apk --dart-define=ENVIRONMENT=development

# Production build with custom backend URL
flutter build apk \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BACKEND_URL=https://api.pressconnect.com \
  --dart-define=OAUTH_REDIRECT_URI=https://app.pressconnect.com/auth/callback

# Staging build example
flutter build apk \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BACKEND_URL=https://staging-api.pressconnect.com \
  --dart-define=OAUTH_REDIRECT_URI=https://staging.pressconnect.com/auth/callback

# Release build for production
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BACKEND_URL=https://api.pressconnect.com \
  --dart-define=OAUTH_REDIRECT_URI=https://app.pressconnect.com/auth/callback

# iOS builds
flutter build ios \
  --dart-define=ENVIRONMENT=production \
  --dart-define=BACKEND_URL=https://api.pressconnect.com \
  --dart-define=OAUTH_REDIRECT_URI=https://app.pressconnect.com/auth/callback

# For running in development with custom backend
flutter run \
  --dart-define=BACKEND_URL=http://192.168.1.100:3000 \
  --dart-define=OAUTH_REDIRECT_URI=http://192.168.1.100:8080/auth/callback