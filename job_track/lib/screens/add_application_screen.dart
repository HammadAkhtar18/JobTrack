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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editingApplication == null
                    ? 'Application form coming soon.'
                    : 'Editing ${editingApplication.companyName} - ${editingApplication.jobTitle}',
                textAlign: TextAlign.center,
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
    );
  }

  Future<void> _saveApplication(
    BuildContext context,
    WidgetRef ref,
    JobApplication? editingApplication,
  ) async {
    setState(() => _isSaving = true);
    final notifier = ref.read(applicationsProvider.notifier);

    try {
      if (editingApplication != null) {
        await notifier.updateApplication(editingApplication);
      } else {
        await notifier.addApplication(
          JobApplication(
            id: const Uuid().v4(),
            companyName: 'New Company',
            jobTitle: 'New Role',
            jobType: 'Full-time',
            appliedDate: DateTime.now(),
            status: 'Applied',
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
}
