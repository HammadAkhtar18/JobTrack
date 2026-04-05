import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:job_track/services/notification_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _versionLabel = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _versionLabel = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _versionLabel = 'Unavailable');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Export Data (JSON backup)'),
                  subtitle: const Text('Create a full backup of all applications.'),
                  onTap: _exportJsonBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_page_outlined),
                  title: const Text('Import Data (restore from JSON)'),
                  subtitle: const Text('Restore from a backup file and overwrite existing data.'),
                  onTap: _importJsonBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Export CSV'),
                  subtitle: const Text('Share your applications as a CSV file.'),
                  onTap: _exportCsv,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    'Clear all data',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  subtitle: const Text('Delete all saved applications permanently.'),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('App version'),
              subtitle: Text(_versionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJsonBackup() async {
    final allApplications = [...ref.read(applicationsProvider.notifier).getAll()]
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    final backupPayload = <String, dynamic>{
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'applications': allApplications.map((application) => application.toJson()).toList(),
    };

    final backupBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(backupPayload),
    );

    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            backupBytes,
            mimeType: 'application/json',
            name: 'jobtrack_backup.json',
          ),
        ],
        fileNameOverrides: ['jobtrack_backup.json'],
        text: 'JobTrack backup export',
      );
    } catch (_) {
      _showMessage('Could not export backup file.');
    }
  }

  Future<void> _importJsonBackup() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore backup?'),
          content: const Text(
            'Importing a backup will overwrite all current data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (pickedFile == null || pickedFile.files.isEmpty) {
        return;
      }

      final file = pickedFile.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage('Could not read selected file.');
        return;
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        _showMessage('Invalid backup format.');
        return;
      }

      final applicationsRaw = decoded['applications'];
      if (applicationsRaw is! List) {
        _showMessage('Backup file does not contain applications data.');
        return;
      }

      final parsedApplications = <JobApplication>[];
      var skippedRecords = 0;
      for (final item in applicationsRaw) {
        if (item is! Map<String, dynamic>) {
          skippedRecords++;
          continue;
        }

        try {
          parsedApplications.add(JobApplication.fromJson(item));
        } catch (_) {
          skippedRecords++;
        }
      }

      if (parsedApplications.isEmpty && applicationsRaw.isNotEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No valid records found. Import aborted. Existing data preserved.',
            ),
          ),
        );
        return;
      }

      final notifier = ref.read(applicationsProvider.notifier);
      final notificationService = ref.read(notificationServiceProvider);
      final existingApplications = notifier.getAll();
      for (final application in existingApplications) {
        try {
          await notificationService.cancelReminder(application.id);
        } catch (_) {
          // Continue restoring even if a reminder cancellation fails.
        }
      }

      await notifier.replaceAllApplications(parsedApplications);

      _showMessage(
        'Imported ${parsedApplications.length} applications. '
        '$skippedRecords records skipped due to errors.',
      );
    } catch (_) {
      _showMessage('Could not import backup file.');
    }
  }

  Future<void> _exportCsv() async {
    final allApplications = [...ref.read(applicationsProvider.notifier).getAll()]
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    if (allApplications.isEmpty) {
      _showMessage('No applications to export.');
      return;
    }

    final csvContent = _buildCsv(allApplications);
    final csvBytes = utf8.encode(csvContent);

    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            csvBytes,
            mimeType: 'text/csv',
            name: 'job_applications.csv',
          ),
        ],
        fileNameOverrides: ['job_applications.csv'],
        text: 'Job applications export',
      );
    } catch (_) {
      _showMessage('Could not export applications.');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all data?'),
          content: const Text(
            'This will permanently delete all applications and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final notifier = ref.read(applicationsProvider.notifier);
      final notificationService = ref.read(notificationServiceProvider);
      final allApplications = notifier.getAll();
      for (final application in allApplications) {
        try {
          await notificationService.cancelReminder(application.id);
        } catch (_) {
          // Continue clearing data even if a reminder cancellation fails.
        }
      }

      await notifier.clearAllApplications();
      _showMessage('All data cleared.');
    } catch (_) {
      _showMessage('Could not clear data.');
    }
  }

  String _buildCsv(List<JobApplication> applications) {
    const headers = <String>[
      'Company',
      'Title',
      'Type',
      'Status',
      'Applied Date',
      'Follow-up Date',
      'Notes',
    ];

    final buffer = StringBuffer('${headers.join(',')}\n');

    for (final application in applications) {
      final row = <String>[
        application.companyName,
        application.jobTitle,
        application.jobType,
        application.status,
        DateFormat('yyyy-MM-dd').format(application.appliedDate),
        application.followUpDate == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(application.followUpDate!),
        application.notes ?? '',
      ].map(_escapeCsvValue).join(',');

      buffer.writeln(row);
    }

    return buffer.toString();
  }

  String _escapeCsvValue(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
