import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:uuid/uuid.dart';

class AddApplicationScreen extends ConsumerStatefulWidget {
  const AddApplicationScreen({
    super.key,
    this.application,
  });

  final JobApplication? application;

  @override
  ConsumerState<AddApplicationScreen> createState() => _AddApplicationScreenState();
}

class _AddApplicationScreenState extends ConsumerState<AddApplicationScreen> {
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyNameController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _jobTypeController;
  late final TextEditingController _statusController;
  late final TextEditingController _applicationUrlController;
  late final TextEditingController _notesController;
  late final TextEditingController _salaryExpectationController;
  DateTime? _appliedDate;
  DateTime? _followUpDate;

  @override
  void initState() {
    super.initState();
    final application = widget.application;
    _companyNameController = TextEditingController(text: application?.companyName ?? '');
    _jobTitleController = TextEditingController(text: application?.jobTitle ?? '');
    _jobTypeController = TextEditingController(text: application?.jobType ?? 'Full-time');
    _statusController = TextEditingController(text: application?.status ?? 'Applied');
    _applicationUrlController = TextEditingController(text: application?.applicationUrl ?? '');
    _notesController = TextEditingController(text: application?.notes ?? '');
    _salaryExpectationController =
        TextEditingController(text: application?.salaryExpectation ?? '');
    _appliedDate = application?.appliedDate ?? DateTime.now();
    _followUpDate = application?.followUpDate;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _jobTypeController.dispose();
    _statusController.dispose();
    _applicationUrlController.dispose();
    _notesController.dispose();
    _salaryExpectationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editingApplication =
        widget.application ?? ModalRoute.of(context)?.settings.arguments as JobApplication?;

    return Scaffold(
      appBar: AppBar(
        title: Text(editingApplication == null ? 'Add Application' : 'Edit Application'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _companyNameController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jobTitleController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Job title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Job title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jobTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Job type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _applicationUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Application URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final normalized = (value ?? '').trim();
                    if (normalized.isEmpty) {
                      return null;
                    }
                    final uri = Uri.tryParse(normalized);
                    final isValid =
                        uri != null && uri.hasScheme && uri.hasAuthority;
                    if (!isValid) {
                      return 'Enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salaryExpectationController,
                  decoration: const InputDecoration(
                    labelText: 'Salary expectation',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Applied date'),
                  subtitle: Text(
                    _appliedDate == null
                        ? 'Not set'
                        : '${_appliedDate!.year}-${_appliedDate!.month.toString().padLeft(2, '0')}-${_appliedDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickAppliedDate,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Follow-up date'),
                  subtitle: Text(
                    _followUpDate == null
                        ? 'Not set'
                        : '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (_followUpDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _followUpDate = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickFollowUpDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _saveApplication(context, ref, editingApplication),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveApplication(
    BuildContext context,
    WidgetRef ref,
    JobApplication? editingApplication,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final companyName = _companyNameController.text.trim();
    final jobTitle = _jobTitleController.text.trim();
    final jobType = _jobTypeController.text.trim();
    final status = _toTitleCase(_statusController.text.trim());
    final applicationUrlValue = _applicationUrlController.text.trim();
    final notesValue = _notesController.text.trim();
    final salaryExpectationValue = _salaryExpectationController.text.trim();
    final followUpDate = _followUpDate;
    final appliedDate = _appliedDate ?? DateTime.now();

    if (followUpDate != null &&
        DateUtils.dateOnly(followUpDate).isBefore(DateUtils.dateOnly(DateTime.now()))) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Follow-up date is in the past')),
        );
      return;
    }

    setState(() => _isSaving = true);
    final notifier = ref.read(applicationsProvider.notifier);

    try {
      if (editingApplication != null) {
        await notifier.updateApplication(
          editingApplication.copyWith(
            companyName: companyName,
            jobTitle: jobTitle,
            jobType: jobType.isEmpty ? 'Full-time' : jobType,
            status: status.isEmpty ? 'Applied' : status,
            applicationUrl: applicationUrlValue.isEmpty ? null : applicationUrlValue,
            notes: notesValue.isEmpty ? null : notesValue,
            followUpDate: followUpDate,
            salaryExpectation:
                salaryExpectationValue.isEmpty ? null : salaryExpectationValue,
            appliedDate: appliedDate,
          ),
        );
      } else {
        await notifier.addApplication(
          JobApplication(
            id: const Uuid().v4(),
            companyName: companyName,
            jobTitle: jobTitle,
            jobType: jobType.isEmpty ? 'Full-time' : jobType,
            appliedDate: appliedDate,
            status: status.isEmpty ? 'Applied' : status,
            applicationUrl: applicationUrlValue.isEmpty ? null : applicationUrlValue,
            notes: notesValue.isEmpty ? null : notesValue,
            followUpDate: followUpDate,
            salaryExpectation: salaryExpectationValue.isEmpty ? null : salaryExpectationValue,
          ),
        );
      }

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAppliedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() => _appliedDate = picked);
    }
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  String _toTitleCase(String input) {
    if (input.isEmpty) {
      return input;
    }

    return input
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}
