import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:job_track/models/job_application.dart';

final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, AsyncValue<List<JobApplication>>>((ref) {
  final box = Hive.box<JobApplication>('applications');
  return ApplicationsNotifier(box);
});

class ApplicationsNotifier extends StateNotifier<AsyncValue<List<JobApplication>>> {
  ApplicationsNotifier(this._applicationsBox)
      : _boxListenable = _applicationsBox.listenable(),
        super(const AsyncValue.loading()) {
    _loadInitialState();
  }

  final Box<JobApplication> _applicationsBox;
  final ValueListenable<Box<JobApplication>> _boxListenable;
  bool _isListening = false;

  void _loadInitialState() {
    try {
      state = AsyncValue.data(_applicationsBox.values.toList());
      _boxListenable.addListener(_syncState);
      _isListening = true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<JobApplication> getAll() {
    final stateValue = state.valueOrNull;
    if (stateValue != null) {
      return stateValue;
    }

    try {
      return _applicationsBox.values.toList();
    } catch (_) {
      return <JobApplication>[];
    }
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
      getAll().where((application) => application.status.toLowerCase() == 'applied').length;

  int get totalInterviews =>
      getAll().where((application) => application.status.toLowerCase() == 'interview').length;

  int get totalOffers =>
      getAll().where((application) => application.status.toLowerCase() == 'offer').length;

  int get totalRejections =>
      getAll().where((application) => application.status.toLowerCase() == 'rejected').length;

  Future<void> addApplication(JobApplication application) async {
    try {
      await _applicationsBox.put(application.id, application);
      _syncState();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateApplication(JobApplication application) async {
    try {
      await _applicationsBox.put(application.id, application);
      _syncState();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      await _applicationsBox.delete(applicationId);
      _syncState();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> clearAllApplications() async {
    try {
      await _applicationsBox.clear();
      _syncState();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> replaceAllApplications(List<JobApplication> applications) async {
    try {
      await _applicationsBox.clear();
      if (applications.isNotEmpty) {
        await _applicationsBox.putAll({
          for (final application in applications) application.id: application,
        });
      }
      _syncState();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void _syncState() {
    try {
      state = AsyncValue.data(_applicationsBox.values.toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _boxListenable.removeListener(_syncState);
    }
    super.dispose();
  }
}
