# QuickSlot Developer Guide

Quick reference for developers working on QuickSlot.

---

## Quick Start Commands

### Backend

```bash
# Setup
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create database
createdb quickslot_db

# Create admin
python create_admin.py

# Run server
uvicorn app.main:app --reload

# Access docs
open http://localhost:8000/docs
```

### Mobile

```bash
# Setup
cd frontend
flutter pub get

# Run
flutter run

# Build
flutter build apk --release
flutter build ios --release
```

---

## Project Structure

### Backend (`/backend`)

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app entry
│   ├── config.py            # Settings & env vars
│   ├── database.py          # Async SQLAlchemy setup
│   ├── models/              # Database models
│   │   └── user.py
│   ├── schemas/             # Pydantic schemas
│   │   └── user.py
│   ├── routers/             # API endpoints
│   │   ├── auth.py          # Authentication
│   │   └── sync.py          # Sync endpoints
│   └── auth/                # Auth utilities
│       └── utils.py         # JWT & password hashing
├── create_admin.py          # Admin creation script
├── requirements.txt         # Python dependencies
└── .env                     # Environment variables
```

### Mobile (`/frontend`)

```
frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── database/                # SQLite caching
│   │   │   ├── database_helper.dart
│   │   │   ├── cache_manager.dart
│   │   │   └── models/
│   │   │       ├── cached_user.dart
│   │   │       └── cached_shop.dart
│   │   ├── network/
│   │   │   └── api_client.dart      # HTTP client
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart
│   │   ├── sync/
│   │   │   └── sync_service.dart    # Offline sync
│   │   └── theme/
│   │       └── app_theme.dart
│   └── features/
│       ├── auth/                    # Authentication feature
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   ├── models/
│       │   │   └── repositories/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   └── repositories/
│       │   └── presentation/
│       │       ├── pages/
│       │       ├── providers/
│       │       └── widgets/
│       └── home/
│           └── presentation/
│               └── pages/
└── pubspec.yaml                     # Flutter dependencies
```

---

## Common Tasks

### Adding a New API Endpoint

1. **Create router** (`backend/app/routers/my_feature.py`):
```python
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db

router = APIRouter(prefix="/my-feature", tags=["my-feature"])

@router.get("/items")
async def get_items(db: AsyncSession = Depends(get_db)):
    return {"items": []}
```

2. **Register router** (`backend/app/main.py`):
```python
from .routers import auth, sync, my_feature

app.include_router(my_feature.router, prefix="/api/v1")
```

3. **Test endpoint**:
```bash
curl http://localhost:8000/api/v1/my-feature/items
```

### Adding a New Database Model

1. **Create model** (`backend/app/models/shop.py`):
```python
from sqlalchemy import Column, String, Float, Boolean
from ..database import Base

class Shop(Base):
    __tablename__ = "shops"
    
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    rating = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
```

2. **Create schema** (`backend/app/schemas/shop.py`):
```python
from pydantic import BaseModel

class ShopBase(BaseModel):
    name: str
    rating: float = 0.0

class ShopCreate(ShopBase):
    pass

class ShopResponse(ShopBase):
    id: str
    is_active: bool
    
    class Config:
        from_attributes = True
```

3. **Import in models** (`backend/app/models/__init__.py`):
```python
from .user import User
from .shop import Shop
```

### Adding a Cache Table in Mobile

1. **Update database helper** (`lib/core/database/database_helper.dart`):
```dart
await db.execute('''
  CREATE TABLE cached_my_entity (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    synced_at TEXT,
    is_dirty INTEGER DEFAULT 0
  )
''');
```

2. **Create model** (`lib/core/database/models/cached_my_entity.dart`):
```dart
class CachedMyEntity {
  final String id;
  final String name;
  final DateTime? syncedAt;
  final bool isDirty;
  
  CachedMyEntity({
    required this.id,
    required this.name,
    this.syncedAt,
    this.isDirty = false,
  });
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'synced_at': syncedAt?.toIso8601String(),
    'is_dirty': isDirty ? 1 : 0,
  };
  
  factory CachedMyEntity.fromMap(Map<String, dynamic> map) =>
    CachedMyEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      syncedAt: map['synced_at'] != null 
        ? DateTime.parse(map['synced_at']) 
        : null,
      isDirty: (map['is_dirty'] as int?) == 1,
    );
}
```

3. **Add cache methods** (`lib/core/database/cache_manager.dart`):
```dart
Future<void> cacheMyEntity(CachedMyEntity entity) async {
  final db = await _dbHelper.database;
  await db.insert(
    'cached_my_entity',
    entity.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<CachedMyEntity>> getCachedMyEntities() async {
  final db = await _dbHelper.database;
  final maps = await db.query('cached_my_entity');
  return maps.map((m) => CachedMyEntity.fromMap(m)).toList();
}
```

### Implementing Biometric Login

Already implemented! Usage:

```dart
// Check if biometric is available
final authNotifier = ref.read(authStateProvider.notifier);
final isAvailable = await authNotifier.checkBiometricAvailability();

// Enable biometric for user
await authNotifier.enableBiometric(userEmail);

// Login with biometric
await authNotifier.loginWithBiometrics();
```

### Adding Offline Operation

```dart
// Queue operation when offline
await syncService.queueOfflineOperation(
  entityType: 'reservation',
  entityId: reservation.id,
  operation: 'create',
  payload: reservation.toJson(),
);

// Will auto-sync when online
```

---

## Environment Variables

### Backend `.env`

```bash
# Required
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/quickslot_db
SECRET_KEY=your-secret-key-here

# Optional
REDIS_URL=redis://localhost:6379/0
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
ENVIRONMENT=development
```

### Mobile (Runtime)

```bash
# Default
flutter run

# Custom API
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

---

## Testing

### Backend Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest

# With coverage
pytest --cov=app tests/
```

### Mobile Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widgets/
```

---

## Debugging

### Backend Debugging

```python
# Add breakpoint
import pdb; pdb.set_trace()

# Or use debugpy for VS Code
import debugpy
debugpy.listen(5678)
debugpy.wait_for_client()
```

### Mobile Debugging

```dart
# Print debug info
print('Debug: $variable');

# Use logger
import 'package:logger/logger.dart';
final logger = Logger();
logger.d('Debug message');
logger.e('Error message', error: e, stackTrace: st);

# Inspect widget tree
flutter run --debug
# Press 'w' in terminal to dump widget tree
```

### Database Debugging

```bash
# Backend (PostgreSQL)
psql -U quickslot -d quickslot_db
\dt                    # List tables
\d users              # Describe table
SELECT * FROM users;  # Query data

# Mobile (SQLite)
# Use Android Studio Database Inspector
# Or export and view:
adb pull /data/data/com.example.quickslot/databases/quickslot_cache.db
sqlite3 quickslot_cache.db
```

---

## Performance Profiling

### Backend

```bash
# Install profiler
pip install py-spy

# Profile running app
py-spy top --pid <process_id>

# Generate flamegraph
py-spy record -o profile.svg -- python -m uvicorn app.main:app
```

### Mobile

```bash
# Performance overlay
flutter run --profile

# DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Memory profiling
flutter run --profile
# Open DevTools and check Memory tab
```

---

## Common Issues & Solutions

### Backend

**Issue: Database connection error**
```bash
# Check PostgreSQL is running
pg_isready

# Check credentials
psql -U quickslot -d quickslot_db

# Reset database
dropdb quickslot_db
createdb quickslot_db
python create_admin.py
```

**Issue: Import errors**
```bash
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall

# Check Python version
python --version  # Should be 3.9+
```

### Mobile

**Issue: SQLite errors**
```bash
# Clear cache
flutter clean
flutter pub get

# Uninstall app
flutter run --uninstall-only
flutter run
```

**Issue: Sync not working**
```dart
// Check connectivity
final isOnline = await syncService.isOnline();
print('Online: $isOnline');

// Check sync queue
final stats = await cacheManager.getCacheStats();
print('Pending sync: ${stats['pending_sync']}');

// Force sync
await syncService.syncAll();
```

---

## Code Style

### Backend (Python)

```python
# Follow PEP 8
# Use type hints
async def get_user(user_id: str, db: AsyncSession) -> User:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

# Use descriptive names
# Add docstrings
async def create_reservation(
    user_id: str,
    shop_id: str,
    slot_time: datetime,
    db: AsyncSession
) -> Reservation:
    """
    Create a new reservation for a user.
    
    Args:
        user_id: The ID of the user making the reservation
        shop_id: The ID of the shop being reserved
        slot_time: The datetime of the reservation
        db: Database session
        
    Returns:
        The created Reservation object
    """
    # Implementation
    pass
```

### Mobile (Dart)

```dart
// Follow Effective Dart
// Use meaningful names
Future<List<Shop>> getCachedShops({String? category}) async {
  final db = await _dbHelper.database;
  final maps = await db.query(
    'cached_shops',
    where: category != null ? 'category = ?' : null,
    whereArgs: category != null ? [category] : null,
  );
  return maps.map((map) => Shop.fromMap(map)).toList();
}

// Use const constructors
const SizedBox(height: 16)

// Prefer final over var
final user = await getUser();
```

---

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes and commit
git add .
git commit -m "feat: add my feature"

# Push and create PR
git push origin feature/my-feature

# Commit message format:
# feat: new feature
# fix: bug fix
# docs: documentation
# refactor: code refactoring
# test: add tests
# chore: maintenance
```

---

## Deployment Checklist

### Backend

- [ ] Update `SECRET_KEY` to strong random value
- [ ] Set `ENVIRONMENT=production`
- [ ] Configure PostgreSQL with SSL
- [ ] Set up database backups
- [ ] Configure CORS for production domains
- [ ] Enable HTTPS
- [ ] Set up monitoring (Sentry, etc.)
- [ ] Configure rate limiting
- [ ] Review security headers

### Mobile

- [ ] Update API endpoint to production
- [ ] Enable certificate pinning
- [ ] Obfuscate code (`--obfuscate`)
- [ ] Test on real devices
- [ ] Configure app signing
- [ ] Update version numbers
- [ ] Test offline functionality
- [ ] Review app permissions
- [ ] Prepare store listings

---

## Resources

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **Flutter Docs**: https://docs.flutter.dev/
- **SQLAlchemy Async**: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- **Riverpod**: https://riverpod.dev/
- **PostgreSQL**: https://www.postgresql.org/docs/

---

## Support

For questions or issues:
1. Check this guide
2. Review ARCHITECTURE.md
3. Check API docs at `/docs`
4. Review application logs
5. File an issue on GitHub
