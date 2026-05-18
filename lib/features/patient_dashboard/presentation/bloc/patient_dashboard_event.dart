import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class PatientDashboardEvent extends Equatable {
  const PatientDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends PatientDashboardEvent {}

class RequestConsultation extends PatientDashboardEvent {
  final String doctorId;
  const RequestConsultation(this.doctorId);
  @override
  List<Object?> get props => [doctorId];
}
