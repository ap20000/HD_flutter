import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dashboard_data.dart';
import '../repositories/patient_dashboard_repository.dart';

class GetDoctorsUseCase implements UseCase<List<Doctor>, NoParams> {
  final PatientDashboardRepository repository;
  GetDoctorsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Doctor>>> call(NoParams params) async {
    return await repository.getDoctors();
  }
}

class GetArticlesUseCase implements UseCase<List<Article>, NoParams> {
  final PatientDashboardRepository repository;
  GetArticlesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Article>>> call(NoParams params) async {
    return await repository.getArticles();
  }
}

class GetLatestHealthRecordUseCase implements UseCase<HealthRecord?, NoParams> {
  final PatientDashboardRepository repository;
  GetLatestHealthRecordUseCase(this.repository);

  @override
  Future<Either<Failure, HealthRecord?>> call(NoParams params) async {
    return await repository.getLatestHealthRecord();
  }
}

class GetConsultationsUseCase implements UseCase<List<Consultation>, NoParams> {
  final PatientDashboardRepository repository;
  GetConsultationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Consultation>>> call(NoParams params) async {
    return await repository.getConsultations();
  }
}
