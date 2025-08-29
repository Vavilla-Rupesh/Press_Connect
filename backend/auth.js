const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

class AuthService {
  constructor(database) {
    this.db = database;
    this.jwtSecret = process.env.JWT_SECRET || 'fallback_secret_change_in_production';
  }

  async hashPassword(password) {
    const saltRounds = 12;
    return await bcrypt.hash(password, saltRounds);
  }

  async verifyPassword(password, hash) {
    return await bcrypt.compare(password, hash);
  }

  generateJWT(userId, username, email) {
    return jwt.sign(
      { 
        userId, 
        username, 
        email,
        iat: Math.floor(Date.now() / 1000)
      },
      this.jwtSecret,
      { expiresIn: '24h' }
    );
  }

  verifyJWT(token) {
    try {
      return jwt.verify(token, this.jwtSecret);
    } catch (err) {
      return null;
    }
  }

  async registerUser(username, email, password) {
    // Validate input
    if (!username || !email || !password) {
      throw new Error('Username, email, and password are required');
    }

    if (password.length < 6) {
      throw new Error('Password must be at least 6 characters long');
    }

    // Check if user already exists
    const existingUserByUsername = await this.db.getUserByUsername(username);
    if (existingUserByUsername) {
      throw new Error('Username already exists');
    }

    const existingUserByEmail = await this.db.getUserByEmail(email);
    if (existingUserByEmail) {
      throw new Error('Email already exists');
    }

    // Hash password and create user
    const passwordHash = await this.hashPassword(password);
    const user = await this.db.createUser(username, email, passwordHash);
    
    // Generate JWT token
    const token = this.generateJWT(user.id, user.username, user.email);
    
    return {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        created_at: user.created_at
      },
      token
    };
  }

  async authenticateUser(username, password) {
    // Find user by username or email
    let user = await this.db.getUserByUsername(username);
    if (!user) {
      user = await this.db.getUserByEmail(username);
    }

    if (!user) {
      throw new Error('Invalid credentials');
    }

    // Verify password
    const isValidPassword = await this.verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      throw new Error('Invalid credentials');
    }

    // Generate JWT token
    const token = this.generateJWT(user.id, user.username, user.email);
    
    return {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        created_at: user.created_at
      },
      token
    };
  }

  // Middleware to verify JWT token
  authenticateToken(req, res, next) {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ error: 'Access token required' });
    }

    const decoded = this.verifyJWT(token);
    if (!decoded) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }

    req.user = decoded;
    next();
  }

  // Store OAuth token for a user
  async storeOAuthToken(userId, provider, accessToken, refreshToken, expiresIn, scope) {
    const expiresAt = expiresIn ? new Date(Date.now() + (expiresIn * 1000)) : null;
    return await this.db.storeOAuthToken(userId, provider, accessToken, refreshToken, expiresAt, scope);
  }

  // Get OAuth token for a user
  async getOAuthToken(userId, provider) {
    return await this.db.getOAuthToken(userId, provider);
  }

  // Validate OAuth token (check if it's expired)
  isOAuthTokenValid(tokenData) {
    if (!tokenData) return false;
    if (!tokenData.expires_at) return true; // No expiry set
    return new Date() < new Date(tokenData.expires_at);
  }
}

module.exports = AuthService;