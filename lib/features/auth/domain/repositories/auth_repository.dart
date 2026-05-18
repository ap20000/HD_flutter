import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String loginId,
    required String password,
  });

  Future<Either<Failure, String>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  });

  Future<Either<Failure, User>> verifyOtp({
    required String phone,
    required String code,
  });

  Future<Either<Failure, User>> updateAvatar({
    required String base64Image,
  });
}
