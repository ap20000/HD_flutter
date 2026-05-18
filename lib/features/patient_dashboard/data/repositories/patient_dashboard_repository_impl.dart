import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/patient_dashboard_repository.dart';
import '../datasources/patient_dashboard_remote_data_source.dart';

class PatientDashboardRepositoryImpl implements PatientDashboardRepository {
  final PatientDashboardRemoteDataSource remoteDataSource;

  PatientDashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Doctor>>> getDoctors() async {
    try {
      final doctors = await remoteDataSource.getDoctors();
      return Right(doctors);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getArticles() async {
    try {
      final articles = await remoteDataSource.getArticles();
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, HealthRecord?>> getLatestHealthRecord() async {
    try {
      final record = await remoteDataSource.getLatestHealthRecord();
      return Right(record);
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
  Future<Either<Failure, void>> requestConsultation(String doctorId) async {
    try {
      await remoteDataSource.requestConsultation(doctorId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred'));
    }
  }
}
