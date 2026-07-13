import 'package:equatable/equatable.dart';
import '../../domain/entities/surgical_log.dart';

abstract class SurgicalState extends Equatable {
  const SurgicalState();

  @override
  List<Object?> get props => [];
}

class SurgicalInitial extends SurgicalState {}

class SurgicalLoading extends SurgicalState {}

class SurgicalLoaded extends SurgicalState {
  final List<SurgicalLog> logs;

  const SurgicalLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}

class SurgicalError extends SurgicalState {
  final String message;

  const SurgicalError(this.message);

  @override
  List<Object?> get props => [message];
}
