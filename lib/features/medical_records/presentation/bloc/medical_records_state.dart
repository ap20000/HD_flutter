import 'package:equatable/equatable.dart';
import '../../domain/entities/medical_record.dart';

abstract class MedicalRecordsState extends Equatable {
  const MedicalRecordsState();

  @override
  List<Object?> get props => [];
}

class MedicalRecordsInitial extends MedicalRecordsState {}

class MedicalRecordsLoading extends MedicalRecordsState {}

class MedicalRecordsLoaded extends MedicalRecordsState {
  final List<MedicalRecord> records;

  const MedicalRecordsLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

class MedicalRecordsError extends MedicalRecordsState {
  final String message;

  const MedicalRecordsError(this.message);

  @override
  List<Object?> get props => [message];
}
