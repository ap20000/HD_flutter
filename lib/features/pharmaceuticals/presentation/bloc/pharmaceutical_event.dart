import 'package:equatable/equatable.dart';

abstract class PharmaceuticalEvent extends Equatable {
  const PharmaceuticalEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedicines extends PharmaceuticalEvent {}

class AddMedicineEvent extends PharmaceuticalEvent {
  final String name;
  final String generic;
  final String category;
  final String details;

  const AddMedicineEvent({
    required this.name,
    required this.generic,
    required this.category,
    required this.details,
  });

  @override
  List<Object?> get props => [name, generic, category, details];
}
