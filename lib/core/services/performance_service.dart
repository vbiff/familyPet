import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'cache_service.dart';

/// Performance metrics data class
class PerformanceMetrics {
  final double frameRate;
  final double frameTime;
  final int memoryUsage;
  final int droppedFrames;
  final Map<String, double> networkTimings;
  final Map<String, double> widgetBuildTimes;
  final DateTime timestamp;

  const PerformanceMetrics({
    required this.frameRate,
    required this.frameTime,
    required this.memoryUsage,
    required this.droppedFrames,
    required this.networkTimings,
    required this.widgetBuildTimes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'frameRate': frameRate,
        'frameTime': frameTime,
        'memoryUsage': memoryUsage,
        'droppedFrames': droppedFrames,
        'networkTimings': networkTimings,
        'widgetBuildTimes': widgetBuildTimes,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Network request timing data
class NetworkTiming {
  final String endpoint;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final bool isSuccess;
  final int? statusCode;

  NetworkTiming({
    required this.endpoint,
    required this.startTime,
    this.endTime,
    this.duration,
    this.isSuccess = false,
    this.statusCode,
  });

  NetworkTiming copyWith({
    DateTime? endTime,
    Duration? duration,
    bool? isSuccess,
    int? statusCode,
  }) =>
      NetworkTiming(
        endpoint: endpoint,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        duration: duration ?? this.duration,
        isSuccess: isSuccess ?? this.isSuccess,
        statusCode: statusCode ?? this.statusCode,
      );
}

/// Widget build timing data
class WidgetBuildTiming {
  final String widgetName;
  final DateTime startTime;
  final DateTime endTime;
  final Duration buildTime;

  const WidgetBuildTiming({
    required this.widgetName,
    required this.startTime,
    required this.endTime,
    required this.buildTime,
  });
}

/// Comprehensive performance monitoring service
class PerformanceService {
  static const int _targetFrameRate = 60;
  static const Duration _metricsInterval = Duration(seconds: 30);
  static const int _maxStoredMetrics = 100;

  final List<PerformanceMetrics> _metricsHistory = [];
  final Map<String, NetworkTiming> _activeNetworkRequests = {};
  final Map<String, WidgetBuildTiming> _widgetBuildTimes = {};

  Timer? _metricsTimer;
  Timer? _frameRateTimer;
  int _frameCount = 0;
  int _droppedFrameCount = 0;
  DateTime _lastFrameTime = DateTime.now();

  bool _isMonitoring = false;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Start frame rate monitoring
    _startFrameRateMonitoring();

    // Start periodic metrics collection
    _metricsTimer = Timer.periodic(_metricsInterval, (_) => _collectMetrics());

    developer.log('Performance monitoring started', name: 'PerformanceService');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    _metricsTimer?.cancel();
    _frameRateTimer?.cancel();

    developer.log('Performance monitoring stopped', name: 'PerformanceService');
  }

  /// Start network request timing
  String startNetworkTiming(String endpoint) {
    final requestId = '${endpoint}_${DateTime.now().millisecondsSinceEpoch}';
    _activeNetworkRequests[requestId] = NetworkTiming(
      endpoint: endpoint,
      startTime: DateTime.now(),
    );
    return requestId;
  }

  /// End network request timing
  void endNetworkTiming(
    String requestId, {
    bool isSuccess = true,
    int? statusCode,
  }) {
    final timing = _activeNetworkRequests[requestId];
    if (timing == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(timing.startTime);

    _activeNetworkRequests[requestId] = timing.copyWith(
      endTime: endTime,
      duration: duration,
      isSuccess: isSuccess,
      statusCode: statusCode,
    );

    // Cache the timing for metrics
    cacheService.set(
      'network_timing_${timing.endpoint}',
      duration.inMilliseconds.toDouble(),
      ttl: const Duration(minutes: 5),
    );
  }

  /// Start widget build timing
  void startWidgetBuildTiming(String widgetName) {
    if (!_isMonitoring) return;

    final startTime = DateTime.now();
    _widgetBuildTimes['${widgetName}_build'] = WidgetBuildTiming(
      widgetName: widgetName,
      startTime: startTime,
      endTime: startTime, // Temporary
      buildTime: Duration.zero, // Temporary
    );
  }

  /// End widget build timing
  void endWidgetBuildTiming(String widgetName) {
    if (!_isMonitoring) return;

    final key = '${widgetName}_build';
    final timing = _widgetBuildTimes[key];
    if (timing == null) return;

    final endTime = DateTime.now();
    final buildTime = endTime.difference(timing.startTime);

    _widgetBuildTimes[key] = WidgetBuildTiming(
      widgetName: widgetName,
      startTime: timing.startTime,
      endTime: endTime,
      buildTime: buildTime,
    );

    // Cache build time for metrics
    cacheService.set(
      'build_time_$widgetName',
      buildTime.inMicroseconds.toDouble(),
      ttl: const Duration(minutes: 5),
    );
  }

  /// Get current performance metrics
  PerformanceMetrics getCurrentMetrics() {
    final networkTimings = <String, double>{};
    for (final timing in _activeNetworkRequests.values) {
      if (timing.duration != null) {
        networkTimings[timing.endpoint] =
            timing.duration!.inMilliseconds.toDouble();
      }
    }

    final widgetBuildTimes = <String, double>{};
    for (final timing in _widgetBuildTimes.values) {
      widgetBuildTimes[timing.widgetName] =
          timing.buildTime.inMicroseconds.toDouble();
    }

    return PerformanceMetrics(
      frameRate: _calculateFrameRate(),
      frameTime: _calculateAverageFrameTime(),
      memoryUsage: _getMemoryUsage(),
      droppedFrames: _droppedFrameCount,
      networkTimings: networkTimings,
      widgetBuildTimes: widgetBuildTimes,
      timestamp: DateTime.now(),
    );
  }

  /// Get metrics history
  List<PerformanceMetrics> get metricsHistory =>
      List.unmodifiable(_metricsHistory);

  /// Get average frame rate over last period
  double get averageFrameRate {
    if (_metricsHistory.isEmpty) return 0.0;

    final recentMetrics = _metricsHistory.take(10);
    return recentMetrics.map((m) => m.frameRate).reduce((a, b) => a + b) /
        recentMetrics.length;
  }

  /// Get memory usage trend
  List<double> get memoryUsageTrend {
    return _metricsHistory.map((m) => m.memoryUsage.toDouble()).toList();
  }

  /// Check if performance is degraded
  bool get isPerformanceDegraded {
    final currentMetrics = getCurrentMetrics();
    return currentMetrics.frameRate < _targetFrameRate * 0.8 || // Below 48 FPS
        currentMetrics.droppedFrames > 5 ||
        currentMetrics.memoryUsage > 100 * 1024 * 1024; // Above 100MB
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final current = getCurrentMetrics();
    final cacheStats = cacheService.stats;

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'currentMetrics': current.toJson(),
      'averageFrameRate': averageFrameRate,
      'isPerformanceDegraded': isPerformanceDegraded,
      'cacheStats': {
        'hitRate': cacheStats.hitRate,
        'totalEntries': cacheStats.totalEntries,
        'memoryUsage': cacheStats.memoryUsage,
      },
      'networkTimings': Map.fromEntries(
        _activeNetworkRequests.entries
            .where((e) => e.value.duration != null)
            .map((e) =>
                MapEntry(e.value.endpoint, e.value.duration!.inMilliseconds)),
      ),
      'recommendations': _generateRecommendations(),
    };
  }

  /// Start frame rate monitoring
  void _startFrameRateMonitoring() {
    _frameRateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _frameCount++;
        final now = DateTime.now();
        final timeSinceLastFrame = now.difference(_lastFrameTime);

        if (timeSinceLastFrame.inMilliseconds > 16.67) {
          // 60 FPS = 16.67ms per frame
          _droppedFrameCount++;
        }

        _lastFrameTime = now;
      });
    });
  }

  /// Calculate current frame rate
  double _calculateFrameRate() {
    if (_frameCount == 0) return 0.0;
    return _frameCount.toDouble(); // Frames per second (updated every second)
  }

  /// Calculate average frame time
  double _calculateAverageFrameTime() {
    if (_frameCount == 0) return 0.0;
    return 1000.0 / _frameCount; // Milliseconds per frame
  }

  /// Get current memory usage
  int _getMemoryUsage() {
    try {
      return ProcessInfo.currentRss;
    } catch (e) {
      // Fallback for platforms that don't support ProcessInfo
      return 0;
    }
  }

  /// Collect metrics periodically
  void _collectMetrics() {
    final metrics = getCurrentMetrics();
    _metricsHistory.add(metrics);

    // Keep only recent metrics
    if (_metricsHistory.length > _maxStoredMetrics) {
      _metricsHistory.removeAt(0);
    }

    // Cache metrics for analysis
    cacheService.set(
      CacheKeys.performanceMetrics,
      metrics.toJson(),
      ttl: const Duration(hours: 1),
    );

    // Reset frame counters
    _frameCount = 0;
    _droppedFrameCount = 0;
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    final current = getCurrentMetrics();

    if (current.frameRate < _targetFrameRate * 0.8) {
      recommendations.add(
          'Frame rate is low. Consider optimizing widgets and reducing rebuilds.');
    }

    if (current.droppedFrames > 5) {
      recommendations.add(
          'High number of dropped frames. Check for heavy computations in build methods.');
    }

    if (current.memoryUsage > 100 * 1024 * 1024) {
      recommendations.add(
          'High memory usage detected. Consider implementing more aggressive caching policies.');
    }

    final slowNetworkRequests = current.networkTimings.entries
        .where((e) => e.value > 3000) // > 3 seconds
        .map((e) => e.key);

    if (slowNetworkRequests.isNotEmpty) {
      recommendations.add(
          'Slow network requests detected: ${slowNetworkRequests.join(', ')}');
    }

    final slowWidgets = current.widgetBuildTimes.entries
        .where((e) => e.value > 16670) // > 16.67ms (1 frame at 60fps)
        .map((e) => e.key);

    if (slowWidgets.isNotEmpty) {
      recommendations
          .add('Slow widget builds detected: ${slowWidgets.join(', ')}');
    }

    return recommendations;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _metricsHistory.clear();
    _activeNetworkRequests.clear();
    _widgetBuildTimes.clear();
  }
}

/// Global performance service instance
final performanceService = PerformanceService();
