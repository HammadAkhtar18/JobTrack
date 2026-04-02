import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:job_track/models/job_application.dart';

final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, List<JobApplication>>((ref) {
  final box = Hive.box<JobApplication>('applications');
  return ApplicationsNotifier(box);
});

class ApplicationsNotifier extends StateNotifier<List<JobApplication>> {
  ApplicationsNotifier(this._applicationsBox) : super(_applicationsBox.values.toList()) {
    _applicationsBox.listenable().addListener(_syncState);
  }

  final Box<JobApplication> _applicationsBox;

  List<JobApplication> getAll() {
    return _applicationsBox.values.toList();
  }

  List<JobApplication> getFilteredByStatus(String statusFilter) {
    final normalizedFilter = statusFilter.trim().toLowerCase();
    final applications = getAll();

    if (normalizedFilter.isEmpty || normalizedFilter == 'all') {
      return applications;
    }

    return applications
        .where((application) =>
            application.status.trim().toLowerCase() == normalizedFilter)
        .toList();
  }

  int get totalApplied =>
      state.where((application) => application.status.toLowerCase() == 'applied').length;

  int get totalInterviews =>
      state.where((application) => application.status.toLowerCase() == 'interview').length;

  int get totalOffers =>
      state.where((application) => application.status.toLowerCase() == 'offer').length;

  int get totalRejections =>
      state.where((application) => application.status.toLowerCase() == 'rejected').length;

  Future<void> addApplication(JobApplication application) async {
    await _applicationsBox.put(application.id, application);
    _syncState();
  }

  Future<void> updateApplication(JobApplication application) async {
    await _applicationsBox.put(application.id, application);
    _syncState();
  }

  Future<void> deleteApplication(String applicationId) async {
    await _applicationsBox.delete(applicationId);
    _syncState();
  }

  void _syncState() {
    state = _applicationsBox.values.toList();
  }

  @override
  void dispose() {
    _applicationsBox.listenable().removeListener(_syncState);
    super.dispose();
  }
}
