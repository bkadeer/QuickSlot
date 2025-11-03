import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quickslot_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String path = join(appDocumentsDir.path, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // User cache table
    await db.execute('''
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
      )
    ''');

    // Session tokens cache
    await db.execute('''
      CREATE TABLE cached_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        access_token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES cached_users (id)
      )
    ''');

    // Shops/Venues cache (for browsing)
    await db.execute('''
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
      )
    ''');

    // Categories cache
    await db.execute('''
      CREATE TABLE cached_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        synced_at TEXT,
        is_dirty INTEGER DEFAULT 0
      )
    ''');

    // Reservations cache
    await db.execute('''
      CREATE TABLE cached_reservations (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        shop_id TEXT NOT NULL,
        slot_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT,
        synced_at TEXT,
        is_dirty INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES cached_users (id),
        FOREIGN KEY (shop_id) REFERENCES cached_shops (id)
      )
    ''');

    // Sync queue for offline operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_cached_shops_category ON cached_shops(category)');
    await db.execute('CREATE INDEX idx_cached_reservations_user ON cached_reservations(user_id)');
    await db.execute('CREATE INDEX idx_cached_reservations_shop ON cached_reservations(shop_id)');
    await db.execute('CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Example migration for future versions
      // await db.execute('ALTER TABLE cached_users ADD COLUMN new_field TEXT');
    }
  }

  // Clear all cached data (useful for logout)
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cached_users');
    await db.delete('cached_sessions');
    await db.delete('cached_shops');
    await db.delete('cached_categories');
    await db.delete('cached_reservations');
    await db.delete('sync_queue');
  }

  // Clear only user-specific data
  Future<void> clearUserCache(String userId) async {
    final db = await database;
    await db.delete('cached_users', where: 'id = ?', whereArgs: [userId]);
    await db.delete('cached_sessions', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('cached_reservations', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Get database size for monitoring
  Future<int> getDatabaseSize() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String path = join(appDocumentsDir.path, 'quickslot_cache.db');
    final File dbFile = File(path);
    if (await dbFile.exists()) {
      return await dbFile.length();
    }
    return 0;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
