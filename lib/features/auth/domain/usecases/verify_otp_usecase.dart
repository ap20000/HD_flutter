import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase implements UseCase<User, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(
      phone: params.phone,
      code: params.code,
    );
  }
}

class VerifyOtpParams extends Equatable {
  final String phone;
  final String code;

  const VerifyOtpParams({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}
