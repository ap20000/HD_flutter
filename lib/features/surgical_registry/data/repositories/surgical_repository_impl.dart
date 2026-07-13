import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/surgical_log.dart';
import '../../domain/repositories/surgical_repository.dart';
import '../datasources/surgical_remote_data_source.dart';

class SurgicalRepositoryImpl implements SurgicalRepository {
  final SurgicalRemoteDataSource remoteDataSource;

  final List<SurgicalLog> _mockLogs = [
    const SurgicalLog(
      id: 'log_1',
      procedure: 'Laparoscopic Appendectomy',
      date: 'May 14, 2024',
      hospital: 'Kathmandu Medical College',
      surgeon: 'Dr. Sunil Sharma',
      notes: 'Successful removal of acute appendix. Fully recovered, no complications.',
    ),
    const SurgicalLog(
      id: 'log_2',
      procedure: 'Septoplasty & Turbinate Reduction',
      date: 'Nov 03, 2022',
      hospital: 'Grande International Hospital',
      surgeon: 'Dr. Bikash Pokhrel',
      notes: 'Deviated septum corrected to improve breathing pathways.',
    ),
  ];

  SurgicalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SurgicalLog>>> getSurgicalLogs() async {
    try {
      final logs = await remoteDataSource.getSurgicalLogs();
      return Right(logs);
    } catch (_) {
      return Right(_mockLogs);
    }
  }

  @override
  Future<Either<Failure, SurgicalLog>> addSurgicalLog({
    required String procedure,
    required String hospital,
    required String surgeon,
    required String notes,
  }) async {
    try {
      final log = await remoteDataSource.addSurgicalLog(
        procedure: procedure,
        hospital: hospital,
        surgeon: surgeon,
        notes: notes,
      );
      return Right(log);
    } catch (_) {
      final newLog = SurgicalLog(
        id: 'log_${_mockLogs.length + 1}',
        procedure: procedure,
        date: 'Today',
        hospital: hospital,
        surgeon: surgeon,
        notes: notes,
      );
      _mockLogs.insert(0, newLog);
      return Right(newLog);
    }
  }
}
