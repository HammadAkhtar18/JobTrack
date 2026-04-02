import 'package:flutter/material.dart';
import 'package:job_track/models/job_application.dart';

class AddApplicationScreen extends StatelessWidget {
  const AddApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editingApplication = ModalRoute.of(context)?.settings.arguments as JobApplication?;

    return Scaffold(
      appBar: AppBar(
        title: Text(editingApplication == null ? 'Add Application' : 'Edit Application'),
      ),
      body: Center(
        child: Text(
          editingApplication == null
              ? 'Application form coming soon.'
              : 'Editing ${editingApplication.companyName} - ${editingApplication.jobTitle}',
        ),
      ),
    );
  }
}
