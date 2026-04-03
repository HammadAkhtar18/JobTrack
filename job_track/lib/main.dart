import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/screens/add_application_screen.dart';
import 'package:job_track/screens/applications_list_screen.dart';
import 'package:job_track/screens/dashboard_screen.dart';
import 'package:job_track/screens/settings_screen.dart';
import 'package:job_track/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveFlutter.init();
  Hive.registerAdapter(JobApplicationAdapter());
  await Hive.openBox<JobApplication>('applications');
  await NotificationService.instance.initialize();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

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
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final page = switch (settings.name) {
          '/add-application' => AddApplicationScreen(
              application: settings.arguments is JobApplication
                  ? settings.arguments as JobApplication
                  : null,
            ),
          '/applications' => const ApplicationsListScreen(),
          '/dashboard' => const DashboardScreen(),
          '/settings' => const SettingsScreen(),
          '/app-shell' => const _AppShell(),
          '/onboarding' => const OnboardingScreen(),
          _ => const SplashScreen(),
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      onboardingComplete ? '/app-shell' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.work_outline_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'JobTrack',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    (
      icon: Icons.track_changes_rounded,
      title: 'Track Every Application',
      description: 'Save job applications in one place and review them anytime.',
    ),
    (
      icon: Icons.query_stats_rounded,
      title: 'See Progress Clearly',
      description: 'Use dashboard insights to monitor statuses and interview momentum.',
    ),
    (
      icon: Icons.notifications_active_rounded,
      title: 'Stay on Top of Follow-Ups',
      description: 'Set reminders so important opportunities never slip through.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed('/app-shell');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            slide.icon,
                            size: 52,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: _currentPage == index ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
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
