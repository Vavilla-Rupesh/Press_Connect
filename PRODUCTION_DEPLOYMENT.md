# Production Deployment Guide

This guide covers deploying Press Connect to production environments.

## Environment Setup

### 1. Database Configuration

#### PostgreSQL Production Setup

```bash
# Install PostgreSQL on production server
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# Create production database
sudo -u postgres createdb press_connect_prod
sudo -u postgres createuser --interactive press_connect_prod_user

# Set secure password
sudo -u postgres psql
ALTER USER press_connect_prod_user WITH ENCRYPTED PASSWORD 'very_secure_production_password';
GRANT ALL PRIVILEGES ON DATABASE press_connect_prod TO press_connect_prod_user;
```

#### Connection Pooling (Recommended)

For production, consider using PgBouncer for connection pooling:

```bash
sudo apt-get install pgbouncer
```

Configure `/etc/pgbouncer/pgbouncer.ini`:
```ini
[databases]
press_connect_prod = host=localhost port=5432 dbname=press_connect_prod

[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 100
default_pool_size = 4
```

### 2. Backend Deployment

#### Using PM2 (Recommended)

```bash
# Install PM2 globally
npm install -g pm2

# Create ecosystem file
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'press-connect-backend',
    script: 'server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
EOF

# Start with PM2
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

#### Using Docker

```dockerfile
# Dockerfile
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

```bash
# Build and run
docker build -t press-connect-backend .
docker run -d --name press-connect -p 3000:3000 --env-file .env press-connect-backend
```

### 3. Reverse Proxy (Nginx)

Configure Nginx for SSL termination and load balancing:

```nginx
# /etc/nginx/sites-available/press-connect
server {
    listen 80;
    server_name api.pressconnect.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.pressconnect.com;

    ssl_certificate /path/to/ssl/cert.pem;
    ssl_certificate_key /path/to/ssl/private.key;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
        access_log off;
    }

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

### 4. Environment Variables

Create production `.env` file:

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=press_connect_prod
DB_USER=press_connect_prod_user
DB_PASSWORD=very_secure_production_password

# YouTube API
YOUTUBE_API_KEY=your_production_api_key
YOUTUBE_CLIENT_ID=your_production_client_id
YOUTUBE_CLIENT_SECRET=your_production_client_secret
YOUTUBE_REDIRECT_URI=https://app.pressconnect.com/auth/callback

# Server
PORT=3000
NODE_ENV=production

# Security - Generate with: openssl rand -base64 32
JWT_SECRET=your_super_secure_jwt_secret_here
SESSION_SECRET=your_super_secure_session_secret_here

# Logging
LOG_LEVEL=warn
```

### 5. Security Considerations

#### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

#### Database Security

```sql
-- Remove default postgres user if not needed
-- Restrict database access
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO press_connect_prod_user;

-- Enable row-level security for sensitive tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE oauth_tokens ENABLE ROW LEVEL SECURITY;
```

#### Application Security

1. **Environment Variables**: Never commit `.env` files
2. **API Rate Limiting**: Implement rate limiting for API endpoints
3. **Input Validation**: Validate all user inputs
4. **SQL Injection**: Use parameterized queries (already implemented)
5. **XSS Protection**: Sanitize outputs
6. **CSRF Protection**: Implement CSRF tokens for web interface

### 6. Monitoring and Logging

#### Application Monitoring

```bash
# Install monitoring tools
npm install -g clinic

# Monitor with PM2
pm2 monitor

# Application logs
pm2 logs press-connect-backend
```

#### Database Monitoring

```sql
-- Enable logging in PostgreSQL
-- Edit postgresql.conf:
log_statement = 'all'
log_duration = on
log_min_duration_statement = 1000  -- Log queries taking >1s
```

#### Health Checks

Create monitoring script:

```bash
#!/bin/bash
# health_check.sh

API_URL="https://api.pressconnect.com/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")

if [ "$RESPONSE" != "200" ]; then
    echo "API health check failed: $RESPONSE"
    # Send alert (email, Slack, etc.)
    exit 1
fi

echo "API health check passed"
```

### 7. Backup Strategy

#### Database Backups

```bash
# Create backup script
cat > /usr/local/bin/backup_press_connect.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/var/backups/press_connect"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/press_connect_$DATE.sql"

mkdir -p "$BACKUP_DIR"

pg_dump -h localhost -U press_connect_prod_user -d press_connect_prod > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
EOF

chmod +x /usr/local/bin/backup_press_connect.sh

# Schedule daily backups
echo "0 2 * * * /usr/local/bin/backup_press_connect.sh" | crontab -
```

### 8. Scaling Considerations

#### Horizontal Scaling

1. **Load Balancer**: Use Nginx or cloud load balancer
2. **Database Connection Pooling**: PgBouncer or PgPool
3. **Session Storage**: Redis for session management
4. **File Storage**: Cloud storage for recordings/snapshots

#### Vertical Scaling

1. **CPU**: Monitor and increase based on load
2. **Memory**: Ensure adequate RAM for Node.js and PostgreSQL
3. **Storage**: SSD for database, adequate space for recordings

### 9. Deployment Checklist

- [ ] PostgreSQL production database configured
- [ ] Environment variables set securely
- [ ] SSL certificates installed
- [ ] Nginx reverse proxy configured
- [ ] Firewall rules applied
- [ ] Backup strategy implemented
- [ ] Monitoring and logging configured
- [ ] Health checks implemented
- [ ] Security hardening applied
- [ ] Performance testing completed
- [ ] Documentation updated

### 10. Mobile App Distribution

#### Android (Google Play Store)

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Sign APK with production key
3. Upload to Google Play Console
4. Update API URLs to production endpoints

#### iOS (App Store)

1. Build release IPA:
   ```bash
   flutter build ios --release
   ```

2. Archive and upload via Xcode
3. Submit for App Store review
4. Update API URLs to production endpoints

Remember to test thoroughly in a staging environment before deploying to production!