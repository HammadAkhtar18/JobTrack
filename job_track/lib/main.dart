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
    const seedColor = Color(0xFF6C63FF);
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Job Track',
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.copyWith(
          bodySmall: baseTheme.textTheme.bodySmall?.copyWith(fontSize: 13),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(fontSize: 15),
          bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(fontSize: 17),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ).copyWith(
        textTheme: ThemeData(brightness: Brightness.dark).textTheme.copyWith(
              bodySmall: ThemeData(brightness: Brightness.dark)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 13),
              bodyMedium: ThemeData(brightness: Brightness.dark)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 15),
              bodyLarge: ThemeData(brightness: Brightness.dark)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontSize: 17),
            ),
      ),
      themeMode: ThemeMode.system,
      home: const _AppShell(),
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          '/add-application' => AddApplicationScreen(
              application: settings.arguments is JobApplication
                  ? settings.arguments as JobApplication
                  : null,
            ),
          '/applications' => const ApplicationsListScreen(),
          '/dashboard' => const DashboardScreen(),
          _ => const _AppShell(),
        };

        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: page,
          ),
          transitionsBuilder: (_, animation, __, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
        );
      },
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    ApplicationsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Applications',
          ),
        ],
      ),
    );
  }
}
