import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:job_track/screens/applications_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockApplicationsBox extends Mock implements Box<JobApplication> {}

class MockBoxListenable extends Mock implements ValueListenable<Box<JobApplication>> {}

class FakeApplicationsNotifier extends ApplicationsNotifier {
  FakeApplicationsNotifier(this.store) : super(_buildBox(store));

  final List<JobApplication> store;
  final List<String> deletedIds = <String>[];

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
  Future<void> deleteApplication(String applicationId) async {
    deletedIds.add(applicationId);
    store.removeWhere((application) => application.id == applicationId);
    state = AsyncValue.data(List<JobApplication>.from(store));
  }
}

void _noop() {}

void main() {
  JobApplication app({
    required String id,
    required String company,
    required String title,
    required String status,
  }) {
    return JobApplication(
      id: id,
      companyName: company,
      jobTitle: title,
      jobType: 'Full-time',
      appliedDate: DateTime(2026, 1, 1).add(Duration(days: id.codeUnitAt(0))),
      status: status,
    );
  }

  Widget buildScreen(FakeApplicationsNotifier notifier) {
    return ProviderScope(
      overrides: [applicationsProvider.overrideWith((ref) => notifier)],
      child: const MaterialApp(home: ApplicationsListScreen()),
    );
  }

  testWidgets('filters applications by search query', (tester) async {
    final notifier = FakeApplicationsNotifier(<JobApplication>[
      app(id: 'a', company: 'Acme Corp', title: 'Flutter Dev', status: 'Applied'),
      app(id: 'b', company: 'Beta Inc', title: 'Backend Engineer', status: 'Interview'),
    ]);

    await tester.pumpWidget(buildScreen(notifier));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Acme');
    await tester.pumpAndSettle();

    expect(find.text('Acme Corp'), findsOneWidget);
    expect(find.text('Beta Inc'), findsNothing);
  });

  testWidgets('filters applications by status chip', (tester) async {
    final notifier = FakeApplicationsNotifier(<JobApplication>[
      app(id: 'a', company: 'Acme Corp', title: 'Flutter Dev', status: 'Applied'),
      app(id: 'b', company: 'Beta Inc', title: 'Backend Engineer', status: 'Interview'),
    ]);

    await tester.pumpWidget(buildScreen(notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Interview'));
    await tester.pumpAndSettle();

    expect(find.text('Beta Inc'), findsOneWidget);
    expect(find.text('Acme Corp'), findsNothing);
  });

  testWidgets('swipe to delete removes item and calls notifier', (tester) async {
    final notifier = FakeApplicationsNotifier(<JobApplication>[
      app(id: 'a', company: 'Acme Corp', title: 'Flutter Dev', status: 'Applied'),
      app(id: 'b', company: 'Beta Inc', title: 'Backend Engineer', status: 'Interview'),
    ]);

    await tester.pumpWidget(buildScreen(notifier));
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const ValueKey('a')), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(notifier.deletedIds, contains('a'));
    expect(find.text('Acme Corp'), findsNothing);
  });
}
