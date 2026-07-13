import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/medical_record.dart';

abstract class MedicalRecordsRepository {
  Future<Either<Failure, List<MedicalRecord>>> getMedicalRecords();
  Future<Either<Failure, MedicalRecord>> uploadMedicalRecord({
    required String title,
    required String recordType,
    required String fileUrl,
  });
  Future<Either<Failure, void>> shareMedicalRecord({
    required String recordId,
    required String doctorId,
    required int durationInHours,
  });
}
