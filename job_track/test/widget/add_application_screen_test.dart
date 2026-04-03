import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:job_track/screens/add_application_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockApplicationsBox extends Mock implements Box<JobApplication> {}

class MockBoxListenable extends Mock implements ValueListenable<Box<JobApplication>> {}

class FakeApplicationsNotifier extends ApplicationsNotifier {
  FakeApplicationsNotifier(this.store) : super(_buildBox(store));

  final List<JobApplication> store;
  int addCalls = 0;
  int updateCalls = 0;

  static Box<JobApplication> _buildBox(List<JobApplication> store) {
    final box = MockApplicationsBox();
    final listenable = MockBoxListenable();
    when(() => box.listenable()).thenReturn(listenable);
    when(() => listenable.addListener(any())).thenAnswer((_) {});
    when(() => listenable.removeListener(any())).thenAnswer((_) {});
    when(() => listenable.value).thenReturn(box);
    when(() => box.values).thenAnswer((_) => store);
    return box;
  }

  @override
  Future<void> addApplication(JobApplication application) async {
    addCalls += 1;
    store.add(application);
    state = AsyncValue.data(List<JobApplication>.from(store));
  }

  @override
  Future<void> updateApplication(JobApplication application) async {
    updateCalls += 1;
    final index = store.indexWhere((element) => element.id == application.id);
    if (index >= 0) {
      store[index] = application;
    }
    state = AsyncValue.data(List<JobApplication>.from(store));
  }
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void _noop() {}

void main() {
  setUpAll(() {
    registerFallbackValue(_noop);
    registerFallbackValue(FakeRoute());
  });

  Widget buildScreen({
    required FakeApplicationsNotifier notifier,
    JobApplication? application,
    NavigatorObserver? observer,
  }) {
    return ProviderScope(
      overrides: [
        applicationsProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        navigatorObservers: observer == null ? const [] : [observer],
        home: AddApplicationScreen(application: application),
      ),
    );
  }

  testWidgets('shows validation errors when required fields are empty', (tester) async {
    final notifier = FakeApplicationsNotifier(<JobApplication>[]);

    await tester.pumpWidget(buildScreen(notifier: notifier));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Company name is required'), findsOneWidget);
    expect(find.text('Job title is required'), findsOneWidget);
    expect(notifier.addCalls, 0);
  });

  testWidgets('shows snackbar when follow-up date is in the past', (tester) async {
    final notifier = FakeApplicationsNotifier(<JobApplication>[]);
    final application = JobApplication(
      id: 'existing',
      companyName: 'Acme',
      jobTitle: 'Engineer',
      jobType: 'Full-time',
      appliedDate: DateTime(2026, 1, 2),
      status: 'Applied',
      followUpDate: DateTime.now().subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(buildScreen(notifier: notifier, application: application));

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Follow-up date is in the past'), findsOneWidget);
    expect(notifier.updateCalls, 0);
  });

  testWidgets('save flow adds application and pops route', (tester) async {
    final notifier = FakeApplicationsNotifier(<JobApplication>[]);
    final observer = MockNavigatorObserver();

    await tester.pumpWidget(buildScreen(notifier: notifier, observer: observer));

    await tester.enterText(find.widgetWithText(TextFormField, 'Company name'), 'Acme');
    await tester.enterText(find.widgetWithText(TextFormField, 'Job title'), 'Mobile Engineer');

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(notifier.addCalls, 1);
    verify(() => observer.didPop(any(), any())).called(1);
  });
}
