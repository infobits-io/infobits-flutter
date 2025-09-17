import 'package:flutter/material.dart';
import 'package:infobits/infobits.dart';

/// Simplest possible Infobits integration - local logging only
void main() {
  // Just one line! No API key needed for local logging
  runWithInfobits(app: const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Infobits Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Infobits Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Infobits is automatically tracking:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text('✅ All errors and crashes'),
            const Text('✅ Screen views'),
            const Text('✅ App lifecycle'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // This will be automatically logged
                throw Exception('Test error - will be caught by Infobits');
              },
              child: const Text('Trigger Test Error'),
            ),
          ],
        ),
      ),
    );
  }
}
