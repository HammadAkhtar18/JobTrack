import 'package:flutter/material.dart';

void main() {
  runApp(const JobTrackApp());
}

class JobTrackApp extends StatelessWidget {
  const JobTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Track',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Welcome to Job Track'),
        ),
      ),
    );
  }
}
