import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(
      loginId: params.loginId,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  final String loginId;
  final String password;

  const LoginParams({required this.loginId, required this.password});

  @override
  List<Object?> get props => [loginId, password];
}
