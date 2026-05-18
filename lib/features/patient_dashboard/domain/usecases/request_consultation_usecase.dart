import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/patient_dashboard_repository.dart';

class RequestConsultationUseCase implements UseCase<void, String> {
  final PatientDashboardRepository repository;

  RequestConsultationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String doctorId) async {
    return await repository.requestConsultation(doctorId);
  }
}
