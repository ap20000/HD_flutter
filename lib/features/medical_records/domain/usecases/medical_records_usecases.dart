import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medical_record.dart';
import '../repositories/medical_records_repository.dart';

class GetMedicalRecordsUseCase implements UseCase<List<MedicalRecord>, NoParams> {
  final MedicalRecordsRepository repository;

  GetMedicalRecordsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MedicalRecord>>> call(NoParams params) {
    return repository.getMedicalRecords();
  }
}

class UploadParams {
  final String title;
  final String recordType;
  final String fileUrl;

  UploadParams({required this.title, required this.recordType, required this.fileUrl});
}

class UploadMedicalRecordUseCase implements UseCase<MedicalRecord, UploadParams> {
  final MedicalRecordsRepository repository;

  UploadMedicalRecordUseCase(this.repository);

  @override
  Future<Either<Failure, MedicalRecord>> call(UploadParams params) {
    return repository.uploadMedicalRecord(
      title: params.title,
      recordType: params.recordType,
      fileUrl: params.fileUrl,
    );
  }
}

class ShareParams {
  final String recordId;
  final String doctorId;
  final int durationInHours;

  ShareParams({required this.recordId, required this.doctorId, required this.durationInHours});
}

class ShareMedicalRecordUseCase implements UseCase<void, ShareParams> {
  final MedicalRecordsRepository repository;

  ShareMedicalRecordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ShareParams params) {
    return repository.shareMedicalRecord(
      recordId: params.recordId,
      doctorId: params.doctorId,
      durationInHours: params.durationInHours,
    );
  }
}
