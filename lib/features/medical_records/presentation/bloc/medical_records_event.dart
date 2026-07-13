import 'package:equatable/equatable.dart';

abstract class MedicalRecordsEvent extends Equatable {
  const MedicalRecordsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedicalRecords extends MedicalRecordsEvent {}

class UploadMedicalRecordEvent extends MedicalRecordsEvent {
  final String title;
  final String recordType;
  final String fileUrl;

  const UploadMedicalRecordEvent({
    required this.title,
    required this.recordType,
    required this.fileUrl,
  });

  @override
  List<Object?> get props => [title, recordType, fileUrl];
}

class ShareMedicalRecordEvent extends MedicalRecordsEvent {
  final String recordId;
  final String doctorId;
  final int durationInHours;

  const ShareMedicalRecordEvent({
    required this.recordId,
    required this.doctorId,
    required this.durationInHours,
  });

  @override
  List<Object?> get props => [recordId, doctorId, durationInHours];
}
