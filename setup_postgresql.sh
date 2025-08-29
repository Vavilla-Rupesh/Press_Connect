#!/bin/bash

echo "Press Connect - PostgreSQL Setup Script"
echo "========================================"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL is not installed. Please install PostgreSQL first:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "  macOS: brew install postgresql"
    echo "  Windows: Download from https://www.postgresql.org/download/"
    exit 1
fi

echo "PostgreSQL is installed."

# Set default values
DB_NAME="press_connect"
DB_USER="press_connect_user"
DB_PASSWORD=""

# Get database password
read -s -p "Enter password for database user '$DB_USER': " DB_PASSWORD
echo

if [ -z "$DB_PASSWORD" ]; then
    echo "Password cannot be empty!"
    exit 1
fi

echo "Creating database and user..."

# Create database and user (run as postgres user)
sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF

if [ $? -eq 0 ]; then
    echo "Database and user created successfully!"
else
    echo "Error creating database and user. Please check your PostgreSQL installation."
    exit 1
fi

# Create .env file
echo "Creating .env file..."
cat > backend/.env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# YouTube API Configuration (REQUIRED - Get from Google Cloud Console)
YOUTUBE_API_KEY=your_youtube_api_key_here
YOUTUBE_CLIENT_ID=your_youtube_client_id_here
YOUTUBE_CLIENT_SECRET=your_youtube_client_secret_here
YOUTUBE_REDIRECT_URI=http://localhost:8080/auth/callback

# Server Configuration
PORT=3000
NODE_ENV=development

# Security (REQUIRED - Generate secure random strings)
JWT_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)

# Logging
LOG_LEVEL=info
EOF

echo "Environment file created at backend/.env"

# Install backend dependencies
echo "Installing backend dependencies..."
cd backend
npm install

if [ $? -eq 0 ]; then
    echo "Dependencies installed successfully!"
else
    echo "Error installing dependencies."
    exit 1
fi

# Run database migrations
echo "Running database migrations..."
npm run migrate

if [ $? -eq 0 ]; then
    echo "Database migrations completed successfully!"
else
    echo "Error running migrations."
    exit 1
fi

echo ""
echo "Setup completed successfully!"
echo ""
echo "IMPORTANT: Before running the app, you need to:"
echo "1. Get YouTube API credentials from Google Cloud Console:"
echo "   - Go to https://console.cloud.google.com/"
echo "   - Create a new project or select existing one"
echo "   - Enable YouTube Data API v3"
echo "   - Create credentials (API Key and OAuth 2.0 Client ID)"
echo "   - Update the backend/.env file with your credentials"
echo ""
echo "2. Start the backend server:"
echo "   cd backend && npm start"
echo ""
echo "3. Run the Flutter app:"
echo "   flutter run"
echo ""
echo "The database is ready and configured!"