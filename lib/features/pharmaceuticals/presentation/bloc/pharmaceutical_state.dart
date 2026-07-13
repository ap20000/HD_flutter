import 'package:equatable/equatable.dart';
import '../../domain/entities/medicine.dart';

abstract class PharmaceuticalState extends Equatable {
  const PharmaceuticalState();

  @override
  List<Object?> get props => [];
}

class PharmaceuticalInitial extends PharmaceuticalState {}

class PharmaceuticalLoading extends PharmaceuticalState {}

class PharmaceuticalLoaded extends PharmaceuticalState {
  final List<Medicine> medicines;

  const PharmaceuticalLoaded(this.medicines);

  @override
  List<Object?> get props => [medicines];
}

class PharmaceuticalError extends PharmaceuticalState {
  final String message;

  const PharmaceuticalError(this.message);

  @override
  List<Object?> get props => [message];
}
