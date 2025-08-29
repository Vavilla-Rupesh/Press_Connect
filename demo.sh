#!/bin/bash

# Press Connect Demo Script
# Tests the backend API functionality

BASE_URL="http://localhost:3000"
TEST_TOKEN="demo_access_token_123"

echo "🚀 Press Connect API Demo"
echo "========================="

# Check if backend is running
echo "📡 Checking backend health..."
if curl -s "$BASE_URL/health" > /dev/null; then
    echo "✅ Backend is running"
    curl -s "$BASE_URL/health" | jq .
else
    echo "❌ Backend is not running. Start it with: cd backend && npm start"
    exit 1
fi

echo ""
echo "📺 Creating YouTube stream..."

# Create a new stream
STREAM_RESPONSE=$(curl -s -X POST "$BASE_URL/api/create-stream" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TEST_TOKEN" \
    -d '{
        "title": "Demo Stream from Press Connect",
        "description": "Test stream for demonstration",
        "privacyStatus": "unlisted"
    }')

echo "Stream created:"
echo "$STREAM_RESPONSE" | jq .

# Extract stream key for cleanup
STREAM_KEY=$(echo "$STREAM_RESPONSE" | jq -r '.streamKey')

echo ""
echo "📋 Listing active streams..."
curl -s "$BASE_URL/api/streams" | jq .

echo ""
echo "🔍 Getting stream details..."
curl -s "$BASE_URL/api/streams/$STREAM_KEY" | jq .

echo ""
echo "⏹️ Ending stream..."
curl -s -X POST "$BASE_URL/api/end-stream" \
    -H "Content-Type: application/json" \
    -d "{\"streamKey\": \"$STREAM_KEY\"}" | jq .

echo ""
echo "📋 Listing streams after cleanup..."
curl -s "$BASE_URL/api/streams" | jq .

echo ""
echo "✅ Demo completed successfully!"
echo ""
echo "Next steps:"
echo "1. Set up YouTube API credentials in backend/.env"
echo "2. Run 'flutter run' to test the mobile app"
echo "3. Use login credentials: admin / 1234"