import 'package:flutter/material.dart';
import 'package:infobits/infobits.dart';

/// Example showing Infobits used for local logging only (no API key required)
void main() {
  // No API key needed for local logging!
  runWithInfobits(
    app: const MyApp(),
    // Optional: You can still customize logging behavior
    debug: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Logging Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    // Logging works without API key - logs to console only
    Logger.info('HomePage initialized');
    Logger.debug('Running in local-only mode (no API key)');

    // Analytics won't work without API key
    if (Infobits.canTrack) {
      // This won't execute in local-only mode
      InfobitsAnalytics.instance.startView('/home');
    } else {
      Logger.debug('Analytics not available - no API key provided');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    // Local logging works great!
    Logger.debug('Counter incremented to $_counter');
  }

  void _testLoggingLevels() {
    Logger.verbose('Verbose: Most detailed logging level');
    Logger.debug('Debug: Detailed information for debugging');
    Logger.info('Info: General informational messages');
    Logger.warn('Warning: Something unexpected but recoverable');
    Logger.error(
      'Error: Something went wrong',
      exception: Exception('Test error'),
    );
    Logger.fatal('Fatal: Critical error that might crash the app');
  }

  void _triggerError() {
    try {
      throw Exception('This is a test error');
    } catch (e, stack) {
      // Errors are logged locally without API key
      Logger.error(
        'Caught an error',
        exception: e,
        information: stack.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Local Logging Only'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Running without API key',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Local logging to console'),
                    const Text('✅ Error handling'),
                    const Text('✅ All log levels'),
                    const Text('❌ No server logging'),
                    const Text('❌ No analytics tracking'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _testLoggingLevels,
                  icon: const Icon(Icons.list),
                  label: const Text('Test Log Levels'),
                ),
                ElevatedButton.icon(
                  onPressed: _triggerError,
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Trigger Error'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show status
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Infobits Status'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Initialized: ${Infobits.isInitialized}'),
                            Text('Can Log: ${Infobits.canLog}'),
                            Text('Can Track: ${Infobits.canTrack}'),
                            const SizedBox(height: 10),
                            const Text(
                              'No API key provided, so only local logging is available.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('Check Status'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
