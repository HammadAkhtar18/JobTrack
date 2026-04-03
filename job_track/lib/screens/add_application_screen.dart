import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:uuid/uuid.dart';

class AddApplicationScreen extends ConsumerWidget {
  const AddApplicationScreen({
    super.key,
    this.application,
  });

  final JobApplication? application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editingApplication =
        application ?? ModalRoute.of(context)?.settings.arguments as JobApplication?;

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
                onPressed: () => _saveApplication(context, ref, editingApplication),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
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
    }
  }
}
