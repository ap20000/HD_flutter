import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/surgical_log.dart';

abstract class SurgicalRepository {
  Future<Either<Failure, List<SurgicalLog>>> getSurgicalLogs();
  Future<Either<Failure, SurgicalLog>> addSurgicalLog({
    required String procedure,
    required String hospital,
    required String surgeon,
    required String notes,
  });
}
