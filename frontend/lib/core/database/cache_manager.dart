import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'models/cached_user.dart';
import 'models/cached_shop.dart';

class CacheManager {
  final DatabaseHelper _dbHelper;

  CacheManager(this._dbHelper);

  // ==================== USER CACHE ====================
  
  Future<void> cacheUser(CachedUser user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'cached_users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CachedUser?> getCachedUser(String userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;
    return CachedUser.fromMap(maps.first);
  }

  Future<CachedUser?> getCachedUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;
    return CachedUser.fromMap(maps.first);
  }

  Future<void> updateCachedUser(CachedUser user) async {
    final db = await _dbHelper.database;
    await db.update(
      'cached_users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteCachedUser(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cached_users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== SHOP CACHE ====================
  
  Future<void> cacheShop(CachedShop shop) async {
    final db = await _dbHelper.database;
    await db.insert(
      'cached_shops',
      shop.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheShops(List<CachedShop> shops) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var shop in shops) {
      batch.insert(
        'cached_shops',
        shop.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CachedShop>> getCachedShops({String? category, int? limit}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_shops',
      where: category != null ? 'category = ? AND is_active = 1' : 'is_active = 1',
      whereArgs: category != null ? [category] : null,
      orderBy: 'rating DESC, name ASC',
      limit: limit,
    );

    return maps.map((map) => CachedShop.fromMap(map)).toList();
  }

  Future<CachedShop?> getCachedShop(String shopId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_shops',
      where: 'id = ?',
      whereArgs: [shopId],
    );

    if (maps.isEmpty) return null;
    return CachedShop.fromMap(maps.first);
  }

  Future<List<CachedShop>> searchCachedShops(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_shops',
      where: '(name LIKE ? OR description LIKE ? OR address LIKE ?) AND is_active = 1',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'rating DESC',
      limit: 50,
    );

    return maps.map((map) => CachedShop.fromMap(map)).toList();
  }

  // ==================== CATEGORY CACHE ====================
  
  Future<void> cacheCategory(Map<String, dynamic> category) async {
    final db = await _dbHelper.database;
    await db.insert(
      'cached_categories',
      category,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var category in categories) {
      batch.insert(
        'cached_categories',
        category,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedCategories() async {
    final db = await _dbHelper.database;
    return await db.query(
      'cached_categories',
      orderBy: 'sort_order ASC, name ASC',
    );
  }

  // ==================== SYNC QUEUE ====================
  
  Future<void> addToSyncQueue({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await _dbHelper.database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: 50,
    );
  }

  Future<void> removeSyncItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncItemRetry(int id, String error) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  // ==================== CACHE STATS ====================
  
  Future<Map<String, int>> getCacheStats() async {
    final db = await _dbHelper.database;
    
    final userCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_users'),
    ) ?? 0;
    
    final shopCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_shops'),
    ) ?? 0;
    
    final categoryCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_categories'),
    ) ?? 0;
    
    final syncQueueCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_queue'),
    ) ?? 0;

    return {
      'users': userCount,
      'shops': shopCount,
      'categories': categoryCount,
      'pending_sync': syncQueueCount,
    };
  }

  // Check if cache needs refresh (older than 24 hours)
  Future<bool> needsCacheRefresh() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(synced_at) as last_sync FROM cached_shops',
    );
    
    if (result.isEmpty || result.first['last_sync'] == null) {
      return true;
    }
    
    final lastSync = DateTime.parse(result.first['last_sync'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    return difference.inHours > 24;
  }
}
