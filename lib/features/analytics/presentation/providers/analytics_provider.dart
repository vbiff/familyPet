import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/real_analytics_service.dart';

// Provider for the real analytics service
final analyticsServiceProvider = Provider<RealAnalyticsService>((ref) {
  return RealAnalyticsService();
});
