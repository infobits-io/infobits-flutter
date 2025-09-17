import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infobits/infobits.dart';

void main() {
  runWithInfobits(
    app: const BenchmarkExampleApp(),
    domain: 'benchmark.example',
    debug: true,
  );
}

class BenchmarkExampleApp extends StatelessWidget {
  const BenchmarkExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Benchmark Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BenchmarkExamplePage(),
    );
  }
}

class BenchmarkExamplePage extends StatefulWidget {
  const BenchmarkExamplePage({super.key});

  @override
  State<BenchmarkExamplePage> createState() => _BenchmarkExamplePageState();
}

class _BenchmarkExamplePageState extends State<BenchmarkExamplePage> {
  String _output = 'Press a button to run benchmarks';
  bool _isRunning = false;

  /// Example: Simple synchronous benchmark
  void _runSimpleBenchmark() {
    setState(() {
      _isRunning = true;
      _output = 'Running simple benchmark...';
    });

    // Benchmark a simple calculation
    final result = Benchmark.measure('fibonacci_calculation', () {
      return _fibonacci(35);
    }, metadata: {'n': 35});

    setState(() {
      _isRunning = false;
      _output = 'Simple Benchmark Result:\n$result';
    });
  }

  /// Example: Async benchmark
  Future<void> _runAsyncBenchmark() async {
    setState(() {
      _isRunning = true;
      _output = 'Running async benchmark...';
    });

    // Benchmark an async operation
    final result = await Benchmark.measureAsync('api_simulation', () async {
      await Future.delayed(Duration(milliseconds: Random().nextInt(500) + 500));
      return 'API Response';
    }, metadata: {'endpoint': '/api/test'});

    setState(() {
      _isRunning = false;
      _output = 'Async Benchmark Result:\n$result';
    });
  }

  /// Example: Nested benchmarks
  Future<void> _runNestedBenchmarks() async {
    setState(() {
      _isRunning = true;
      _output = 'Running nested benchmarks...';
    });

    final mainTimer = Benchmark.start('main_operation');
    
    // Sub-benchmark 1
    final subTimer1 = Benchmark.start('data_preparation', 
      metadata: {'parent': mainTimer.id});
    await Future.delayed(const Duration(milliseconds: 100));
    final subResult1 = Benchmark.stop(subTimer1);
    
    // Sub-benchmark 2
    final subTimer2 = Benchmark.start('processing', 
      metadata: {'parent': mainTimer.id});
    await Future.delayed(const Duration(milliseconds: 200));
    final subResult2 = Benchmark.stop(subTimer2);
    
    // Sub-benchmark 3
    final subTimer3 = Benchmark.start('cleanup', 
      metadata: {'parent': mainTimer.id});
    await Future.delayed(const Duration(milliseconds: 50));
    final subResult3 = Benchmark.stop(subTimer3);
    
    final mainResult = Benchmark.stop(mainTimer);

    setState(() {
      _isRunning = false;
      _output = '''Nested Benchmarks:
Main: $mainResult
  - $subResult1
  - $subResult2
  - $subResult3''';
    });
  }

  /// Example: Statistical benchmarks
  Future<void> _runStatisticalBenchmark() async {
    setState(() {
      _isRunning = true;
      _output = 'Running statistical benchmark...';
    });

    // Run multiple iterations for statistics
    final stats = await Benchmark.measureIterations(
      'sort_algorithm',
      () async {
        final list = List.generate(10000, (i) => Random().nextInt(10000));
        list.sort();
      },
      iterations: 20,
      warmupIterations: 3,
      metadata: {'array_size': 10000},
    );

    setState(() {
      _isRunning = false;
      _output = '''Statistical Benchmark:
$stats

Min: ${stats.min.inMilliseconds}ms
Max: ${stats.max.inMilliseconds}ms
Mean: ${stats.mean.inMilliseconds}ms
Median: ${stats.median.inMilliseconds}ms''';
    });
  }

  /// Example: Complex benchmark with multiple operations
  Future<void> _runComplexBenchmark() async {
    setState(() {
      _isRunning = true;
      _output = 'Running complex benchmark suite...';
    });

    // Clear previous benchmarks
    Benchmark.clear();

    // Benchmark 1: String operations
    await Benchmark.measureAsync('string_operations', () async {
      final buffer = StringBuffer();
      for (int i = 0; i < 10000; i++) {
        buffer.write('Item $i, ');
      }
      return buffer.toString();
    });

    // Benchmark 2: List operations
    Benchmark.measure('list_operations', () {
      final list = <int>[];
      for (int i = 0; i < 10000; i++) {
        list.add(i * 2);
      }
      return list.where((n) => n % 3 == 0).toList();
    });

    // Benchmark 3: Map operations
    Benchmark.measure('map_operations', () {
      final map = <String, int>{};
      for (int i = 0; i < 5000; i++) {
        map['key_$i'] = i * i;
      }
      return map.values.where((v) => v > 1000).toList();
    });

    // Benchmark 4: Math operations
    for (int i = 0; i < 5; i++) {
      Benchmark.measure('math_operations', () {
        double result = 1.0;
        for (int j = 0; j < 10000; j++) {
          result = sqrt(result * 2.5 + j);
        }
        return result;
      });
    }

    // Generate detailed report
    final report = Benchmark.report(detailed: false);

    setState(() {
      _isRunning = false;
      _output = report;
    });
  }

  /// Example: Show all statistics
  void _showStatistics() {
    final stats = <String>[];
    
    // Get statistics for specific benchmarks
    final mathStats = Benchmark.getStatistics('math_operations');
    if (mathStats != null) {
      stats.add('Math Operations Stats:');
      stats.add(mathStats.toString());
      stats.add('');
    }

    final sortStats = Benchmark.getStatistics('sort_algorithm');
    if (sortStats != null) {
      stats.add('Sort Algorithm Stats:');
      stats.add(sortStats.toString());
      stats.add('');
    }

    // Show full report
    stats.add('Full Report:');
    stats.add(Benchmark.report(detailed: true));

    setState(() {
      _output = stats.join('\n');
    });
  }

  // Helper function for fibonacci
  int _fibonacci(int n) {
    if (n <= 1) return n;
    return _fibonacci(n - 1) + _fibonacci(n - 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Infobits Benchmark Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _output,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runSimpleBenchmark,
                  child: const Text('Simple Benchmark'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runAsyncBenchmark,
                  child: const Text('Async Benchmark'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runNestedBenchmarks,
                  child: const Text('Nested Benchmarks'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runStatisticalBenchmark,
                  child: const Text('Statistical Benchmark'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runComplexBenchmark,
                  child: const Text('Complex Suite'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _showStatistics,
                  child: const Text('Show Statistics'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : () {
                    Benchmark.clear();
                    setState(() {
                      _output = 'Benchmarks cleared';
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}