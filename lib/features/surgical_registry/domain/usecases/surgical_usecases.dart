import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/surgical_log.dart';
import '../repositories/surgical_repository.dart';

class GetSurgicalLogsUseCase implements UseCase<List<SurgicalLog>, NoParams> {
  final SurgicalRepository repository;

  GetSurgicalLogsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SurgicalLog>>> call(NoParams params) {
    return repository.getSurgicalLogs();
  }
}

class AddSurgicalLogParams {
  final String procedure;
  final String hospital;
  final String surgeon;
  final String notes;

  AddSurgicalLogParams({
    required this.procedure,
    required this.hospital,
    required this.surgeon,
    required this.notes,
  });
}

class AddSurgicalLogUseCase implements UseCase<SurgicalLog, AddSurgicalLogParams> {
  final SurgicalRepository repository;

  AddSurgicalLogUseCase(this.repository);

  @override
  Future<Either<Failure, SurgicalLog>> call(AddSurgicalLogParams params) {
    return repository.addSurgicalLog(
      procedure: params.procedure,
      hospital: params.hospital,
      surgeon: params.surgeon,
      notes: params.notes,
    );
  }
}
