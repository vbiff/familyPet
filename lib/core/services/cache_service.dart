import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Cache entry with TTL and metadata
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;
  final int accessCount;
  final DateTime lastAccessedAt;

  const CacheEntry({
    required this.data,
    required this.createdAt,
    required this.ttl,
    this.accessCount = 0,
    required this.lastAccessedAt,
  });

  bool get isExpired => DateTime.now().isAfter(createdAt.add(ttl));

  CacheEntry<T> copyWithAccess() => CacheEntry(
        data: data,
        createdAt: createdAt,
        ttl: ttl,
        accessCount: accessCount + 1,
        lastAccessedAt: DateTime.now(),
      );
}

/// Cache statistics for performance monitoring
class CacheStats {
  final int hits;
  final int misses;
  final int evictions;
  final int totalEntries;
  final double hitRate;
  final int memoryUsage; // estimated bytes

  const CacheStats({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.totalEntries,
    required this.hitRate,
    required this.memoryUsage,
  });
}

/// High-performance caching service with TTL and LRU eviction
class CacheService {
  static const Duration _defaultTtl = Duration(minutes: 15);
  static const int _defaultMaxSize = 1000;
  static const int _maxMemoryUsageMB = 50;

  final Map<String, CacheEntry> _cache = {};
  final int _maxSize;
  Timer? _cleanupTimer;

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  CacheService({
    int maxSize = _defaultMaxSize,
    Duration cleanupInterval = const Duration(minutes: 5),
  }) : _maxSize = maxSize {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _performCleanup());
  }

  /// Get cached data with automatic TTL check
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    // Update access statistics
    _cache[key] = entry.copyWithAccess();
    _hits++;
    return entry.data as T?;
  }

  /// Set cached data with TTL
  void set<T>(
    String key,
    T data, {
    Duration? ttl,
    bool force = false,
  }) {
    final effectiveTtl = ttl ?? _defaultTtl;

    // Check memory limits before adding
    if (!force && _cache.length >= _maxSize) {
      _evictLRU();
    }

    final entry = CacheEntry<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: effectiveTtl,
      lastAccessedAt: DateTime.now(),
    );

    _cache[key] = entry;
  }

  /// Get or compute cached data
  Future<T> getOrCompute<T>(
    String key,
    Future<T> Function() computer, {
    Duration? ttl,
  }) async {
    final cached = get<T>(key);
    if (cached != null) return cached;

    final computed = await computer();
    set(key, computed, ttl: ttl);
    return computed;
  }

  /// Batch get operations
  Map<String, T?> getBatch<T>(List<String> keys) {
    final result = <String, T?>{};
    for (final key in keys) {
      result[key] = get<T>(key);
    }
    return result;
  }

  /// Batch set operations
  void setBatch<T>(Map<String, T> entries, {Duration? ttl}) {
    for (final entry in entries.entries) {
      set(entry.key, entry.value, ttl: ttl);
    }
  }

  /// Remove specific key
  bool remove(String key) {
    return _cache.remove(key) != null;
  }

  /// Remove keys by pattern
  int removePattern(Pattern pattern) {
    final keysToRemove =
        _cache.keys.where((key) => key.contains(pattern)).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    return keysToRemove.length;
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }

  /// Get cache statistics
  CacheStats get stats {
    final total = _hits + _misses;
    final hitRate = total > 0 ? _hits / total : 0.0;

    return CacheStats(
      hits: _hits,
      misses: _misses,
      evictions: _evictions,
      totalEntries: _cache.length,
      hitRate: hitRate,
      memoryUsage: _estimateMemoryUsage(),
    );
  }

  /// Check if cache contains key
  bool containsKey(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// Get all cache keys
  List<String> get keys => _cache.keys.toList();

  /// Perform cleanup of expired entries
  void _performCleanup() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    // Check memory usage and evict if necessary
    while (_estimateMemoryUsage() > _maxMemoryUsageMB * 1024 * 1024) {
      _evictLRU();
    }
  }

  /// Evict least recently used entry
  void _evictLRU() {
    if (_cache.isEmpty) return;

    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _cache.entries) {
      if (oldestAccess == null ||
          entry.value.lastAccessedAt.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccessedAt;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      _cache.remove(lruKey);
      _evictions++;
    }
  }

  /// Estimate memory usage in bytes
  int _estimateMemoryUsage() {
    int estimate = 0;
    for (final entry in _cache.entries) {
      // Basic estimation: key + data serialization length
      estimate += entry.key.length * 2; // UTF-16 chars

      try {
        final jsonData = jsonEncode(entry.value.data);
        estimate += jsonData.length * 2;
      } catch (e) {
        // Fallback for non-serializable data
        estimate += 1024; // 1KB estimate
      }
    }
    return estimate;
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

/// Specialized cache for different data types
mixin CacheKeys {
  // User and auth caching
  static const String userProfile = 'user_profile';
  static const String familyData = 'family_data';
  static const String authToken = 'auth_token';

  // Task caching
  static String taskList(String userId) => 'task_list_$userId';
  static String taskDetail(String taskId) => 'task_detail_$taskId';
  static String taskCategories = 'task_categories';

  // Pet caching
  static String petData(String petId) => 'pet_data_$petId';
  static String petImages = 'pet_images';
  static String petAnimations = 'pet_animations';

  // Family member caching
  static String familyMembers(String familyId) => 'family_members_$familyId';
  static String memberProfile(String memberId) => 'member_profile_$memberId';

  // Settings and configuration
  static const String appSettings = 'app_settings';
  static const String userPreferences = 'user_preferences';

  // Analytics and performance
  static const String analyticsCache = 'analytics_cache';
  static const String performanceMetrics = 'performance_metrics';
}

/// Global cache service instance
final cacheService = CacheService();
