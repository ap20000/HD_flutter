import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/doctor_dashboard_data.dart';
import '../../../patient_dashboard/domain/entities/dashboard_data.dart';

abstract class DoctorDashboardRepository {
  Future<Either<Failure, DoctorStats>> getStats();
  Future<Either<Failure, List<Workplace>>> getWorkplaces();
  Future<Either<Failure, List<Consultation>>> getConsultations();
  Future<Either<Failure, bool>> updateStatus(bool isOnline);
  Future<Either<Failure, void>> respondToConsultation(String consultationId, String status);
  Future<Either<Failure, Consultation>> getConsultationById(String id);
}
