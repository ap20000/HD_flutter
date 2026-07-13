import 'package:equatable/equatable.dart';

class SurgicalLog extends Equatable {
  final String id;
  final String procedure;
  final String date;
  final String hospital;
  final String surgeon;
  final String notes;

  const SurgicalLog({
    required this.id,
    required this.procedure,
    required this.date,
    required this.hospital,
    required this.surgeon,
    required this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        procedure,
        date,
        hospital,
        surgeon,
        notes,
      ];
}
