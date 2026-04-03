import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-application');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Application'),
      ),
      body: SafeArea(
        child: applicationsAsync.when(
          data: (applications) {
            if (applications.isEmpty) {
              return const _DashboardMessageState(
                icon: Icons.inbox_rounded,
                title: 'Nothing here yet',
                message: 'Add your first application to see dashboard insights.',
              );
            }

            return _DashboardContent(applications: applications, countByStatus: _countByStatus);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _DashboardMessageState(
            icon: Icons.error_outline_rounded,
            title: 'Couldn’t load your dashboard',
            message: 'Please try again in a moment.',
          ),
        ),
      ),
    );
  }

  int _countByStatus(List<JobApplication> applications, String status) {
    return applications.where((application) {
      final normalized = application.status.trim().toLowerCase();
      if (status == 'interview') {
        return normalized == 'interview' || normalized == 'interviews';
      }
      if (status == 'offer') {
        return normalized == 'offer' || normalized == 'offers';
      }
      return normalized == status;
    }).length;
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.applications,
    required this.countByStatus,
  });

  final List<JobApplication> applications;
  final int Function(List<JobApplication>, String) countByStatus;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final applicationsThisMonth = applications.where((application) {
      return application.appliedDate.year == now.year &&
          application.appliedDate.month == now.month;
    }).length;

    final appliedCount = countByStatus(applications, 'applied');
    final interviewCount = countByStatus(applications, 'interview');
    final offerCount = countByStatus(applications, 'offer');
    final rejectedCount = countByStatus(applications, 'rejected');

    final recentApplications = [...applications]
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GreetingCard(totalApplicationsThisMonth: applicationsThisMonth),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _StatCard(
              title: 'Applied',
              value: appliedCount,
              color: Colors.blue,
              icon: Icons.send_rounded,
            ),
            _StatCard(
              title: 'Interviews',
              value: interviewCount,
              color: Colors.orange,
              icon: Icons.forum_rounded,
            ),
            _StatCard(
              title: 'Offers',
              value: offerCount,
              color: Colors.green,
              icon: Icons.workspace_premium_rounded,
            ),
            _StatCard(
              title: 'Rejected',
              value: rejectedCount,
              color: Colors.red,
              icon: Icons.cancel_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Distribution',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 44,
                      sections: _buildStatusSections(
                        appliedCount: appliedCount,
                        interviewCount: interviewCount,
                        offerCount: offerCount,
                        rejectedCount: rejectedCount,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Applications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (recentApplications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No applications yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...recentApplications.take(5).map(_RecentApplicationTile.new),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  List<PieChartSectionData> _buildStatusSections({
    required int appliedCount,
    required int interviewCount,
    required int offerCount,
    required int rejectedCount,
  }) {
    final statusData = [
      ('Applied', appliedCount, Colors.blue),
      ('Interviews', interviewCount, Colors.orange),
      ('Offers', offerCount, Colors.green),
      ('Rejected', rejectedCount, Colors.red),
    ].where((status) => status.$2 > 0).toList();

    if (statusData.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          radius: 60,
          title: 'No data yet',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
    }

    return statusData
        .map((status) => _buildSection(
              status.$2.toDouble(),
              status.$3,
              status.$1,
            ))
        .toList();
  }

  PieChartSectionData _buildSection(double value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value,
      radius: 60,
      title: '${value.toInt()}',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      badgeWidget: Padding(
        padding: const EdgeInsets.only(top: 76),
        child: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      badgePositionPercentageOffset: 1.36,
    );
  }
}

class _DashboardMessageState extends StatelessWidget {
  const _DashboardMessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.totalApplicationsThisMonth});

  final int totalApplicationsThisMonth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.waving_hand_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Great progress this month', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$totalApplicationsThisMonth applications submitted',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _RecentApplicationTile extends StatelessWidget {
  const _RecentApplicationTile(this.application);

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = application.status.trim().toLowerCase();
    final statusColor = switch (normalizedStatus) {
      'applied' => Colors.blue,
      'interview' || 'interviews' => Colors.orange,
      'offer' || 'offers' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Text(application.companyName),
          subtitle: Text(application.jobTitle),
          trailing: Chip(
            label: Text(application.status),
            side: BorderSide.none,
            labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            backgroundColor: statusColor.withValues(alpha: 0.15),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}
