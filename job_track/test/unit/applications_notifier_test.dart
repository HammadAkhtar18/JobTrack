import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockApplicationsBox extends Mock implements Box<JobApplication> {}

class MockBoxListenable extends Mock implements ValueListenable<Box<JobApplication>> {}

void _noop() {}

void main() {
  late MockApplicationsBox box;
  late MockBoxListenable listenable;
  late Map<String, JobApplication> store;

  JobApplication makeApplication({
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
      appliedDate: DateTime(2026, 1, 1),
      status: status,
    );
  }

  setUpAll(() {
    registerFallbackValue(_noop);
    registerFallbackValue(JobApplication(
      id: 'fallback',
      companyName: 'Fallback Co',
      jobTitle: 'Fallback Job',
      jobType: 'Full-time',
      appliedDate: DateTime(2026, 1, 1),
      status: 'Applied',
    ));
    registerFallbackValue(<String, JobApplication>{});
  });

  setUp(() {
    box = MockApplicationsBox();
    listenable = MockBoxListenable();
    store = <String, JobApplication>{};

    when(() => box.listenable()).thenReturn(listenable);
    when(() => listenable.addListener(any())).thenAnswer((_) {});
    when(() => listenable.removeListener(any())).thenAnswer((_) {});
    when(() => listenable.value).thenReturn(box);
    when(() => box.values).thenAnswer((_) => store.values);

    when(() => box.put(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as JobApplication;
      store[key] = value;
    });

    when(() => box.putAll(any())).thenAnswer((invocation) async {
      final values = invocation.positionalArguments[0] as Map<String, JobApplication>;
      store.addAll(values);
    });

    when(() => box.delete(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      store.remove(key);
    });

    when(() => box.clear()).thenAnswer((_) async {
      store.clear();
      return 0;
    });
  });

  group('ApplicationsNotifier operations', () {
    test('add, update, and delete mutate state', () async {
      final notifier = ApplicationsNotifier(box);
      final initial = makeApplication(
        id: 'app-1',
        company: 'Acme',
        title: 'Engineer',
        status: 'Applied',
      );

      await notifier.addApplication(initial);
      expect(notifier.state.valueOrNull, hasLength(1));
      expect(notifier.state.valueOrNull!.first.companyName, 'Acme');

      final updated = initial.copyWith(status: 'Interview');
      await notifier.updateApplication(updated);

      expect(notifier.state.valueOrNull, hasLength(1));
      expect(notifier.state.valueOrNull!.first.status, 'Interview');

      await notifier.deleteApplication(initial.id);
      expect(notifier.state.valueOrNull, isEmpty);

      verify(() => box.put(initial.id, initial)).called(1);
      verify(() => box.put(updated.id, updated)).called(1);
      verify(() => box.delete(initial.id)).called(1);

      notifier.dispose();
    });

    test('filters applications by normalized status', () {
      store['1'] = makeApplication(
        id: '1',
        company: 'Alpha',
        title: 'Dev',
        status: 'Applied',
      );
      store['2'] = makeApplication(
        id: '2',
        company: 'Beta',
        title: 'Dev',
        status: 'Interview',
      );

      final notifier = ApplicationsNotifier(box);

      expect(notifier.getFilteredByStatus('all'), hasLength(2));
      expect(notifier.getFilteredByStatus(' interview '), hasLength(1));
      expect(notifier.getFilteredByStatus('interview').first.id, '2');

      notifier.dispose();
    });

    test('computes totals by status', () {
      store['1'] = makeApplication(id: '1', company: 'A', title: 'T1', status: 'Applied');
      store['2'] = makeApplication(id: '2', company: 'B', title: 'T2', status: 'Interview');
      store['3'] = makeApplication(id: '3', company: 'C', title: 'T3', status: 'Offer');
      store['4'] = makeApplication(id: '4', company: 'D', title: 'T4', status: 'Rejected');
      store['5'] = makeApplication(id: '5', company: 'E', title: 'T5', status: 'Applied');

      final notifier = ApplicationsNotifier(box);

      expect(notifier.totalApplied, 2);
      expect(notifier.totalInterviews, 1);
      expect(notifier.totalOffers, 1);
      expect(notifier.totalRejections, 1);

      notifier.dispose();
    });
  });
}
