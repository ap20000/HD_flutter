import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../patient_dashboard/domain/entities/dashboard_data.dart';
import '../entities/doctor_dashboard_data.dart';
import '../repositories/doctor_dashboard_repository.dart';

class GetDoctorStatsUseCase implements UseCase<DoctorStats, NoParams> {
  final DoctorDashboardRepository repository;
  GetDoctorStatsUseCase(this.repository);

  @override
  Future<Either<Failure, DoctorStats>> call(NoParams params) async {
    return await repository.getStats();
  }
}

class GetDoctorWorkplacesUseCase implements UseCase<List<Workplace>, NoParams> {
  final DoctorDashboardRepository repository;
  GetDoctorWorkplacesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Workplace>>> call(NoParams params) async {
    return await repository.getWorkplaces();
  }
}

class GetDoctorConsultationsUseCase implements UseCase<List<Consultation>, NoParams> {
  final DoctorDashboardRepository repository;
  GetDoctorConsultationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Consultation>>> call(NoParams params) async {
    return await repository.getConsultations();
  }
}

class UpdateDoctorStatusUseCase implements UseCase<bool, bool> {
  final DoctorDashboardRepository repository;
  UpdateDoctorStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(bool isOnline) async {
    return await repository.updateStatus(isOnline);
  }
}

class RespondToConsultationUseCase implements UseCase<void, RespondParams> {
  final DoctorDashboardRepository repository;
  RespondToConsultationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RespondParams params) async {
    return await repository.respondToConsultation(params.id, params.status);
  }
}

class RespondParams {
  final String id;
  final String status;
  RespondParams({required this.id, required this.status});
}

class GetConsultationByIdUseCase implements UseCase<Consultation, String> {
  final DoctorDashboardRepository repository;
  GetConsultationByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Consultation>> call(String id) async {
    return await repository.getConsultationById(id);
  }
}
