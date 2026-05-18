import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class PatientDashboardState extends Equatable {
  const PatientDashboardState();

  @override
  List<Object?> get props => [];
}

class PatientDashboardInitial extends PatientDashboardState {}

class PatientDashboardLoading extends PatientDashboardState {}

class PatientDashboardLoaded extends PatientDashboardState {
  final List<Doctor> doctors;
  final List<Article> articles;
  final HealthRecord? latestRecord;
  final List<Consultation> consultations;

  const PatientDashboardLoaded({
    required this.doctors,
    required this.articles,
    this.latestRecord,
    required this.consultations,
  });

  @override
  List<Object?> get props => [doctors, articles, latestRecord, consultations];
}

class PatientDashboardError extends PatientDashboardState {
  final String message;
  const PatientDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
