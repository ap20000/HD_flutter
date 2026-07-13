import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medicine.dart';
import '../repositories/pharmaceutical_repository.dart';

class GetMedicinesUseCase implements UseCase<List<Medicine>, NoParams> {
  final PharmaceuticalRepository repository;

  GetMedicinesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Medicine>>> call(NoParams params) {
    return repository.getMedicines();
  }
}

class AddMedicineParams {
  final String name;
  final String generic;
  final String category;
  final String details;

  AddMedicineParams({
    required this.name,
    required this.generic,
    required this.category,
    required this.details,
  });
}

class AddMedicineUseCase implements UseCase<Medicine, AddMedicineParams> {
  final PharmaceuticalRepository repository;

  AddMedicineUseCase(this.repository);

  @override
  Future<Either<Failure, Medicine>> call(AddMedicineParams params) {
    return repository.addMedicine(
      name: params.name,
      generic: params.generic,
      category: params.category,
      details: params.details,
    );
  }
}
