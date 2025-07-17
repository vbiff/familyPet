import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/performance_service.dart';

/// Optimized StatelessWidget with automatic RepaintBoundary and performance tracking
abstract class OptimizedStatelessWidget extends StatelessWidget {
  const OptimizedStatelessWidget({super.key});

  String get widgetName => runtimeType.toString();

  @override
  Widget build(BuildContext context) {
    performanceService.startWidgetBuildTiming(widgetName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performanceService.endWidgetBuildTiming(widgetName);
    });

    return RepaintBoundary(
      child: buildOptimized(context),
    );
  }

  /// Build method that subclasses should implement
  Widget buildOptimized(BuildContext context);
}

/// Optimized StatefulWidget with automatic RepaintBoundary and performance tracking
abstract class OptimizedStatefulWidget extends StatefulWidget {
  const OptimizedStatefulWidget({super.key});

  String get widgetName => runtimeType.toString();

  @override
  State<OptimizedStatefulWidget> createState();
}

/// Base state class for optimized widgets
abstract class OptimizedState<T extends OptimizedStatefulWidget>
    extends State<T> {
  bool _isDisposed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    performanceService.startWidgetBuildTiming(widget.widgetName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performanceService.endWidgetBuildTiming(widget.widgetName);
    });

    return RepaintBoundary(
      child: buildOptimized(context),
    );
  }

  /// Build method that subclasses should implement
  Widget buildOptimized(BuildContext context);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Safe setState that checks disposal status
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }
}

/// Optimized ListView with better performance
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? separator;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.separator,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (separator != null) {
      return ListView.separated(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: items.length,
        separatorBuilder: (context, index) => separator!,
        itemBuilder: (context, index) => RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: items.length,
      itemBuilder: (context, index) => RepaintBoundary(
        child: itemBuilder(context, items[index], index),
      ),
    );
  }
}

/// Cached network image with performance optimization
class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;

          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error, color: Colors.grey);
        },
      ),
    );
  }
}

/// Debounced text field for better performance
class OptimizedTextField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Duration debounceDuration;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextEditingController? controller;

  const OptimizedTextField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.decoration,
    this.keyboardType,
    this.maxLines,
    this.controller,
  });

  @override
  State<OptimizedTextField> createState() => _OptimizedTextFieldState();
}

class _OptimizedTextFieldState extends State<OptimizedTextField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.onChanged == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged!(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextField(
        controller: _controller,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
      ),
    );
  }
}

/// Optimized animated widget with reduced rebuilds
class OptimizedAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onAnimationComplete;

  const OptimizedAnimatedWidget({
    super.key,
    required this.child,
    required this.duration,
    this.curve = Curves.easeInOut,
    this.onAnimationComplete,
  });

  @override
  State<OptimizedAnimatedWidget> createState() =>
      _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => FadeTransition(
          opacity: _animation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Optimized sliver list for better scrolling performance
class OptimizedSliverList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double? itemExtent;

  const OptimizedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemExtent,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }

    if (itemExtent != null) {
      return SliverFixedExtentList(
        itemExtent: itemExtent!,
        delegate: SliverChildBuilderDelegate(
          (context, index) => RepaintBoundary(
            child: itemBuilder(context, items[index], index),
          ),
          childCount: items.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        ),
        childCount: items.length,
      ),
    );
  }
}

/// Widget that provides performance information overlay
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  Timer? _updateTimer;
  PerformanceMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _startUpdating();
    }
  }

  @override
  void didUpdateWidget(PerformanceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showOverlay != oldWidget.showOverlay) {
      if (widget.showOverlay) {
        _startUpdating();
      } else {
        _stopUpdating();
      }
    }
  }

  @override
  void dispose() {
    _stopUpdating();
    super.dispose();
  }

  void _startUpdating() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _metrics = performanceService.getCurrentMetrics();
        });
      }
    });
  }

  void _stopUpdating() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && _metrics != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FPS: ${_metrics!.frameRate.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Memory: ${(_metrics!.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Dropped: ${_metrics!.droppedFrames}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
