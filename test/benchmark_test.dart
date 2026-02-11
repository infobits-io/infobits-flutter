import 'package:flutter_test/flutter_test.dart';
import 'package:infobits/infobits.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Benchmark Tests', () {
    setUp(() {
      // Clear benchmarks before each test
      Benchmark.clear();
    });

    test('Simple benchmark measurement', () {
      final result = Benchmark.measure('test_operation', () {
        int sum = 0;
        for (int i = 0; i < 1000; i++) {
          sum += i;
        }
        return sum;
      });

      expect(result, equals(499500));

      // Check that benchmark was recorded
      final stats = Benchmark.getStatistics('test_operation');
      expect(stats, isNotNull);
      expect(stats!.results.length, equals(1));
    });

    test('Async benchmark measurement', () async {
      final result = await Benchmark.measureAsync('async_test', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'completed';
      });

      expect(result, equals('completed'));

      final stats = Benchmark.getStatistics('async_test');
      expect(stats, isNotNull);
      expect(stats!.results.length, equals(1));
      expect(
        stats.results.first.duration.inMilliseconds,
        greaterThanOrEqualTo(10),
      );
    });

    test('Manual start/stop benchmark', () async {
      final timer = Benchmark.start('manual_test');

      await Future.delayed(const Duration(milliseconds: 50));

      final result = Benchmark.stop(timer);

      expect(result.name, equals('manual_test'));
      expect(result.duration.inMilliseconds, greaterThanOrEqualTo(50));
      expect(result.id, equals(timer.id));
    });

    test('Stop benchmark by name', () async {
      Benchmark.start('named_test');

      await Future.delayed(const Duration(milliseconds: 20));

      final result = Benchmark.stopByName('named_test');

      expect(result, isNotNull);
      expect(result!.name, equals('named_test'));
      expect(result.duration.inMilliseconds, greaterThanOrEqualTo(20));
    });

    test('Nested benchmarks with metadata', () async {
      final parentTimer = Benchmark.start('parent_operation');

      // Child benchmark 1
      final child1Timer = Benchmark.start(
        'child_1',
        metadata: {'index': 1, 'parentId': parentTimer.id},
      );
      await Future.delayed(const Duration(milliseconds: 10));
      Benchmark.stop(child1Timer);

      // Child benchmark 2
      final child2Timer = Benchmark.start(
        'child_2',
        metadata: {'index': 2, 'parentId': parentTimer.id},
      );
      await Future.delayed(const Duration(milliseconds: 20));
      Benchmark.stop(child2Timer);

      final parentResult = Benchmark.stop(parentTimer);

      expect(parentResult.name, equals('parent_operation'));
      expect(parentResult.metadata, isNotNull);

      // Check that sub-benchmarks were recorded
      final subBenchmarks = parentResult.metadata!['sub_benchmarks'] as List;
      expect(subBenchmarks.length, equals(2));
    });

    test('Benchmark with error handling', () {
      expect(() {
        Benchmark.measure('error_test', () {
          throw Exception('Test error');
        });
      }, throwsException);

      // Error should still be recorded
      final stats = Benchmark.getStatistics('error_test');
      expect(stats, isNotNull);
      expect(stats!.results.length, equals(1));
      expect(stats.results.first.metadata?['error'], contains('Test error'));
    });

    test('Statistical benchmarks with iterations', () async {
      final stats = await Benchmark.measureIterations(
        'iteration_test',
        () async {
          await Future.delayed(const Duration(milliseconds: 5));
        },
        iterations: 5,
        warmupIterations: 2,
      );

      expect(stats.name, equals('iteration_test'));
      expect(stats.results.length, equals(5));

      // All durations should be at least 5ms
      for (final result in stats.results) {
        expect(result.duration.inMilliseconds, greaterThanOrEqualTo(5));
      }

      // Statistics should be calculated
      expect(stats.min.inMilliseconds, greaterThanOrEqualTo(5));
      expect(stats.max.inMilliseconds, greaterThanOrEqualTo(5));
      expect(stats.mean.inMilliseconds, greaterThanOrEqualTo(5));
      expect(stats.median.inMilliseconds, greaterThanOrEqualTo(5));
    });

    test('Benchmark report generation', () {
      // Add some benchmarks
      Benchmark.measure('report_test_1', () => 1);
      Benchmark.measure('report_test_1', () => 2);
      Benchmark.measure('report_test_2', () => 3);

      final report = Benchmark.report();

      expect(report, contains('Benchmark Report'));
      expect(report, contains('Total benchmarks: 3'));
      expect(report, contains('report_test_1'));
      expect(report, contains('report_test_2'));
      expect(report, contains('count=2')); // report_test_1 has 2 results
      expect(report, contains('count=1')); // report_test_2 has 1 result
    });

    test('Detailed report generation', () {
      Benchmark.measure(
        'detailed_test',
        () => 'result',
        metadata: {'key': 'value'},
      );

      final report = Benchmark.report(detailed: true);

      expect(report, contains('detailed_test'));
      // In detailed mode, individual results should be shown
      expect(report, contains('detailed_test:'));
    });

    test('Clear benchmarks', () {
      Benchmark.measure('clear_test', () => 1);

      var stats = Benchmark.getStatistics('clear_test');
      expect(stats, isNotNull);

      Benchmark.clear();

      stats = Benchmark.getStatistics('clear_test');
      expect(stats, isNull);

      final report = Benchmark.report();
      expect(report, contains('Total benchmarks: 0'));
    });

    test('BenchmarkResult toString formatting', () {
      // Test microseconds formatting
      final microResult = BenchmarkResult(
        name: 'micro_test',
        duration: const Duration(microseconds: 500),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      expect(microResult.toString(), contains('500μs'));

      // Test milliseconds formatting
      final milliResult = BenchmarkResult(
        name: 'milli_test',
        duration: const Duration(milliseconds: 50),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      expect(milliResult.toString(), contains('50.00ms'));

      // Test seconds formatting
      final secResult = BenchmarkResult(
        name: 'sec_test',
        duration: const Duration(seconds: 2, milliseconds: 500),
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      expect(secResult.toString(), contains('2.50s'));
    });

    test('BenchmarkResult toJson', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(milliseconds: 100));

      final result = BenchmarkResult(
        name: 'json_test',
        duration: const Duration(milliseconds: 100),
        startTime: startTime,
        endTime: endTime,
        metadata: {'key': 'value'},
        parentId: 'parent123',
      );

      final json = result.toJson();

      expect(json['name'], equals('json_test'));
      expect(json['duration_ms'], equals(100));
      expect(json['duration_us'], equals(100000));
      expect(json['start_time'], equals(startTime.toIso8601String()));
      expect(json['end_time'], equals(endTime.toIso8601String()));
      expect(json['metadata'], equals({'key': 'value'}));
      expect(json['parent_id'], equals('parent123'));
      expect(json['id'], isNotNull);
    });

    test('BenchmarkStatistics calculations', () {
      // Create benchmarks with known durations
      final results = [
        BenchmarkResult(
          name: 'stats_test',
          duration: const Duration(milliseconds: 10),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        ),
        BenchmarkResult(
          name: 'stats_test',
          duration: const Duration(milliseconds: 20),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        ),
        BenchmarkResult(
          name: 'stats_test',
          duration: const Duration(milliseconds: 30),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        ),
        BenchmarkResult(
          name: 'stats_test',
          duration: const Duration(milliseconds: 40),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        ),
        BenchmarkResult(
          name: 'stats_test',
          duration: const Duration(milliseconds: 50),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
        ),
      ];

      final stats = BenchmarkStatistics(name: 'stats_test', results: results);

      expect(stats.min.inMilliseconds, equals(10));
      expect(stats.max.inMilliseconds, equals(50));
      expect(stats.mean.inMilliseconds, equals(30));
      expect(stats.median.inMilliseconds, equals(30));
    });

    test('Active timers tracking', () {
      final timer1 = Benchmark.start('active_test_1');
      final timer2 = Benchmark.start('active_test_2');

      final activeTimers = InfobitsBenchmark.instance.activeTimers;
      expect(activeTimers.length, equals(2));

      Benchmark.stop(timer1);
      expect(InfobitsBenchmark.instance.activeTimers.length, equals(1));

      Benchmark.stop(timer2);
      expect(InfobitsBenchmark.instance.activeTimers.length, equals(0));
    });

    test('Grouped benchmarks', () {
      Benchmark.measure('group_a', () => 1);
      Benchmark.measure('group_a', () => 2);
      Benchmark.measure('group_b', () => 3);

      final grouped = InfobitsBenchmark.instance.groupedBenchmarks;

      expect(grouped.keys.length, equals(2));
      expect(grouped['group_a']?.length, equals(2));
      expect(grouped['group_b']?.length, equals(1));
    });
  });
}
