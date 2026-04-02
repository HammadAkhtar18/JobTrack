// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobApplicationAdapter extends TypeAdapter<JobApplication> {
  @override
  final int typeId = 0;

  @override
  JobApplication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobApplication(
      id: fields[0] as String,
      companyName: fields[1] as String,
      jobTitle: fields[2] as String,
      jobType: fields[3] as String,
      appliedDate: fields[4] as DateTime,
      status: fields[5] as String,
      applicationUrl: fields[6] as String?,
      notes: fields[7] as String?,
      followUpDate: fields[8] as DateTime?,
      salaryExpectation: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JobApplication obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.companyName)
      ..writeByte(2)
      ..write(obj.jobTitle)
      ..writeByte(3)
      ..write(obj.jobType)
      ..writeByte(4)
      ..write(obj.appliedDate)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.applicationUrl)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.followUpDate)
      ..writeByte(9)
      ..write(obj.salaryExpectation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobApplicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
