import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:job_track/models/job_application.dart';
import 'package:job_track/providers/applications_provider.dart';

class ApplicationsListScreen extends ConsumerStatefulWidget {
  const ApplicationsListScreen({super.key});

  @override
  ConsumerState<ApplicationsListScreen> createState() =>
      _ApplicationsListScreenState();
}

class _ApplicationsListScreenState extends ConsumerState<ApplicationsListScreen> {
  static const List<String> _statusFilters = [
    'All',
    'Applied',
    'Interview',
    'Offer',
    'Rejected',
    'Ghosted',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(applicationsProvider);
    final normalizedFilter = _selectedFilter.toLowerCase();

    final filteredApplications = applications.where((application) {
      final normalizedStatus = application.status.trim().toLowerCase();
      final matchesFilter = normalizedFilter == 'all' || normalizedStatus == normalizedFilter;
      final normalizedQuery = _searchQuery.trim().toLowerCase();
      final matchesSearch = normalizedQuery.isEmpty ||
          application.companyName.toLowerCase().contains(normalizedQuery) ||
          application.jobTitle.toLowerCase().contains(normalizedQuery);
      return matchesFilter && matchesSearch;
    }).toList()
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search company or job title',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredApplications.isEmpty
                ? const Center(child: Text('No applications found.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredApplications.length,
                    itemBuilder: (context, index) {
                      final application = filteredApplications[index];
                      return _ApplicationCard(
                        application: application,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/add-application',
                            arguments: application,
                          );
                        },
                        onDelete: () async {
                          await ref
                              .read(applicationsProvider.notifier)
                              .deleteApplication(application.id);
                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deleted ${application.companyName} - ${application.jobTitle}',
                                ),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref
                                        .read(applicationsProvider.notifier)
                                        .addApplication(application);
                                  },
                                ),
                              ),
                            );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
    required this.onDelete,
  });

  final JobApplication application;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(application.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(application.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: Card(
          elevation: 0,
          child: ListTile(
            onTap: onTap,
            title: Text(application.companyName),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(application.jobTitle),
                  const SizedBox(height: 4),
                  Text('Applied ${DateFormat.yMMMd().format(application.appliedDate)}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(application.status),
                        labelStyle: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                      if (application.followUpDate != null)
                        Chip(
                          label: Text(
                            'Follow-up ${DateFormat.yMMMd().format(application.followUpDate!)}',
                          ),
                          avatar: const Icon(Icons.notifications_active, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status.trim().toLowerCase()) {
      'applied' => Colors.blue,
      'interview' || 'interviews' => Colors.orange,
      'offer' || 'offers' => Colors.green,
      'rejected' => Colors.red,
      'ghosted' => Colors.deepPurple,
      _ => Colors.grey,
    };
  }
}
