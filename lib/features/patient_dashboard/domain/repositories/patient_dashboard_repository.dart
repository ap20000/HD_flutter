import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_data.dart';

abstract class PatientDashboardRepository {
  Future<Either<Failure, List<Doctor>>> getDoctors();
  Future<Either<Failure, List<Article>>> getArticles();
  Future<Either<Failure, HealthRecord?>> getLatestHealthRecord();
  Future<Either<Failure, List<Consultation>>> getConsultations();
  Future<Either<Failure, void>> requestConsultation(String doctorId);
}
