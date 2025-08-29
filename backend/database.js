const { Pool } = require('pg');

class Database {
  constructor() {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'press_connect',
      user: process.env.DB_USER || 'press_connect_user',
      password: process.env.DB_PASSWORD || 'your_password_here',
      max: 20, // maximum number of connections in the pool
      idleTimeoutMillis: 30000, // close idle connections after 30 seconds
      connectionTimeoutMillis: 2000, // return an error after 2 seconds if connection could not be established
    });
    
    // Handle pool errors
    this.pool.on('error', (err) => {
      console.error('Unexpected error on idle client', err);
      process.exit(-1);
    });
  }

  async initialize() {
    try {
      // Test connection
      const client = await this.pool.connect();
      console.log('Database connected successfully');
      client.release();
      
      // Create tables if they don't exist
      await this.createTables();
    } catch (err) {
      console.error('Database connection failed:', err);
      throw err;
    }
  }

  async createTables() {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Users table for authentication
      await client.query(`
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          username VARCHAR(50) UNIQUE NOT NULL,
          email VARCHAR(255) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          is_active BOOLEAN DEFAULT true
        )
      `);

      // OAuth tokens table
      await client.query(`
        CREATE TABLE IF NOT EXISTS oauth_tokens (
          id SERIAL PRIMARY KEY,
          user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
          provider VARCHAR(50) NOT NULL,
          access_token TEXT NOT NULL,
          refresh_token TEXT,
          token_type VARCHAR(50) DEFAULT 'Bearer',
          expires_at TIMESTAMP,
          scope TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Streams table for active and historical streams
      await client.query(`
        CREATE TABLE IF NOT EXISTS streams (
          id SERIAL PRIMARY KEY,
          user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
          broadcast_id VARCHAR(255) UNIQUE NOT NULL,
          stream_id VARCHAR(255) UNIQUE NOT NULL,
          stream_key VARCHAR(255) UNIQUE NOT NULL,
          ingest_url TEXT NOT NULL,
          title VARCHAR(255) NOT NULL,
          description TEXT,
          privacy_status VARCHAR(50) DEFAULT 'public',
          status VARCHAR(50) DEFAULT 'created',
          started_at TIMESTAMP,
          ended_at TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Recordings table for recorded content
      await client.query(`
        CREATE TABLE IF NOT EXISTS recordings (
          id SERIAL PRIMARY KEY,
          stream_id INTEGER REFERENCES streams(id) ON DELETE CASCADE,
          user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
          filename VARCHAR(255) NOT NULL,
          file_path TEXT NOT NULL,
          file_size BIGINT,
          duration INTEGER,
          format VARCHAR(50),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Snapshots table for captured images
      await client.query(`
        CREATE TABLE IF NOT EXISTS snapshots (
          id SERIAL PRIMARY KEY,
          stream_id INTEGER REFERENCES streams(id) ON DELETE CASCADE,
          user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
          filename VARCHAR(255) NOT NULL,
          file_path TEXT NOT NULL,
          file_size BIGINT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Create indexes for better performance
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_streams_user_id ON streams(user_id);
        CREATE INDEX IF NOT EXISTS idx_streams_status ON streams(status);
        CREATE INDEX IF NOT EXISTS idx_recordings_stream_id ON recordings(stream_id);
        CREATE INDEX IF NOT EXISTS idx_snapshots_stream_id ON snapshots(stream_id);
        CREATE INDEX IF NOT EXISTS idx_oauth_tokens_user_id ON oauth_tokens(user_id);
      `);

      await client.query('COMMIT');
      console.log('Database tables created successfully');
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating tables:', err);
      throw err;
    } finally {
      client.release();
    }
  }

  // User management methods
  async createUser(username, email, passwordHash) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'INSERT INTO users (username, email, password_hash) VALUES ($1, $2, $3) RETURNING id, username, email, created_at',
        [username, email, passwordHash]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async getUserByUsername(username) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT * FROM users WHERE username = $1 AND is_active = true',
        [username]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async getUserByEmail(email) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT * FROM users WHERE email = $1 AND is_active = true',
        [email]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  // OAuth token methods
  async storeOAuthToken(userId, provider, accessToken, refreshToken, expiresAt, scope) {
    const client = await this.pool.connect();
    try {
      // Delete existing tokens for this user and provider
      await client.query(
        'DELETE FROM oauth_tokens WHERE user_id = $1 AND provider = $2',
        [userId, provider]
      );

      // Insert new token
      const result = await client.query(
        'INSERT INTO oauth_tokens (user_id, provider, access_token, refresh_token, expires_at, scope) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [userId, provider, accessToken, refreshToken, expiresAt, scope]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async getOAuthToken(userId, provider) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT * FROM oauth_tokens WHERE user_id = $1 AND provider = $2',
        [userId, provider]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  // Stream management methods
  async createStream(userId, broadcastId, streamId, streamKey, ingestUrl, title, description, privacyStatus) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'INSERT INTO streams (user_id, broadcast_id, stream_id, stream_key, ingest_url, title, description, privacy_status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
        [userId, broadcastId, streamId, streamKey, ingestUrl, title, description, privacyStatus]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async getStreamByKey(streamKey) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT * FROM streams WHERE stream_key = $1',
        [streamKey]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async updateStreamStatus(streamKey, status, startedAt = null, endedAt = null) {
    const client = await this.pool.connect();
    try {
      let query = 'UPDATE streams SET status = $1, updated_at = CURRENT_TIMESTAMP';
      let params = [status];
      let paramCount = 1;

      if (startedAt) {
        paramCount++;
        query += `, started_at = $${paramCount}`;
        params.push(startedAt);
      }

      if (endedAt) {
        paramCount++;
        query += `, ended_at = $${paramCount}`;
        params.push(endedAt);
      }

      paramCount++;
      query += ` WHERE stream_key = $${paramCount} RETURNING *`;
      params.push(streamKey);

      const result = await client.query(query, params);
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async getActiveStreams(userId = null) {
    const client = await this.pool.connect();
    try {
      let query = "SELECT * FROM streams WHERE status IN ('created', 'active', 'starting')";
      let params = [];

      if (userId) {
        query += ' AND user_id = $1';
        params.push(userId);
      }

      query += ' ORDER BY created_at DESC';

      const result = await client.query(query, params);
      return result.rows;
    } finally {
      client.release();
    }
  }

  async deleteStream(streamKey) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'DELETE FROM streams WHERE stream_key = $1 RETURNING *',
        [streamKey]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  // Recording methods
  async createRecording(streamId, userId, filename, filePath, fileSize, duration, format) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'INSERT INTO recordings (stream_id, user_id, filename, file_path, file_size, duration, format) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
        [streamId, userId, filename, filePath, fileSize, duration, format]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  // Snapshot methods
  async createSnapshot(streamId, userId, filename, filePath, fileSize) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'INSERT INTO snapshots (stream_id, user_id, filename, file_path, file_size) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [streamId, userId, filename, filePath, fileSize]
      );
      return result.rows[0];
    } finally {
      client.release();
    }
  }

  async close() {
    await this.pool.end();
  }
}

module.exports = Database;