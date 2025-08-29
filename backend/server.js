const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const session = require('express-session');
const { google } = require('googleapis');
require('dotenv').config();

const Database = require('./database');
const AuthService = require('./auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize database and auth service
const database = new Database();
const authService = new AuthService(database);

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://your-domain.com'] 
    : ['http://localhost:8080', 'http://localhost:3000'],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(session({
  secret: process.env.SESSION_SECRET || 'fallback_session_secret',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: process.env.NODE_ENV === 'production',
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// YouTube API configuration
const youtube = google.youtube({
  version: 'v3',
  auth: process.env.YOUTUBE_API_KEY
});

// OAuth2 client setup
const oauth2Client = new google.auth.OAuth2(
  process.env.YOUTUBE_CLIENT_ID,
  process.env.YOUTUBE_CLIENT_SECRET,
  process.env.YOUTUBE_REDIRECT_URI
);

// Initialize database connection
async function initializeApp() {
  try {
    await database.initialize();
    console.log('Database initialized successfully');
  } catch (err) {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// User registration endpoint
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Username, email, and password are required' });
    }

    const result = await authService.registerUser(username, email, password);
    res.status(201).json(result);
  } catch (error) {
    console.error('Registration error:', error);
    res.status(400).json({ error: error.message });
  }
});

// User login endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }

    const result = await authService.authenticateUser(username, password);
    res.json(result);
  } catch (error) {
    console.error('Login error:', error);
    res.status(401).json({ error: error.message });
  }
});

// OAuth token storage endpoint
app.post('/api/auth/oauth/store', authService.authenticateToken.bind(authService), async (req, res) => {
  try {
    const { provider, accessToken, refreshToken, expiresIn, scope } = req.body;
    
    if (!provider || !accessToken) {
      return res.status(400).json({ error: 'Provider and access token are required' });
    }

    const tokenData = await authService.storeOAuthToken(
      req.user.userId, 
      provider, 
      accessToken, 
      refreshToken, 
      expiresIn, 
      scope
    );
    
    res.json({ message: 'OAuth token stored successfully', tokenId: tokenData.id });
  } catch (error) {
    console.error('OAuth token storage error:', error);
    res.status(500).json({ error: 'Failed to store OAuth token' });
  }
});

// Create YouTube broadcast and stream
app.post('/api/create-stream', authService.authenticateToken.bind(authService), async (req, res) => {
  try {
    const { title, description, privacyStatus = 'public' } = req.body;
    const userId = req.user.userId;
    
    // Get user's YouTube OAuth token
    const oauthToken = await authService.getOAuthToken(userId, 'youtube');
    if (!oauthToken || !authService.isOAuthTokenValid(oauthToken)) {
      return res.status(401).json({ 
        error: 'Valid YouTube OAuth token required. Please re-authenticate with YouTube.' 
      });
    }

    // Set the OAuth2 client credentials
    oauth2Client.setCredentials({
      access_token: oauthToken.access_token,
      refresh_token: oauthToken.refresh_token
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

    // Store the stream info in database
    const streamRecord = await database.createStream(
      userId,
      broadcast.id,
      stream.id,
      stream.cdn.ingestionInfo.streamName,
      stream.cdn.ingestionInfo.ingestionAddress,
      broadcast.snippet.title,
      description,
      privacyStatus
    );

    res.json({
      broadcastId: broadcast.id,
      streamId: stream.id,
      ingestUrl: stream.cdn.ingestionInfo.ingestionAddress,
      streamKey: stream.cdn.ingestionInfo.streamName,
      broadcastUrl: `https://www.youtube.com/watch?v=${broadcast.id}`,
      streamDbId: streamRecord.id
    });

  } catch (error) {
    console.error('Error creating YouTube stream:', error);
    
    // Check if it's an authentication error
    if (error.code === 401 || error.code === 403) {
      return res.status(401).json({ 
        error: 'YouTube authentication failed. Please re-authenticate with YouTube.',
        requiresReauth: true
      });
    }
    
    // Check if it's a quota error
    if (error.code === 403 && error.message.includes('quota')) {
      return res.status(429).json({ 
        error: 'YouTube API quota exceeded. Please try again later.' 
      });
    }
    
    res.status(500).json({ 
      error: 'Failed to create YouTube stream',
      message: error.message 
    });
  }
});

// End stream
app.post('/api/end-stream', authService.authenticateToken.bind(authService), async (req, res) => {
  try {
    const { streamKey } = req.body;
    const userId = req.user.userId;
    
    if (!streamKey) {
      return res.status(400).json({ error: 'Stream key is required' });
    }

    // Get stream info from database
    const streamInfo = await database.getStreamByKey(streamKey);
    
    if (!streamInfo) {
      return res.status(404).json({ error: 'Stream not found' });
    }

    // Verify stream belongs to user
    if (streamInfo.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Get user's YouTube OAuth token
    const oauthToken = await authService.getOAuthToken(userId, 'youtube');
    if (oauthToken && authService.isOAuthTokenValid(oauthToken)) {
      // Set OAuth credentials
      oauth2Client.setCredentials({
        access_token: oauthToken.access_token,
        refresh_token: oauthToken.refresh_token
      });

      google.options({
        auth: oauth2Client
      });

      try {
        // End the broadcast
        await youtube.liveBroadcasts.transition({
          part: ['id'],
          id: streamInfo.broadcast_id,
          broadcastStatus: 'complete'
        });
      } catch (error) {
        console.error('Error ending YouTube broadcast:', error);
        // Continue even if YouTube API call fails
      }
    }

    // Update stream status in database
    await database.updateStreamStatus(streamKey, 'ended', null, new Date());

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
app.get('/api/streams', authService.authenticateToken.bind(authService), async (req, res) => {
  try {
    const userId = req.user.userId;
    const streams = await database.getActiveStreams(userId);
    res.json({ streams, count: streams.length });
  } catch (error) {
    console.error('Error fetching streams:', error);
    res.status(500).json({ error: 'Failed to fetch streams' });
  }
});

// Get stream info
app.get('/api/streams/:streamKey', authService.authenticateToken.bind(authService), async (req, res) => {
  try {
    const { streamKey } = req.params;
    const userId = req.user.userId;
    
    const streamInfo = await database.getStreamByKey(streamKey);
    
    if (!streamInfo) {
      return res.status(404).json({ error: 'Stream not found' });
    }

    // Verify stream belongs to user
    if (streamInfo.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    res.json(streamInfo);
  } catch (error) {
    console.error('Error fetching stream info:', error);
    res.status(500).json({ error: 'Failed to fetch stream info' });
  }
});

// Update stream status (start streaming)
app.patch('/api/streams/:streamKey/start', authService.authenticateToken.bind(authService), async (req, res) => {
  try {
    const { streamKey } = req.params;
    const userId = req.user.userId;
    
    const streamInfo = await database.getStreamByKey(streamKey);
    
    if (!streamInfo) {
      return res.status(404).json({ error: 'Stream not found' });
    }

    // Verify stream belongs to user
    if (streamInfo.user_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Update stream status to active
    const updatedStream = await database.updateStreamStatus(streamKey, 'active', new Date());
    
    res.json({ 
      message: 'Stream started successfully',
      stream: updatedStream 
    });
  } catch (error) {
    console.error('Error starting stream:', error);
    res.status(500).json({ error: 'Failed to start stream' });
  }
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
async function startServer() {
  await initializeApp();
  
  app.listen(PORT, () => {
    console.log(`Press Connect Backend running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });
}

// Graceful shutdown
async function gracefulShutdown() {
  console.log('Shutting down gracefully...');
  try {
    await database.close();
    console.log('Database connections closed');
  } catch (err) {
    console.error('Error closing database:', err);
  }
  process.exit(0);
}

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// Start the application
startServer().catch(err => {
  console.error('Failed to start server:', err);
  process.exit(1);
});