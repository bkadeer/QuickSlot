# QuickSlot Setup Guide
## Complete Architecture with Offline-First Mobile App

This guide will help you set up the complete QuickSlot system with:
- **Flutter Mobile App** with SQLite offline caching
- **FastAPI Backend** with PostgreSQL database
- **Automatic sync** between offline cache and server

---

## Architecture Overview

### Mobile App (Flutter)
- **SQLite** for local caching (shops, categories, user data, reservations)
- **Secure Storage** for authentication tokens
- **Biometric Authentication** for quick login
- **Offline-first** with automatic sync when online

### Backend (FastAPI + PostgreSQL)
- **PostgreSQL** as authoritative database
- **Async SQLAlchemy** for high performance
- **JWT Authentication** with token refresh
- **Sync endpoints** for mobile cache updates

---

## Prerequisites

### Backend Requirements
- Python 3.9+
- PostgreSQL 14+
- pip or poetry

### Mobile Requirements
- Flutter SDK 3.9+
- Dart 3.0+
- Android Studio / Xcode
- Android SDK 21+ / iOS 12+

---

## Backend Setup

### 1. Install PostgreSQL

**macOS (Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download from https://www.postgresql.org/download/windows/

### 2. Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database and user
CREATE DATABASE quickslot_db;
CREATE USER quickslot WITH PASSWORD 'quickslot123';
GRANT ALL PRIVILEGES ON DATABASE quickslot_db TO quickslot;
\q
```

### 3. Configure Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env << 'EOF'
# Database
DATABASE_URL=postgresql+asyncpg://quickslot:quickslot123@localhost:5432/quickslot_db

# JWT Settings
SECRET_KEY=your-secret-key-change-this-in-production-use-openssl-rand-hex-32
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Redis (optional)
REDIS_URL=redis://localhost:6379/0

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
EMAIL_FROM=noreply@quickslot.com

# Environment
ENVIRONMENT=development
EOF

# Generate a secure secret key
python -c "import secrets; print(f'SECRET_KEY={secrets.token_hex(32)}')"
# Copy the output and update SECRET_KEY in .env
```

### 4. Initialize Database

```bash
# Create admin user
python create_admin.py

# Default credentials:
# Email: admin@quickslot.com
# Password: admin123
```

### 5. Run Backend Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Server will be available at:
# - API: http://localhost:8000
# - Swagger Docs: http://localhost:8000/docs
# - ReDoc: http://localhost:8000/redoc
```

---

## Mobile App Setup

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Configure API Endpoint

The app is configured to connect to `http://127.0.0.1:8000/api/v1` by default.

For custom configuration:
```bash
# Run with custom API URL
flutter run --dart-define=API_BASE_URL=http://your-server:8000/api/v1
```

### 3. Run on Android

```bash
# Start Android emulator or connect device
flutter devices

# Run app
flutter run
```

### 4. Run on iOS

```bash
# Open iOS simulator
open -a Simulator

# Run app
flutter run
```

---

## Database Architecture

### Backend (PostgreSQL)

**Tables:**
- `users` - User accounts with authentication
- `shops` - Venues/shops for reservations (to be implemented)
- `categories` - Shop categories (to be implemented)
- `reservations` - User bookings (to be implemented)

### Mobile (SQLite)

**Tables:**
- `cached_users` - Cached user profile
- `cached_shops` - Offline shop browsing
- `cached_categories` - Category filters
- `cached_reservations` - User's reservations
- `sync_queue` - Pending offline operations

---

## Sync Architecture

### How Sync Works

1. **On Login:**
   - User authenticates with backend
   - Tokens stored in secure storage
   - User profile cached in SQLite
   - Initial data sync triggered

2. **Offline Mode:**
   - App reads from SQLite cache
   - User actions queued in `sync_queue`
   - UI shows offline indicator

3. **Coming Online:**
   - Connectivity detected automatically
   - Pending operations synced to server
   - Latest data fetched and cached
   - Conflicts resolved (server wins)

4. **Background Sync:**
   - Periodic sync every 24 hours
   - Manual refresh available
   - Push notifications for updates (future)

### Sync Endpoints

```
GET  /api/v1/sync/shops          - Fetch shops for caching
GET  /api/v1/sync/categories     - Fetch categories
POST /api/v1/sync/batch          - Batch sync operations
GET  /api/v1/sync/status         - Server status & timestamp
POST /api/v1/sync/check-updates  - Check for updates
```

---

## Testing the System

### 1. Test Backend

```bash
# Health check
curl http://localhost:8000/health

# Register user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Sync shops
curl http://localhost:8000/api/v1/sync/shops
```

### 2. Test Mobile App

1. **Launch app** - Should show login screen
2. **Register/Login** - Creates account and caches data
3. **Enable biometrics** - Quick login on next launch
4. **Browse shops** - Data loaded from cache
5. **Go offline** - Toggle airplane mode
6. **Make reservation** - Queued for sync
7. **Go online** - Auto-sync triggered
8. **Check sync status** - View cache stats in settings

---

## Production Deployment

### Backend

1. **Update environment variables:**
   ```bash
   ENVIRONMENT=production
   SECRET_KEY=<strong-random-key>
   DATABASE_URL=postgresql+asyncpg://user:pass@prod-db:5432/quickslot
   ALLOWED_ORIGINS=https://yourdomain.com
   ```

2. **Use production WSGI server:**
   ```bash
   gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
   ```

3. **Set up reverse proxy (Nginx):**
   ```nginx
   location /api {
       proxy_pass http://localhost:8000;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
   }
   ```

4. **Enable HTTPS** with Let's Encrypt

### Mobile App

1. **Update API endpoint:**
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
   flutter build ios --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
   ```

2. **Configure app signing:**
   - Android: Update `android/app/build.gradle`
   - iOS: Configure in Xcode

3. **Build release:**
   ```bash
   # Android
   flutter build apk --release
   flutter build appbundle --release

   # iOS
   flutter build ios --release
   ```

---

## Troubleshooting

### Backend Issues

**Database connection error:**
```bash
# Check PostgreSQL is running
pg_isready

# Test connection
psql -U quickslot -d quickslot_db -h localhost

# Check logs
tail -f /usr/local/var/log/postgresql@15.log
```

**Import errors:**
```bash
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Mobile Issues

**SQLite errors:**
```bash
# Clear app data
flutter clean
flutter pub get
```

**Sync not working:**
- Check network connectivity
- Verify API endpoint is reachable
- Check backend logs for errors
- Clear cache and re-login

**Biometric not working:**
- Ensure device has biometric hardware
- Check app permissions
- Re-enable in app settings

---

## Security Best Practices

### Backend
- ✅ Use strong SECRET_KEY (32+ random bytes)
- ✅ Enable HTTPS in production
- ✅ Implement rate limiting
- ✅ Regular security updates
- ✅ Database backups
- ✅ Monitor for suspicious activity

### Mobile
- ✅ Tokens stored in secure storage
- ✅ Biometric authentication
- ✅ Certificate pinning (production)
- ✅ Obfuscate code in release builds
- ✅ Regular dependency updates

---

## Performance Optimization

### Backend
- Connection pooling (configured)
- Database indexes (add as needed)
- Redis caching (optional)
- Query optimization
- Load balancing (production)

### Mobile
- SQLite indexes (configured)
- Image caching
- Lazy loading
- Pagination
- Background sync

---

## Monitoring

### Backend Metrics
- Response times
- Error rates
- Database connections
- API usage

### Mobile Metrics
- Cache hit rate
- Sync success rate
- App crashes
- User engagement

---

## Support

For issues or questions:
1. Check this guide
2. Review API docs at `/docs`
3. Check application logs
4. File an issue on GitHub

---

## License

MIT License - See LICENSE file for details
