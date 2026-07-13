import 'package:equatable/equatable.dart';

abstract class SurgicalEvent extends Equatable {
  const SurgicalEvent();

  @override
  List<Object?> get props => [];
}

class LoadSurgicalLogs extends SurgicalEvent {}

class AddSurgicalLogEvent extends SurgicalEvent {
  final String procedure;
  final String hospital;
  final String surgeon;
  final String notes;

  const AddSurgicalLogEvent({
    required this.procedure,
    required this.hospital,
    required this.surgeon,
    required this.notes,
  });

  @override
  List<Object?> get props => [procedure, hospital, surgeon, notes];
}
