import 'package:flutter/material.dart';
import 'package:infobits/infobits.dart';

/// Example showing manual initialization for more control
void main() async {
  // Manual initialization gives you more control over the initialization process
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Infobits manually
    await Infobits.initialize(
      apiKey: 'your-api-key-here',
      domain: 'example.app',
      debug: true,
      analyticsEnabled: true,
      loggingEnabled: true,
    );

    Logger.info('Infobits initialized successfully');
  } catch (e) {
    // Handle initialization errors
    debugPrint('Failed to initialize Infobits: $e');
  }

  // Run the app
  // Note: Without runWithInfobits, zone errors won't be caught automatically
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infobits Manual Init Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
      navigatorObservers: [InfobitsAnalyticsObserver()],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Initialization Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This example uses manual Infobits initialization',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Check if Infobits is available before using
                if (Infobits.canLog) {
                  Logger.info('Button pressed');
                }
                if (Infobits.canTrack) {
                  InfobitsAnalytics.instance.startView('/button_press');
                }
              },
              child: const Text('Test Logging'),
            ),
            const SizedBox(height: 20),
            Text('Infobits initialized: ${Infobits.isInitialized}'),
            Text('Can log: ${Infobits.canLog}'),
            Text('Can track: ${Infobits.canTrack}'),
          ],
        ),
      ),
    );
  }
}
