import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateAvatarUseCase implements UseCase<User, UpdateAvatarParams> {
  final AuthRepository repository;

  UpdateAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateAvatarParams params) async {
    return await repository.updateAvatar(
      base64Image: params.base64Image,
    );
  }
}

class UpdateAvatarParams extends Equatable {
  final String base64Image;

  const UpdateAvatarParams({required this.base64Image});

  @override
  List<Object?> get props => [base64Image];
}
