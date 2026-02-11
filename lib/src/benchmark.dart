import 'dart:async';
import 'package:flutter/foundation.dart';

/// Represents a single benchmark measurement
class BenchmarkResult {
  final String name;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic>? metadata;
  final String? parentId;
  final String id;

  BenchmarkResult({
    required this.name,
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.metadata,
    this.parentId,
    String? id,
  }) : id = id ?? _generateId();

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration_ms': duration.inMilliseconds,
      'duration_us': duration.inMicroseconds,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (parentId != null) 'parent_id': parentId,
    };
  }

  @override
  String toString() {
    if (duration.inMilliseconds > 1000) {
      return '$name: ${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    } else if (duration.inMicroseconds > 1000) {
      return '$name: ${(duration.inMicroseconds / 1000).toStringAsFixed(2)}ms';
    } else {
      return '$name: ${duration.inMicroseconds}μs';
    }
  }
}

/// Active benchmark timer
class BenchmarkTimer {
  final String name;
  final DateTime startTime;
  final String id;
  final String? parentId;
  final Map<String, dynamic>? metadata;
  final List<BenchmarkResult> _subBenchmarks = [];

  BenchmarkTimer({
    required this.name,
    required this.startTime,
    String? id,
    this.parentId,
    this.metadata,
  }) : id = id ?? BenchmarkResult._generateId();

  /// Stop this benchmark and return the result
  BenchmarkResult stop({Map<String, dynamic>? additionalMetadata}) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    final combinedMetadata = {
      ...?metadata,
      ...?additionalMetadata,
      if (_subBenchmarks.isNotEmpty)
        'sub_benchmarks': _subBenchmarks.map((b) => b.toJson()).toList(),
    };

    final result = BenchmarkResult(
      id: id,
      name: name,
      duration: duration,
      startTime: startTime,
      endTime: endTime,
      metadata: combinedMetadata.isEmpty ? null : combinedMetadata,
      parentId: parentId,
    );

    // Log the benchmark result if in debug mode
    if (kDebugMode) {
      print('[Benchmark] $result');
    }

    return result;
  }

  /// Add a sub-benchmark result
  void addSubBenchmark(BenchmarkResult result) {
    _subBenchmarks.add(result);
  }
}

/// Main benchmark manager class
class InfobitsBenchmark {
  static InfobitsBenchmark? _instance;
  static InfobitsBenchmark get instance {
    _instance ??= InfobitsBenchmark._();
    return _instance!;
  }

  InfobitsBenchmark._();

  final Map<String, BenchmarkTimer> _activeTimers = {};
  final List<BenchmarkResult> _completedBenchmarks = [];
  final Map<String, List<BenchmarkResult>> _groupedBenchmarks = {};

  /// Start a new benchmark
  BenchmarkTimer start(String name, {Map<String, dynamic>? metadata}) {
    // Extract parentId from metadata if present
    final parentId = metadata?['parentId'] as String?;

    final timer = BenchmarkTimer(
      name: name,
      startTime: DateTime.now(),
      metadata: metadata,
      parentId: parentId,
    );

    _activeTimers[timer.id] = timer;

    if (kDebugMode) {
      print('[Benchmark] Started: $name');
    }

    return timer;
  }

  /// Stop a benchmark by its timer
  BenchmarkResult stop(
    BenchmarkTimer timer, {
    Map<String, dynamic>? additionalMetadata,
  }) {
    final result = timer.stop(additionalMetadata: additionalMetadata);

    _activeTimers.remove(timer.id);
    _completedBenchmarks.add(result);

    // Group by name for statistics
    _groupedBenchmarks.putIfAbsent(result.name, () => []).add(result);

    // If this has a parent, add it to parent's sub-benchmarks
    if (result.parentId != null && _activeTimers.containsKey(result.parentId)) {
      _activeTimers[result.parentId]!.addSubBenchmark(result);
    }

    return result;
  }

  /// Stop a benchmark by name (stops the most recent one with that name)
  BenchmarkResult? stopByName(
    String name, {
    Map<String, dynamic>? additionalMetadata,
  }) {
    final timer = _activeTimers.values.where((t) => t.name == name).lastOrNull;

    if (timer != null) {
      return stop(timer, additionalMetadata: additionalMetadata);
    }
    return null;
  }

  /// Measure the execution time of a synchronous function
  T measure<T>(String name, T Function() fn, {Map<String, dynamic>? metadata}) {
    final timer = start(name, metadata: metadata);
    try {
      final result = fn();
      stop(timer);
      return result;
    } catch (e) {
      stop(timer, additionalMetadata: {'error': e.toString()});
      rethrow;
    }
  }

  /// Measure the execution time of an asynchronous function
  Future<T> measureAsync<T>(
    String name,
    Future<T> Function() fn, {
    Map<String, dynamic>? metadata,
  }) async {
    final timer = start(name, metadata: metadata);
    try {
      final result = await fn();
      stop(timer);
      return result;
    } catch (e) {
      stop(timer, additionalMetadata: {'error': e.toString()});
      rethrow;
    }
  }

  /// Measure multiple iterations and return statistics
  Future<BenchmarkStatistics> measureIterations(
    String name,
    Future<void> Function() fn, {
    int iterations = 10,
    int warmupIterations = 2,
    Map<String, dynamic>? metadata,
  }) async {
    // Warmup iterations
    for (int i = 0; i < warmupIterations; i++) {
      await fn();
    }

    // Actual measurements
    final results = <BenchmarkResult>[];
    for (int i = 0; i < iterations; i++) {
      final timer = start('$name #${i + 1}', metadata: metadata);
      try {
        await fn();
        results.add(stop(timer));
      } catch (e) {
        stop(timer, additionalMetadata: {'error': e.toString()});
        rethrow;
      }
    }

    return BenchmarkStatistics(name: name, results: results);
  }

  /// Get all completed benchmarks
  List<BenchmarkResult> get completedBenchmarks =>
      List.unmodifiable(_completedBenchmarks);

  /// Get benchmarks grouped by name
  Map<String, List<BenchmarkResult>> get groupedBenchmarks =>
      Map.unmodifiable(_groupedBenchmarks);

  /// Get currently active benchmarks
  List<BenchmarkTimer> get activeTimers =>
      List.unmodifiable(_activeTimers.values);

  /// Clear all benchmark data
  void clear() {
    _activeTimers.clear();
    _completedBenchmarks.clear();
    _groupedBenchmarks.clear();
  }

  /// Get statistics for benchmarks with a specific name
  BenchmarkStatistics? getStatistics(String name) {
    final results = _groupedBenchmarks[name];
    if (results == null || results.isEmpty) return null;
    return BenchmarkStatistics(name: name, results: results);
  }

  /// Generate a report of all benchmarks
  String generateReport({bool detailed = false}) {
    final buffer = StringBuffer();
    buffer.writeln('=== Benchmark Report ===');
    buffer.writeln('Total benchmarks: ${_completedBenchmarks.length}');
    buffer.writeln();

    if (_groupedBenchmarks.isNotEmpty) {
      buffer.writeln('Grouped Results:');
      for (final entry in _groupedBenchmarks.entries) {
        final stats = BenchmarkStatistics(
          name: entry.key,
          results: entry.value,
        );
        buffer.writeln(stats.toString());

        if (detailed) {
          for (final result in entry.value) {
            buffer.writeln('  - ${result.toString()}');
          }
        }
        buffer.writeln();
      }
    }

    if (_activeTimers.isNotEmpty) {
      buffer.writeln('Active Benchmarks:');
      for (final timer in _activeTimers.values) {
        final elapsed = DateTime.now().difference(timer.startTime);
        buffer.writeln(
          '  - ${timer.name}: ${elapsed.inMilliseconds}ms (running)',
        );
      }
    }

    return buffer.toString();
  }
}

/// Statistics for a group of benchmark results
class BenchmarkStatistics {
  final String name;
  final List<BenchmarkResult> results;

  BenchmarkStatistics({required this.name, required this.results});

  Duration get min =>
      results.map((r) => r.duration).reduce((a, b) => a < b ? a : b);
  Duration get max =>
      results.map((r) => r.duration).reduce((a, b) => a > b ? a : b);

  Duration get mean {
    final totalMicroseconds = results.fold<int>(
      0,
      (sum, r) => sum + r.duration.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ results.length);
  }

  Duration get median {
    final sorted = results.map((r) => r.duration.inMicroseconds).toList()
      ..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isEven) {
      return Duration(microseconds: (sorted[middle - 1] + sorted[middle]) ~/ 2);
    } else {
      return Duration(microseconds: sorted[middle]);
    }
  }

  double get standardDeviation {
    final meanMicros = mean.inMicroseconds;
    final squaredDiffs = results.map((r) {
      final diff = r.duration.inMicroseconds - meanMicros;
      return diff * diff;
    });
    final variance = squaredDiffs.reduce((a, b) => a + b) / results.length;
    return variance.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': results.length,
      'min_ms': min.inMilliseconds,
      'max_ms': max.inMilliseconds,
      'mean_ms': mean.inMilliseconds,
      'median_ms': median.inMilliseconds,
      'std_dev': standardDeviation,
    };
  }

  @override
  String toString() {
    return '$name: count=${results.length}, '
        'min=${_formatDuration(min)}, '
        'max=${_formatDuration(max)}, '
        'mean=${_formatDuration(mean)}, '
        'median=${_formatDuration(median)}';
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds > 1000) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(2)}s';
    } else if (d.inMicroseconds > 1000) {
      return '${(d.inMicroseconds / 1000).toStringAsFixed(2)}ms';
    } else {
      return '${d.inMicroseconds}μs';
    }
  }
}

/// Extension to make benchmarking easier
extension BenchmarkExtension<T> on T {
  /// Benchmark this value with a transformation
  T benchmark(String name, {Map<String, dynamic>? metadata}) {
    InfobitsBenchmark.instance.start(name, metadata: metadata);
    return this;
  }
}

/// Global benchmark functions for convenience
class Benchmark {
  /// Start a benchmark
  static BenchmarkTimer start(String name, {Map<String, dynamic>? metadata}) {
    return InfobitsBenchmark.instance.start(name, metadata: metadata);
  }

  /// Stop a benchmark
  static BenchmarkResult stop(
    BenchmarkTimer timer, {
    Map<String, dynamic>? metadata,
  }) {
    return InfobitsBenchmark.instance.stop(timer, additionalMetadata: metadata);
  }

  /// Stop a benchmark by name
  static BenchmarkResult? stopByName(
    String name, {
    Map<String, dynamic>? metadata,
  }) {
    return InfobitsBenchmark.instance.stopByName(
      name,
      additionalMetadata: metadata,
    );
  }

  /// Measure a synchronous function
  static T measure<T>(
    String name,
    T Function() fn, {
    Map<String, dynamic>? metadata,
  }) {
    return InfobitsBenchmark.instance.measure(name, fn, metadata: metadata);
  }

  /// Measure an asynchronous function
  static Future<T> measureAsync<T>(
    String name,
    Future<T> Function() fn, {
    Map<String, dynamic>? metadata,
  }) {
    return InfobitsBenchmark.instance.measureAsync(
      name,
      fn,
      metadata: metadata,
    );
  }

  /// Measure multiple iterations
  static Future<BenchmarkStatistics> measureIterations(
    String name,
    Future<void> Function() fn, {
    int iterations = 10,
    int warmupIterations = 2,
    Map<String, dynamic>? metadata,
  }) {
    return InfobitsBenchmark.instance.measureIterations(
      name,
      fn,
      iterations: iterations,
      warmupIterations: warmupIterations,
      metadata: metadata,
    );
  }

  /// Get benchmark report
  static String report({bool detailed = false}) {
    return InfobitsBenchmark.instance.generateReport(detailed: detailed);
  }

  /// Clear all benchmarks
  static void clear() {
    InfobitsBenchmark.instance.clear();
  }

  /// Get statistics for a specific benchmark
  static BenchmarkStatistics? getStatistics(String name) {
    return InfobitsBenchmark.instance.getStatistics(name);
  }
}
