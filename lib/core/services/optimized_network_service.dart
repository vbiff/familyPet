import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';
import 'performance_service.dart';

/// Request configuration for network operations
class NetworkRequest {
  final String endpoint;
  final Map<String, dynamic>? queryParameters;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final Duration? timeout;
  final Duration? cacheTtl;
  final bool useCache;
  final String? cacheKey;

  const NetworkRequest({
    required this.endpoint,
    this.queryParameters,
    this.body,
    this.headers,
    this.timeout = const Duration(seconds: 30),
    this.cacheTtl = const Duration(minutes: 5),
    this.useCache = true,
    this.cacheKey,
  });

  String get effectiveCacheKey =>
      cacheKey ??
      'network_${endpoint}_${jsonEncode(queryParameters ?? {})}_${jsonEncode(body ?? {})}';
}

/// Network response with caching metadata
class NetworkResponse<T> {
  final T data;
  final bool fromCache;
  final Duration? requestDuration;
  final DateTime timestamp;
  final Map<String, String>? headers;

  const NetworkResponse({
    required this.data,
    required this.fromCache,
    this.requestDuration,
    required this.timestamp,
    this.headers,
  });
}

/// Batch request for multiple operations
class BatchRequest {
  final String id;
  final List<NetworkRequest> requests;
  final Duration maxWaitTime;
  final int maxBatchSize;

  const BatchRequest({
    required this.id,
    required this.requests,
    this.maxWaitTime = const Duration(milliseconds: 100),
    this.maxBatchSize = 10,
  });
}

/// Optimized network service with caching and batching
class OptimizedNetworkService {
  final SupabaseClient _supabaseClient;
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  final Map<String, Timer> _batchTimers = {};
  final Map<String, List<NetworkRequest>> _batchQueues = {};

  OptimizedNetworkService(this._supabaseClient);

  /// GET request with caching
  Future<NetworkResponse<T>> get<T>(
    NetworkRequest request, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    // Check cache first
    if (request.useCache) {
      final cached = cacheService.get<T>(request.effectiveCacheKey);
      if (cached != null) {
        return NetworkResponse<T>(
          data: cached,
          fromCache: true,
          timestamp: DateTime.now(),
        );
      }
    }

    // Start performance monitoring
    final requestId = performanceService.startNetworkTiming(request.endpoint);
    final startTime = DateTime.now();

    try {
      // Prevent duplicate requests
      final pendingKey = '${request.endpoint}_${request.effectiveCacheKey}';
      if (_pendingRequests.containsKey(pendingKey)) {
        final result = await _pendingRequests[pendingKey]!.future;
        return NetworkResponse<T>(
          data: fromJson(result),
          fromCache: false,
          requestDuration: DateTime.now().difference(startTime),
          timestamp: DateTime.now(),
        );
      }

      final completer = Completer<Map<String, dynamic>>();
      _pendingRequests[pendingKey] = completer;

      try {
        var query = _supabaseClient.from(request.endpoint).select();

        // Apply query parameters
        if (request.queryParameters != null) {
          for (final param in request.queryParameters!.entries) {
            query = query.eq(param.key, param.value);
          }
        }

        final response = await query.timeout(request.timeout!);
        final data = response as List<dynamic>;
        final result = data.isNotEmpty
            ? data.first as Map<String, dynamic>
            : <String, dynamic>{};

        completer.complete(result);
        _pendingRequests.remove(pendingKey);

        // Cache the result
        final parsedData = fromJson(result);
        if (request.useCache) {
          cacheService.set(
            request.effectiveCacheKey,
            parsedData,
            ttl: request.cacheTtl,
          );
        }

        // End performance monitoring
        performanceService.endNetworkTiming(requestId, isSuccess: true);

        return NetworkResponse<T>(
          data: parsedData,
          fromCache: false,
          requestDuration: DateTime.now().difference(startTime),
          timestamp: DateTime.now(),
        );
      } catch (e) {
        completer.completeError(e);
        _pendingRequests.remove(pendingKey);
        rethrow;
      }
    } catch (e) {
      // End performance monitoring with error
      performanceService.endNetworkTiming(requestId, isSuccess: false);
      rethrow;
    }
  }

  /// GET list with caching
  Future<NetworkResponse<List<T>>> getList<T>(
    NetworkRequest request, {
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    // Check cache first
    if (request.useCache) {
      final cached = cacheService.get<List<T>>(request.effectiveCacheKey);
      if (cached != null) {
        return NetworkResponse<List<T>>(
          data: cached,
          fromCache: true,
          timestamp: DateTime.now(),
        );
      }
    }

    // Start performance monitoring
    final requestId = performanceService.startNetworkTiming(request.endpoint);
    final startTime = DateTime.now();

    try {
      dynamic query = _supabaseClient.from(request.endpoint).select();

      // Apply query parameters
      if (request.queryParameters != null) {
        for (final param in request.queryParameters!.entries) {
          if (param.key == 'order') {
            final parts = param.value.toString().split(',');
            if (parts.length == 2) {
              query = query.order(parts[0], ascending: parts[1] == 'asc');
            }
          } else if (param.key == 'limit') {
            query = query.limit(int.parse(param.value.toString()));
          } else {
            query = query.eq(param.key, param.value);
          }
        }
      }

      final response = await query.timeout(request.timeout!);
      final data = response as List<dynamic>;
      final results =
          data.map((item) => fromJson(item as Map<String, dynamic>)).toList();

      // Cache the result
      if (request.useCache) {
        cacheService.set(
          request.effectiveCacheKey,
          results,
          ttl: request.cacheTtl,
        );
      }

      // End performance monitoring
      performanceService.endNetworkTiming(requestId, isSuccess: true);

      return NetworkResponse<List<T>>(
        data: results,
        fromCache: false,
        requestDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // End performance monitoring with error
      performanceService.endNetworkTiming(requestId, isSuccess: false);
      rethrow;
    }
  }

  /// POST request with cache invalidation
  Future<NetworkResponse<T>> post<T>(
    NetworkRequest request, {
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? invalidateCachePatterns,
  }) async {
    // Start performance monitoring
    final requestId = performanceService.startNetworkTiming(request.endpoint);
    final startTime = DateTime.now();

    try {
      final response = await _supabaseClient
          .from(request.endpoint)
          .insert(request.body!)
          .select()
          .single()
          .timeout(request.timeout!);

      final result = fromJson(response);

      // Invalidate related cache entries
      if (invalidateCachePatterns != null) {
        for (final pattern in invalidateCachePatterns) {
          cacheService.removePattern(pattern);
        }
      }

      // End performance monitoring
      performanceService.endNetworkTiming(requestId, isSuccess: true);

      return NetworkResponse<T>(
        data: result,
        fromCache: false,
        requestDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // End performance monitoring with error
      performanceService.endNetworkTiming(requestId, isSuccess: false);
      rethrow;
    }
  }

  /// PUT/PATCH request with cache invalidation
  Future<NetworkResponse<T>> update<T>(
    NetworkRequest request, {
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? invalidateCachePatterns,
    String? id,
  }) async {
    // Start performance monitoring
    final requestId = performanceService.startNetworkTiming(request.endpoint);
    final startTime = DateTime.now();

    try {
      var query = _supabaseClient.from(request.endpoint).update(request.body!);

      if (id != null) {
        query = query.eq('id', id);
      }

      final response = await query.select().single().timeout(request.timeout!);
      final result = fromJson(response);

      // Invalidate related cache entries
      if (invalidateCachePatterns != null) {
        for (final pattern in invalidateCachePatterns) {
          cacheService.removePattern(pattern);
        }
      }

      // Update cache if applicable
      if (request.useCache) {
        cacheService.set(
          request.effectiveCacheKey,
          result,
          ttl: request.cacheTtl,
        );
      }

      // End performance monitoring
      performanceService.endNetworkTiming(requestId, isSuccess: true);

      return NetworkResponse<T>(
        data: result,
        fromCache: false,
        requestDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // End performance monitoring with error
      performanceService.endNetworkTiming(requestId, isSuccess: false);
      rethrow;
    }
  }

  /// DELETE request with cache invalidation
  Future<NetworkResponse<void>> delete(
    NetworkRequest request, {
    List<String>? invalidateCachePatterns,
    String? id,
  }) async {
    // Start performance monitoring
    final requestId = performanceService.startNetworkTiming(request.endpoint);
    final startTime = DateTime.now();

    try {
      var query = _supabaseClient.from(request.endpoint).delete();

      if (id != null) {
        query = query.eq('id', id);
      }

      await query.timeout(request.timeout!);

      // Invalidate related cache entries
      if (invalidateCachePatterns != null) {
        for (final pattern in invalidateCachePatterns) {
          cacheService.removePattern(pattern);
        }
      }

      // End performance monitoring
      performanceService.endNetworkTiming(requestId, isSuccess: true);

      return NetworkResponse<void>(
        data: null,
        fromCache: false,
        requestDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // End performance monitoring with error
      performanceService.endNetworkTiming(requestId, isSuccess: false);
      rethrow;
    }
  }

  /// Batch multiple requests
  Future<List<NetworkResponse<dynamic>>> batch(
      BatchRequest batchRequest) async {
    final results = <NetworkResponse<dynamic>>[];

    // Split into chunks of maxBatchSize
    for (int i = 0;
        i < batchRequest.requests.length;
        i += batchRequest.maxBatchSize) {
      final chunk = batchRequest.requests
          .skip(i)
          .take(batchRequest.maxBatchSize)
          .toList();

      // Execute chunk in parallel
      final futures = chunk.map((request) async {
        try {
          // This is a simplified batch - in a real implementation,
          // you'd need to handle different request types
          return await get<Map<String, dynamic>>(
            request,
            fromJson: (json) => json,
          );
        } catch (e) {
          return NetworkResponse<Map<String, dynamic>>(
            data: {'error': e.toString()},
            fromCache: false,
            timestamp: DateTime.now(),
          );
        }
      });

      final chunkResults = await Future.wait(futures);
      results.addAll(chunkResults);
    }

    return results;
  }

  /// Real-time subscription with caching
  Stream<T> subscribe<T>(
    String table,
    T Function(Map<String, dynamic>) fromJson, {
    String? filter,
    Duration? cacheTtl = const Duration(minutes: 1),
  }) {
    final controller = StreamController<T>.broadcast();

    // Set up Supabase real-time subscription
    final subscription =
        _supabaseClient.from(table).stream(primaryKey: ['id']).listen((data) {
      for (final item in data) {
        final parsed = fromJson(item);

        // Cache the data
        final cacheKey = 'realtime_${table}_${item['id']}';
        cacheService.set(cacheKey, parsed, ttl: cacheTtl);

        controller.add(parsed);
      }
    });

    // Clean up subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Preload data for better performance
  Future<void> preloadData(List<NetworkRequest> requests) async {
    final futures = requests.map((request) async {
      try {
        await get<Map<String, dynamic>>(
          request,
          fromJson: (json) => json,
        );
      } catch (e) {
        // Silently ignore preload errors
        debugPrint('Preload failed for ${request.endpoint}: $e');
      }
    });

    await Future.wait(futures);
  }

  /// Clear all network-related cache
  void clearNetworkCache() {
    cacheService.removePattern('network_');
    cacheService.removePattern('realtime_');
  }

  /// Get network performance metrics
  Map<String, dynamic> getNetworkMetrics() {
    final metrics = performanceService.getCurrentMetrics();
    return {
      'networkTimings': metrics.networkTimings,
      'averageRequestTime': metrics.networkTimings.values.isNotEmpty
          ? metrics.networkTimings.values.reduce((a, b) => a + b) /
              metrics.networkTimings.length
          : 0.0,
      'totalRequests': metrics.networkTimings.length,
      'cacheStats': cacheService.stats,
    };
  }

  /// Dispose resources
  void dispose() {
    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();
    _batchQueues.clear();
    _pendingRequests.clear();
  }
}

/// Global optimized network service provider
OptimizedNetworkService? _optimizedNetworkService;

OptimizedNetworkService getOptimizedNetworkService() {
  _optimizedNetworkService ??=
      OptimizedNetworkService(Supabase.instance.client);
  return _optimizedNetworkService!;
}
