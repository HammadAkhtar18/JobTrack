import 'package:hive/hive.dart';

part 'job_application.g.dart';

@HiveType(typeId: 0)
class JobApplication {
  JobApplication({
    required this.id,
    required this.companyName,
    required this.jobTitle,
    required this.jobType,
    required this.appliedDate,
    required this.status,
    this.applicationUrl,
    this.notes,
    this.followUpDate,
    this.salaryExpectation,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String companyName;

  @HiveField(2)
  final String jobTitle;

  @HiveField(3)
  final String jobType;

  @HiveField(4)
  final DateTime appliedDate;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String? applicationUrl;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime? followUpDate;

  @HiveField(9)
  final String? salaryExpectation;

  JobApplication copyWith({
    String? id,
    String? companyName,
    String? jobTitle,
    String? jobType,
    DateTime? appliedDate,
    String? status,
    Object? applicationUrl = _unset,
    Object? notes = _unset,
    Object? followUpDate = _unset,
    Object? salaryExpectation = _unset,
  }) {
    return JobApplication(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      jobType: jobType ?? this.jobType,
      appliedDate: appliedDate ?? this.appliedDate,
      status: status ?? this.status,
      applicationUrl: applicationUrl == _unset
          ? this.applicationUrl
          : applicationUrl as String?,
      notes: notes == _unset ? this.notes : notes as String?,
      followUpDate: followUpDate == _unset
          ? this.followUpDate
          : followUpDate as DateTime?,
      salaryExpectation: salaryExpectation == _unset
          ? this.salaryExpectation
          : salaryExpectation as String?,
    );
  }
}


const Object _unset = Object();
