import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:uuid/uuid.dart';

class AddApplicationScreen extends ConsumerStatefulWidget {
  const AddApplicationScreen({super.key, this.application});

  final JobApplication? application;

  @override
  ConsumerState<AddApplicationScreen> createState() =>
      _AddApplicationScreenState();
}

class _AddApplicationScreenState extends ConsumerState<AddApplicationScreen> {
  static const List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Internship',
    'Remote',
  ];

  static const List<String> _statuses = [
    'Applied',
    'Interview',
    'Offer',
    'Rejected',
  ];

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _applicationUrlController = TextEditingController();
  final _salaryExpectationController = TextEditingController();
  final _notesController = TextEditingController();

  late String _selectedJobType;
  late String _selectedStatus;
  late DateTime _appliedDate;
  DateTime? _followUpDate;
  bool _isSaving = false;

  bool get _isEditMode => widget.application != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.application;
    _companyNameController.text = existing?.companyName ?? '';
    _jobTitleController.text = existing?.jobTitle ?? '';
    _applicationUrlController.text = existing?.applicationUrl ?? '';
    _salaryExpectationController.text = existing?.salaryExpectation ?? '';
    _notesController.text = existing?.notes ?? '';

    _selectedJobType = _jobTypes.contains(existing?.jobType)
        ? existing!.jobType
        : _jobTypes.first;

    _selectedStatus = _statuses.contains(existing?.status)
        ? existing!.status
        : _statuses.first;

    final now = DateTime.now();
    _appliedDate = DateTime(
      (existing?.appliedDate ?? now).year,
      (existing?.appliedDate ?? now).month,
      (existing?.appliedDate ?? now).day,
    );

    _followUpDate = existing?.followUpDate;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _jobTitleController.dispose();
    _applicationUrlController.dispose();
    _salaryExpectationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Application' : 'Add Application'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _companyNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Company name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jobTitleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Job title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  border: OutlineInputBorder(),
                ),
                items: _jobTypes
                    .map(
                      (jobType) => DropdownMenuItem(
                        value: jobType,
                        child: Text(jobType),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedJobType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Applied Date',
                selectedDate: _appliedDate,
                formattedDate: dateFormat.format(_appliedDate),
                onTap: () async {
                  final picked = await _pickDate(
                    context,
                    initialDate: _appliedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) {
                    return;
                  }
                  setState(() {
                    _appliedDate = picked;
                  });
                },
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Follow-up Date',
                selectedDate: _followUpDate,
                formattedDate:
                    _followUpDate == null ? 'Not set' : dateFormat.format(_followUpDate!),
                onTap: () async {
                  final picked = await _pickDate(
                    context,
                    initialDate: _followUpDate ?? _appliedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) {
                    return;
                  }
                  setState(() {
                    _followUpDate = picked;
                  });
                },
                onClear: _followUpDate == null
                    ? null
                    : () {
                        setState(() {
                          _followUpDate = null;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _applicationUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Application URL',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return null;
                  }

                  final uri = Uri.tryParse(text);
                  if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
                    return 'Enter a valid URL';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryExpectationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Salary Expectation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                textInputAction: TextInputAction.newline,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveApplication,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isEditMode ? 'Update Application' : 'Save Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) {
      return null;
    }

    return DateTime(picked.year, picked.month, picked.day);
  }

  Future<void> _saveApplication() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final notifier = ref.read(applicationsProvider.notifier);

    final application = JobApplication(
      id: widget.application?.id ?? const Uuid().v4(),
      companyName: _companyNameController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      jobType: _selectedJobType,
      appliedDate: _appliedDate,
      status: _selectedStatus,
      applicationUrl: _optionalText(_applicationUrlController),
      salaryExpectation: _optionalText(_salaryExpectationController),
      notes: _optionalText(_notesController),
      followUpDate: _followUpDate,
    );

    if (_isEditMode) {
      await notifier.updateApplication(application);
    } else {
      await notifier.addApplication(application);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  String? _optionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.formattedDate,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? selectedDate;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedDate != null && onClear != null)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              const Icon(Icons.calendar_today_outlined),
              const SizedBox(width: 12),
            ],
          ),
        ),
        child: Text(formattedDate),
      ),
    );
  }
}
