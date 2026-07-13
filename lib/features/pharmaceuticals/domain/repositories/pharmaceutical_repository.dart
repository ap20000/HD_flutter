import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/medicine.dart';

abstract class PharmaceuticalRepository {
  Future<Either<Failure, List<Medicine>>> getMedicines();
  Future<Either<Failure, Medicine>> addMedicine({
    required String name,
    required String generic,
    required String category,
    required String details,
  });
}
