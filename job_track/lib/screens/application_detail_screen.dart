import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';
import 'package:job_track/screens/add_application_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({
    required this.application,
    super.key,
  });

  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddApplicationScreen(application: application),
                ),
              );
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              application.companyName,
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(application.jobTitle, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            _DetailsCard(application: application),
            const SizedBox(height: 16),
            _StatusTimeline(currentStatus: application.status),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _setReminder(context, application),
              icon: const Icon(Icons.alarm_add_rounded),
              label: const Text('Set Reminder'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Application'),
              style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setReminder(BuildContext context, JobApplication application) async {
    try {
      final followUpDate = application.followUpDate;
      if (followUpDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a follow-up date to schedule a reminder.')),
        );
        return;
      }

      if (!followUpDate.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up date must be in the future.')),
        );
        return;
      }

      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission denied')),
          );
          return;
        }
      }

      await _NotificationsService.instance.initialize();

      await _NotificationsService.instance.scheduleFollowUpReminder(
        id: application.id.hashCode,
        companyName: application.companyName,
        jobTitle: application.jobTitle,
        when: followUpDate,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${DateFormat.yMMMd().add_jm().format(followUpDate)}')),
      );
    } on PlatformException {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to set reminder. Please try again.')),
      );
    } on Exception {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to set reminder. Please try again.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete application?'),
          content: Text('This will permanently remove ${application.companyName} - ${application.jobTitle}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(applicationsProvider.notifier).deleteApplication(application.id);

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application deleted.')),
      );
    } on Exception {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete application.')),
      );
    }
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(icon: Icons.business_rounded, label: 'Company', value: application.companyName),
            _DetailRow(icon: Icons.work_outline_rounded, label: 'Job title', value: application.jobTitle),
            _DetailRow(icon: Icons.badge_rounded, label: 'Job type', value: application.jobType),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Applied date',
              value: DateFormat.yMMMd().format(application.appliedDate),
            ),
            _DetailRow(icon: Icons.flag_rounded, label: 'Status', value: application.status),
            _DetailRow(icon: Icons.link_rounded, label: 'Application URL', value: application.applicationUrl),
            _DetailRow(icon: Icons.attach_money_rounded, label: 'Salary', value: application.salaryExpectation),
            _DetailRow(
              icon: Icons.event_repeat_rounded,
              label: 'Follow-up date',
              value: application.followUpDate == null
                  ? null
                  : DateFormat.yMMMd().add_jm().format(application.followUpDate!),
            ),
            _DetailRow(icon: Icons.notes_rounded, label: 'Notes', value: application.notes),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = (value == null || value!.trim().isEmpty) ? 'Not provided' : value!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(displayValue, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});

  final String currentStatus;

  static const List<String> _stages = [
    'applied',
    'screening',
    'interview',
    'offer',
    'hired',
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = currentStatus.trim().toLowerCase();
    final currentIndex = _stages.indexOf(normalized);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Timeline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...List.generate(_stages.length, (index) {
              final stage = _stages[index];
              final reached = currentIndex >= index;
              final isCurrent = currentIndex == index;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        reached ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: reached
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                      if (index != _stages.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: reached
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        _toTitleCase(stage) + (isCurrent ? ' (Current)' : ''),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) {
      return text;
    }

    return text[0].toUpperCase() + text.substring(1);
  }
}

class _NotificationsService {
  _NotificationsService._();

  static final _NotificationsService instance = _NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );

    _initialized = true;
  }

  Future<void> scheduleFollowUpReminder({
    required int id,
    required String companyName,
    required String jobTitle,
    required DateTime when,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'follow_up_reminders',
        'Follow-up reminders',
        channelDescription: 'Reminders for job application follow-up dates.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.schedule(
      id,
      'Follow up with $companyName',
      'Check in about your $jobTitle application.',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
