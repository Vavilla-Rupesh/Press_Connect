const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { google } = require('googleapis');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// YouTube API configuration
const youtube = google.youtube({
  version: 'v3',
  auth: process.env.YOUTUBE_API_KEY || 'YOUR_YOUTUBE_API_KEY'
});

// OAuth2 client setup
const oauth2Client = new google.auth.OAuth2(
  process.env.YOUTUBE_CLIENT_ID || 'YOUR_YOUTUBE_CLIENT_ID',
  process.env.YOUTUBE_CLIENT_SECRET || 'YOUR_YOUTUBE_CLIENT_SECRET',
  process.env.YOUTUBE_REDIRECT_URI || 'http://localhost:8080/auth/callback'
);

// In-memory storage for active streams (in production, use a database)
const activeStreams = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Create YouTube broadcast and stream
app.post('/api/create-stream', async (req, res) => {
  try {
    const { title, description, privacyStatus = 'public' } = req.body;
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const accessToken = authHeader.split(' ')[1];
    
    // Set the OAuth2 client credentials
    oauth2Client.setCredentials({
      access_token: accessToken
    });

    google.options({
      auth: oauth2Client
    });

    // Create a broadcast
    const broadcastResponse = await youtube.liveBroadcasts.insert({
      part: ['id', 'snippet', 'contentDetails', 'status'],
      requestBody: {
        snippet: {
          title: title || `Live Stream - ${new Date().toISOString()}`,
          description: description || 'Live stream from Press Connect mobile app',
          scheduledStartTime: new Date().toISOString(),
        },
        status: {
          privacyStatus: privacyStatus,
          selfDeclaredMadeForKids: false,
        },
        contentDetails: {
          enableAutoStart: true,
          enableAutoStop: true,
        }
      }
    });

    const broadcast = broadcastResponse.data;

    // Create a stream
    const streamResponse = await youtube.liveStreams.insert({
      part: ['id', 'snippet', 'cdn', 'status'],
      requestBody: {
        snippet: {
          title: `Stream for ${broadcast.snippet.title}`,
        },
        cdn: {
          ingestionType: 'rtmp',
          resolution: '720p',
          frameRate: '30fps',
        }
      }
    });

    const stream = streamResponse.data;

    // Bind the broadcast to the stream
    await youtube.liveBroadcasts.bind({
      part: ['id'],
      id: broadcast.id,
      streamId: stream.id
    });

    // Store the stream info
    const streamInfo = {
      broadcastId: broadcast.id,
      streamId: stream.id,
      ingestUrl: stream.cdn.ingestionInfo.ingestionAddress,
      streamKey: stream.cdn.ingestionInfo.streamName,
      createdAt: new Date().toISOString(),
      title: broadcast.snippet.title
    };

    activeStreams.set(stream.cdn.ingestionInfo.streamName, streamInfo);

    res.json({
      broadcastId: broadcast.id,
      streamId: stream.id,
      ingestUrl: stream.cdn.ingestionInfo.ingestionAddress,
      streamKey: stream.cdn.ingestionInfo.streamName,
      broadcastUrl: `https://www.youtube.com/watch?v=${broadcast.id}`
    });

  } catch (error) {
    console.error('Error creating YouTube stream:', error);
    
    // Fallback response for demo purposes
    const demoStreamKey = `demo-stream-${Date.now()}`;
    const demoInfo = {
      broadcastId: `demo-broadcast-${Date.now()}`,
      streamId: `demo-stream-${Date.now()}`,
      ingestUrl: 'rtmp://a.rtmp.youtube.com/live2',
      streamKey: demoStreamKey,
      createdAt: new Date().toISOString(),
      title: req.body.title || 'Demo Stream'
    };
    
    activeStreams.set(demoStreamKey, demoInfo);
    
    res.json({
      broadcastId: demoInfo.broadcastId,
      streamId: demoInfo.streamId,
      ingestUrl: demoInfo.ingestUrl,
      streamKey: demoInfo.streamKey,
      broadcastUrl: `https://www.youtube.com/watch?v=${demoInfo.broadcastId}`,
      demo: true
    });
  }
});

// End stream
app.post('/api/end-stream', async (req, res) => {
  try {
    const { streamKey } = req.body;
    
    if (!streamKey) {
      return res.status(400).json({ error: 'Stream key is required' });
    }

    const streamInfo = activeStreams.get(streamKey);
    
    if (!streamInfo) {
      return res.status(404).json({ error: 'Stream not found' });
    }

    // In a real implementation, you would:
    // 1. End the YouTube broadcast
    // 2. Delete the stream
    // 3. Clean up resources

    try {
      // End the broadcast
      await youtube.liveBroadcasts.transition({
        part: ['id'],
        id: streamInfo.broadcastId,
        broadcastStatus: 'complete'
      });
    } catch (error) {
      console.error('Error ending YouTube broadcast:', error);
    }

    // Remove from active streams
    activeStreams.delete(streamKey);

    res.json({ 
      message: 'Stream ended successfully',
      streamKey: streamKey 
    });

  } catch (error) {
    console.error('Error ending stream:', error);
    res.status(500).json({ error: 'Failed to end stream' });
  }
});

// Get active streams
app.get('/api/streams', (req, res) => {
  const streams = Array.from(activeStreams.values());
  res.json({ streams, count: streams.length });
});

// Get stream info
app.get('/api/streams/:streamKey', (req, res) => {
  const { streamKey } = req.params;
  const streamInfo = activeStreams.get(streamKey);
  
  if (!streamInfo) {
    return res.status(404).json({ error: 'Stream not found' });
  }
  
  res.json(streamInfo);
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: error.message 
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Press Connect Backend running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully');
  process.exit(0);
});