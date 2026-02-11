import 'package:flutter/material.dart';
import 'package:infobits/infobits.dart';

void main() {
  // Run app with Infobits initialization and error handling
  runWithInfobits(
    app: const MyApp(),
    apiKey: 'your-api-key-here',
    // domain is optional - will be extracted from package name if not provided
    // domain: 'example.app',  // You can still override it if needed
    debug: true,
    onError: (error, stack) {
      // Optional: Additional custom error handling
      // The error has already been logged to Infobits
      // You can add custom logic here like showing a dialog,
      // sending to another service, etc.
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infobits Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
      navigatorObservers: [InfobitsAnalyticsObserver()],
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

    // Safe initialization checks
    if (Infobits.canTrack) {
      InfobitsAnalytics.instance.startView('/home');
    }

    if (Infobits.canLog) {
      Logger.info('HomePage initialized');
      Logger.debug(
        'Infobits status - Initialized: ${Infobits.isInitialized}, Can log: ${Infobits.canLog}, Can track: ${Infobits.canTrack}',
      );
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    // Track custom analytics event (using startView as a workaround)
    InfobitsAnalytics.instance.startView(
      '/events/button_click?value=$_counter',
    );

    // Log the action
    Logger.debug('Counter incremented to $_counter');
  }

  void _triggerError() {
    try {
      // Intentionally trigger an error for demonstration
      throw Exception('This is a test error for demonstration purposes');
    } catch (e, stackTrace) {
      Logger.error(
        'Error triggered',
        exception: e,
        information: stackTrace.toString(),
      );

      // Also track as an analytics event
      InfobitsAnalytics.instance.startView('/events/error_triggered');
    }
  }

  void _testLoggingLevels() {
    // Check if logging is available before using it
    if (Infobits.canLog) {
      Logger.verbose('This is a verbose message');
      Logger.debug('This is a debug message');
      Logger.info('This is an info message');
      Logger.warn('This is a warning message');
      Logger.error('This is an error message');
      Logger.fatal('This is a fatal message');
    } else {
      // Fallback if Infobits is not initialized
      debugPrint('Infobits logging is not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Infobits Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Infobits Package Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _testLoggingLevels,
              icon: const Icon(Icons.list),
              label: const Text('Test Logging Levels'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _triggerError,
              icon: const Icon(Icons.error_outline),
              label: const Text('Trigger Test Error'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecondPage(),
                    settings: const RouteSettings(name: '/second'),
                  ),
                );
              },
              icon: const Icon(Icons.navigate_next),
              label: const Text('Navigate to Second Page'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsPage(),
                    settings: const RouteSettings(name: '/analytics'),
                  ),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('Analytics Demo'),
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

  @override
  void dispose() {
    InfobitsAnalytics.instance.endView('/home');
    super.dispose();
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  void initState() {
    super.initState();
    Logger.info('SecondPage opened');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This is the second page',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Logger.debug('Navigating back from SecondPage');
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _propertyValueController =
      TextEditingController();

  void _trackCustomEvent() {
    final eventName = _eventNameController.text.trim();
    final propertyValue = _propertyValueController.text.trim();

    if (eventName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event name')),
      );
      return;
    }

    // Use startView to track custom events
    String eventPath = '/events/$eventName';
    if (propertyValue.isNotEmpty) {
      eventPath += '?value=$propertyValue';
    }

    InfobitsAnalytics.instance.startView(eventPath);
    Logger.info('Custom event tracked: $eventName', information: propertyValue);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Event "$eventName" tracked!')));

    // Clear fields
    _eventNameController.clear();
    _propertyValueController.clear();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _propertyValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Track Custom Event',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., user_signup',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _propertyValueController,
              decoration: const InputDecoration(
                labelText: 'Property Value (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., premium',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _trackCustomEvent,
              child: const Text('Track Event'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Pre-defined Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    InfobitsAnalytics.instance.startView('/events/app_opened');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tracked: app_opened')),
                    );
                  },
                  child: const Text('App Opened'),
                ),
                ElevatedButton(
                  onPressed: () {
                    InfobitsAnalytics.instance.startView(
                      '/events/purchase?amount=99.99&currency=USD',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tracked: purchase')),
                    );
                  },
                  child: const Text('Purchase'),
                ),
                ElevatedButton(
                  onPressed: () {
                    InfobitsAnalytics.instance.startView(
                      '/events/share?platform=twitter&content=article',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tracked: share')),
                    );
                  },
                  child: const Text('Share'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Test crash functionality (commented out for safety)
                    // InfobitsLogging.instance.crash('Test crash from example app');
                    Logger.fatal(
                      'Simulated fatal error',
                      exception: 'User triggered fatal log',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fatal error logged (app not crashed)'),
                      ),
                    );
                  },
                  child: const Text('Log Fatal Error'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
