# QuickSlot Architecture Documentation

## System Overview

QuickSlot is an **offline-first mobile reservation system** with a robust sync architecture that ensures seamless user experience regardless of network connectivity.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     MOBILE APP (Flutter)                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Presentation │  │   Business   │  │     Data     │      │
│  │    Layer     │  │    Logic     │  │    Layer     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                 │                  │               │
│         │                 │                  │               │
│  ┌──────▼─────────────────▼──────────────────▼──────┐      │
│  │           State Management (Riverpod)             │      │
│  └───────────────────────────────────────────────────┘      │
│                                                               │
│  ┌─────────────────────┐  ┌─────────────────────────┐      │
│  │  Secure Storage     │  │   SQLite Cache DB       │      │
│  │  ─────────────      │  │   ─────────────────     │      │
│  │  • Access Token     │  │  • cached_users         │      │
│  │  • Refresh Token    │  │  • cached_shops         │      │
│  │  • User Email       │  │  • cached_categories    │      │
│  │  • Biometric Flag   │  │  • cached_reservations  │      │
│  │                     │  │  • sync_queue           │      │
│  └─────────────────────┘  └─────────────────────────┘      │
│                                                               │
│  ┌───────────────────────────────────────────────────┐      │
│  │            Sync Service                           │      │
│  │  • Connectivity monitoring                        │      │
│  │  • Offline operation queuing                      │      │
│  │  • Auto-sync on reconnect                         │      │
│  │  • Conflict resolution                            │      │
│  └───────────────────────────────────────────────────┘      │
│                                                               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ HTTPS/REST API
                            │ JWT Authentication
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   BACKEND (FastAPI)                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────┐       │
│  │              API Endpoints                        │       │
│  │  • /auth/* - Authentication                       │       │
│  │  • /sync/* - Data synchronization                 │       │
│  │  • /shops/* - Shop management (future)            │       │
│  │  • /reservations/* - Booking management (future)  │       │
│  └──────────────────────────────────────────────────┘       │
│                                                               │
│  ┌──────────────────────────────────────────────────┐       │
│  │         Async SQLAlchemy ORM                      │       │
│  │  • Connection pooling (10 connections)            │       │
│  │  • Async operations for performance               │       │
│  │  • Automatic migrations (Alembic ready)           │       │
│  └──────────────────────────────────────────────────┘       │
│                                                               │
│  ┌──────────────────────────────────────────────────┐       │
│  │         PostgreSQL Database                       │       │
│  │  • users - User accounts                          │       │
│  │  • shops - Venues/locations (to implement)        │       │
│  │  • categories - Shop categories (to implement)    │       │
│  │  • reservations - Bookings (to implement)         │       │
│  └──────────────────────────────────────────────────┘       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### 1. User Authentication Flow

```
User Opens App
     │
     ├─→ Check Secure Storage for tokens
     │   │
     │   ├─→ Tokens exist?
     │   │   │
     │   │   ├─→ YES: Check if biometric enabled
     │   │   │   │
     │   │   │   ├─→ YES: Show biometric prompt
     │   │   │   │   │
     │   │   │   │   ├─→ Success: Auto-login
     │   │   │   │   └─→ Fail: Show login screen
     │   │   │   │
     │   │   │   └─→ NO: Validate token with backend
     │   │   │       │
     │   │   │       ├─→ Valid: Navigate to home
     │   │   │       └─→ Invalid: Show login screen
     │   │   │
     │   │   └─→ NO: Show login screen
     │   │
     │   └─→ User enters credentials
     │       │
     │       └─→ POST /api/v1/auth/login
     │           │
     │           ├─→ Success:
     │           │   • Store tokens in Secure Storage
     │           │   • Cache user data in SQLite
     │           │   • Trigger initial sync
     │           │   • Navigate to home
     │           │
     │           └─→ Fail: Show error message
```

### 2. Offline-First Data Flow

```
User Action (e.g., Browse Shops)
     │
     ├─→ Check connectivity
     │   │
     │   ├─→ ONLINE:
     │   │   │
     │   │   ├─→ Fetch from API
     │   │   │   │
     │   │   │   ├─→ Success:
     │   │   │   │   • Cache in SQLite
     │   │   │   │   • Display to user
     │   │   │   │
     │   │   │   └─→ Fail:
     │   │   │       • Load from SQLite cache
     │   │   │       • Show cached data with indicator
     │   │   │
     │   │   └─→ Check cache freshness
     │   │       │
     │   │       └─→ If stale (>24h): Background refresh
     │   │
     │   └─→ OFFLINE:
     │       │
     │       └─→ Load from SQLite cache
     │           │
     │           ├─→ Cache exists: Display with offline indicator
     │           └─→ No cache: Show empty state
```

### 3. Sync Flow

```
Connectivity Restored
     │
     ├─→ Sync Service detects online status
     │   │
     │   ├─→ Check sync_queue for pending operations
     │   │   │
     │   │   ├─→ Queue not empty:
     │   │   │   │
     │   │   │   └─→ For each queued operation:
     │   │   │       │
     │   │   │       ├─→ POST /api/v1/sync/batch
     │   │   │       │   │
     │   │   │       │   ├─→ Success:
     │   │   │       │   │   • Remove from queue
     │   │   │       │   │   • Update cache
     │   │   │       │   │
     │   │   │       │   └─→ Fail:
     │   │   │       │       • Increment retry count
     │   │   │       │       • Keep in queue
     │   │   │       │       • Log error
     │   │   │
     │   │   └─→ Queue empty: Continue to data sync
     │   │
     │   ├─→ Fetch latest data from server
     │   │   │
     │   │   ├─→ GET /api/v1/sync/shops
     │   │   ├─→ GET /api/v1/sync/categories
     │   │   │
     │   │   └─→ Update SQLite cache
     │   │       • Mark as synced_at = now()
     │   │       • Set is_dirty = false
     │   │
     │   └─→ Notify UI of sync completion
```

---

## Security Architecture

### Authentication & Authorization

```
┌─────────────────────────────────────────────────────────┐
│                  Security Layers                         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  1. Transport Layer Security (TLS/HTTPS)                 │
│     • All API communication encrypted                    │
│     • Certificate pinning (production)                   │
│                                                           │
│  2. Authentication (JWT)                                 │
│     • Access Token (30 min expiry)                       │
│     • Refresh Token (7 day expiry)                       │
│     • Token rotation on refresh                          │
│                                                           │
│  3. Password Security                                    │
│     • PBKDF2-SHA256 hashing                             │
│     • 100,000 iterations                                 │
│     • Random salt per password                           │
│     • Constant-time comparison                           │
│                                                           │
│  4. Secure Storage (Mobile)                              │
│     • iOS: Keychain                                      │
│     • Android: EncryptedSharedPreferences               │
│     • Hardware-backed encryption                         │
│                                                           │
│  5. Biometric Authentication                             │
│     • Face ID / Touch ID (iOS)                          │
│     • Fingerprint / Face Unlock (Android)               │
│     • Fallback to password                               │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Token Refresh Flow

```
API Request with Access Token
     │
     ├─→ Backend validates token
     │   │
     │   ├─→ Valid: Process request
     │   │
     │   └─→ Expired (401):
     │       │
     │       └─→ Mobile intercepts 401
     │           │
     │           └─→ POST /api/v1/auth/refresh
     │               with refresh_token
     │               │
     │               ├─→ Success:
     │               │   • Get new access_token
     │               │   • Get new refresh_token
     │               │   • Update Secure Storage
     │               │   • Retry original request
     │               │
     │               └─→ Fail:
     │                   • Clear all tokens
     │                   • Redirect to login
```

---

## Database Schema

### PostgreSQL (Backend - Authoritative)

```sql
-- Users table
CREATE TABLE users (
    id VARCHAR PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    hashed_password VARCHAR NOT NULL,
    name VARCHAR,
    phone_number VARCHAR,
    profile_image_url VARCHAR,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);
```

### SQLite (Mobile - Cache)

```sql
-- Cached users
CREATE TABLE cached_users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT,
    phone_number TEXT,
    profile_image_url TEXT,
    is_active INTEGER DEFAULT 1,
    is_admin INTEGER DEFAULT 0,
    created_at TEXT,
    last_login_at TEXT,
    synced_at TEXT,
    is_dirty INTEGER DEFAULT 0
);

-- Cached shops
CREATE TABLE cached_shops (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    image_url TEXT,
    address TEXT,
    latitude REAL,
    longitude REAL,
    rating REAL DEFAULT 0.0,
    is_active INTEGER DEFAULT 1,
    created_at TEXT,
    synced_at TEXT,
    is_dirty INTEGER DEFAULT 0
);

CREATE INDEX idx_cached_shops_category ON cached_shops(category);

-- Sync queue for offline operations
CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    payload TEXT NOT NULL,
    created_at TEXT NOT NULL,
    retry_count INTEGER DEFAULT 0,
    last_error TEXT
);

CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id);
```

---

## API Endpoints

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/auth/register` | Register new user | No |
| POST | `/api/v1/auth/login` | Login with credentials | No |
| POST | `/api/v1/auth/refresh` | Refresh access token | No |
| GET | `/api/v1/auth/me` | Get current user | Yes |
| POST | `/api/v1/auth/logout` | Logout user | Yes |
| POST | `/api/v1/auth/password-reset/request` | Request password reset | No |

### Sync Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/sync/shops` | Get shops for caching | Yes |
| GET | `/api/v1/sync/categories` | Get categories | Yes |
| POST | `/api/v1/sync/batch` | Batch sync operations | Yes |
| GET | `/api/v1/sync/status` | Server status | Yes |
| POST | `/api/v1/sync/check-updates` | Check for updates | Yes |

---

## Performance Considerations

### Backend Optimizations

1. **Connection Pooling**
   - Pool size: 10 connections
   - Max overflow: 20 connections
   - Pre-ping enabled for connection health

2. **Async Operations**
   - All database operations are async
   - Non-blocking I/O for better concurrency
   - Efficient handling of multiple requests

3. **Query Optimization**
   - Indexes on frequently queried columns
   - Pagination for large datasets
   - Selective field loading

### Mobile Optimizations

1. **SQLite Performance**
   - Indexes on foreign keys and search columns
   - Batch inserts for bulk operations
   - WAL mode for concurrent reads/writes

2. **Memory Management**
   - Lazy loading of images
   - Pagination for lists
   - Cache size limits

3. **Network Efficiency**
   - Batch API requests
   - Compression for large payloads
   - Conditional requests (ETags)

---

## Scalability

### Horizontal Scaling

```
┌─────────────┐
│ Load        │
│ Balancer    │
└──────┬──────┘
       │
       ├─────────┬─────────┬─────────┐
       │         │         │         │
   ┌───▼───┐ ┌──▼────┐ ┌──▼────┐ ┌──▼────┐
   │ API   │ │ API   │ │ API   │ │ API   │
   │ Node 1│ │ Node 2│ │ Node 3│ │ Node 4│
   └───┬───┘ └───┬───┘ └───┬───┘ └───┬───┘
       │         │         │         │
       └─────────┴─────────┴─────────┘
                 │
         ┌───────▼────────┐
         │   PostgreSQL   │
         │   Primary      │
         └───────┬────────┘
                 │
         ┌───────┴────────┐
         │   PostgreSQL   │
         │   Replicas     │
         └────────────────┘
```

### Caching Strategy

```
Mobile Request
     │
     ├─→ Check SQLite cache
     │   │
     │   ├─→ Cache hit: Return immediately
     │   │
     │   └─→ Cache miss: Request from API
     │       │
     │       └─→ API checks Redis cache
     │           │
     │           ├─→ Cache hit: Return from Redis
     │           │
     │           └─→ Cache miss: Query PostgreSQL
     │               │
     │               └─→ Store in Redis & return
```

---

## Monitoring & Observability

### Key Metrics

**Backend:**
- Request rate (req/sec)
- Response time (p50, p95, p99)
- Error rate (%)
- Database connection pool usage
- Active sessions

**Mobile:**
- Cache hit rate (%)
- Sync success rate (%)
- Offline operation queue size
- App startup time
- Crash rate

### Logging

**Backend:**
```python
# Structured logging
logger.info("User login", extra={
    "user_id": user.id,
    "email": user.email,
    "ip_address": request.client.host
})
```

**Mobile:**
```dart
// Debug logging
logger.d('Cache hit for shop: $shopId');
logger.e('Sync failed', error: e, stackTrace: st);
```

---

## Future Enhancements

### Planned Features

1. **Real-time Updates**
   - WebSocket connections for live data
   - Push notifications for bookings
   - Live availability updates

2. **Advanced Sync**
   - Conflict resolution UI
   - Selective sync (user preferences)
   - Bandwidth-aware sync

3. **Offline Capabilities**
   - Full offline booking
   - Optimistic UI updates
   - Smart retry strategies

4. **Analytics**
   - User behavior tracking
   - Performance monitoring
   - Business intelligence

---

## Conclusion

This architecture provides:
- ✅ **Offline-first experience** - Works without internet
- ✅ **Secure authentication** - JWT + biometrics
- ✅ **Automatic sync** - Seamless data synchronization
- ✅ **Scalable backend** - PostgreSQL + async operations
- ✅ **Production-ready** - Security, performance, monitoring

The system is designed to scale from MVP to enterprise-level deployment while maintaining excellent user experience.
