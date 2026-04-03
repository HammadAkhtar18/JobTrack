import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/screens/add_application_screen.dart';
import 'package:job_track/screens/applications_list_screen.dart';
import 'package:job_track/screens/dashboard_screen.dart';
import 'package:job_track/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveFlutter.init();
  Hive.registerAdapter(JobApplicationAdapter());
  await Hive.openBox<JobApplication>('applications');
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Track',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
      routes: {
        '/add-application': (context) => const AddApplicationScreen(),
        '/applications': (context) => const ApplicationsListScreen(),
      },
    );
  }
}
