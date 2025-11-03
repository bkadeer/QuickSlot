import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/cache_manager.dart';
import '../database/database_helper.dart';
import '../database/models/cached_user.dart';
import '../database/models/cached_shop.dart';
import '../network/api_client.dart';
import '../errors/exceptions.dart';

class SyncService {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  final Connectivity _connectivity;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SyncService(this._apiClient, this._cacheManager, this._connectivity);

  // Start listening to connectivity changes
  void startConnectivityListener(Function(bool isOnline) onConnectivityChange) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      onConnectivityChange(isOnline);
      
      if (isOnline && !_isSyncing) {
        // Auto-sync when coming back online
        syncAll();
      }
    });
  }

  void stopConnectivityListener() {
    _connectivitySubscription?.cancel();
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  // ==================== FULL SYNC ====================
  
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    final result = SyncResult();

    try {
      // Check connectivity
      if (!await isOnline()) {
        result.success = false;
        result.message = 'No internet connection';
        return result;
      }

      // 1. Sync pending operations from queue
      await _syncPendingOperations(result);

      // 2. Fetch and cache latest data from server
      await _fetchAndCacheShops(result);
      await _fetchAndCacheCategories(result);

      // 3. Update sync timestamp
      _lastSyncTime = DateTime.now();
      
      result.success = true;
      result.message = 'Sync completed successfully';
      
    } catch (e) {
      result.success = false;
      result.message = 'Sync failed: ${e.toString()}';
    } finally {
      _isSyncing = false;
    }

    return result;
  }

  // ==================== SYNC PENDING OPERATIONS ====================
  
  Future<void> _syncPendingOperations(SyncResult result) async {
    final pendingItems = await _cacheManager.getPendingSyncItems();
    
    for (var item in pendingItems) {
      try {
        final entityType = item['entity_type'] as String;
        final operation = item['operation'] as String;
        final payload = jsonDecode(item['payload'] as String);
        
        // Execute the operation
        switch (entityType) {
          case 'reservation':
            await _syncReservation(operation, payload);
            break;
          case 'user':
            await _syncUser(operation, payload);
            break;
          default:
            break;
        }
        
        // Remove from queue on success
        await _cacheManager.removeSyncItem(item['id'] as int);
        result.syncedItems++;
        
      } catch (e) {
        // Update retry count
        await _cacheManager.updateSyncItemRetry(
          item['id'] as int,
          e.toString(),
        );
        result.failedItems++;
      }
    }
  }

  Future<void> _syncReservation(String operation, Map<String, dynamic> payload) async {
    switch (operation) {
      case 'create':
        await _apiClient.post('/reservations', data: payload);
        break;
      case 'update':
        await _apiClient.put('/reservations/${payload['id']}', data: payload);
        break;
      case 'delete':
        await _apiClient.delete('/reservations/${payload['id']}');
        break;
    }
  }

  Future<void> _syncUser(String operation, Map<String, dynamic> payload) async {
    switch (operation) {
      case 'update':
        await _apiClient.put('/users/me', data: payload);
        break;
    }
  }

  // ==================== FETCH AND CACHE ====================
  
  Future<void> _fetchAndCacheShops(SyncResult result) async {
    try {
      final response = await _apiClient.get('/shops');
      
      if (response.statusCode == 200) {
        final List<dynamic> shopsData = response.data['shops'] ?? response.data;
        final shops = shopsData.map((data) {
          return CachedShop(
            id: data['id'].toString(),
            name: data['name'] as String,
            description: data['description'] as String?,
            category: data['category'] as String?,
            imageUrl: data['image_url'] as String?,
            address: data['address'] as String?,
            latitude: data['latitude'] as double?,
            longitude: data['longitude'] as double?,
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            isActive: data['is_active'] ?? true,
            createdAt: data['created_at'] != null 
                ? DateTime.parse(data['created_at']) 
                : null,
            syncedAt: DateTime.now(),
            isDirty: false,
          );
        }).toList();
        
        await _cacheManager.cacheShops(shops);
        result.cachedShops = shops.length;
      }
    } catch (e) {
      // Silently fail - use cached data
      result.errors.add('Failed to sync shops: ${e.toString()}');
    }
  }

  Future<void> _fetchAndCacheCategories(SyncResult result) async {
    try {
      final response = await _apiClient.get('/categories');
      
      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = response.data['categories'] ?? response.data;
        final categories = categoriesData.map((data) {
          return {
            'id': data['id'].toString(),
            'name': data['name'] as String,
            'icon': data['icon'] as String?,
            'color': data['color'] as String?,
            'sort_order': data['sort_order'] as int? ?? 0,
            'synced_at': DateTime.now().toIso8601String(),
            'is_dirty': 0,
          };
        }).toList();
        
        await _cacheManager.cacheCategories(categories);
        result.cachedCategories = categories.length;
      }
    } catch (e) {
      // Silently fail - use cached data
      result.errors.add('Failed to sync categories: ${e.toString()}');
    }
  }

  // ==================== CACHE USER DATA ====================
  
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    final user = CachedUser(
      id: userData['id'].toString(),
      email: userData['email'] as String,
      name: userData['name'] as String?,
      phoneNumber: userData['phone_number'] as String?,
      profileImageUrl: userData['profile_image_url'] as String?,
      isActive: userData['is_active'] ?? true,
      isAdmin: userData['is_admin'] ?? false,
      createdAt: userData['created_at'] != null 
          ? DateTime.parse(userData['created_at']) 
          : null,
      lastLoginAt: DateTime.now(),
      syncedAt: DateTime.now(),
      isDirty: false,
    );
    
    await _cacheManager.cacheUser(user);
  }

  // ==================== OFFLINE OPERATIONS ====================
  
  Future<void> queueOfflineOperation({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _cacheManager.addToSyncQueue(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(payload),
    );
  }

  // ==================== GETTERS ====================
  
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  Future<Map<String, int>> getCacheStats() async {
    return await _cacheManager.getCacheStats();
  }

  Future<bool> needsCacheRefresh() async {
    return await _cacheManager.needsCacheRefresh();
  }
}

// Sync result model
class SyncResult {
  bool success;
  String message;
  int syncedItems;
  int failedItems;
  int cachedShops;
  int cachedCategories;
  List<String> errors;

  SyncResult({
    this.success = false,
    this.message = '',
    this.syncedItems = 0,
    this.failedItems = 0,
    this.cachedShops = 0,
    this.cachedCategories = 0,
    List<String>? errors,
  }) : errors = errors ?? [];
}

// Riverpod Providers
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager(DatabaseHelper.instance);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  final connectivity = ref.watch(connectivityProvider);
  return SyncService(apiClient, cacheManager, connectivity);
});
