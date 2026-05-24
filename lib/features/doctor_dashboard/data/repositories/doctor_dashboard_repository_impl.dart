import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../patient_dashboard/domain/entities/dashboard_data.dart';
import '../../domain/entities/doctor_dashboard_data.dart';
import '../../domain/repositories/doctor_dashboard_repository.dart';
import '../datasources/doctor_dashboard_remote_data_source.dart';

class DoctorDashboardRepositoryImpl implements DoctorDashboardRepository {
  final DoctorDashboardRemoteDataSource remoteDataSource;

  DoctorDashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DoctorStats>> getStats() async {
    try {
      final stats = await remoteDataSource.getStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Workplace>>> getWorkplaces() async {
    try {
      final workplaces = await remoteDataSource.getWorkplaces();
      return Right(workplaces);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Consultation>>> getConsultations() async {
    try {
      final consultations = await remoteDataSource.getConsultations();
      return Right(consultations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateStatus(bool isOnline) async {
    try {
      final result = await remoteDataSource.updateStatus(isOnline);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> respondToConsultation(String consultationId, String status) async {
    try {
      await remoteDataSource.respondToConsultation(consultationId, status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Consultation>> getConsultationById(String id) async {
    try {
      final consultation = await remoteDataSource.getConsultationById(id);
      return Right(consultation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }
}
