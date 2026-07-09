import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      name: params.name,
      email: params.email,
      gender: params.gender,
      dob: params.dob,
      address: params.address,
      bmiHeight: params.bmiHeight,
      bmiWeight: params.bmiWeight,
      speciality: params.speciality,
      qualification: params.qualification,
      nmcNumber: params.nmcNumber,
      experience: params.experience,
      bio: params.bio,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String name;
  final String email;
  final String? gender;
  final String? dob;
  final String? address;
  final double? bmiHeight;
  final double? bmiWeight;
  final String? speciality;
  final String? qualification;
  final String? nmcNumber;
  final int? experience;
  final String? bio;

  const UpdateProfileParams({
    required this.name,
    required this.email,
    this.gender,
    this.dob,
    this.address,
    this.bmiHeight,
    this.bmiWeight,
    this.speciality,
    this.qualification,
    this.nmcNumber,
    this.experience,
    this.bio,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        gender,
        dob,
        address,
        bmiHeight,
        bmiWeight,
        speciality,
        qualification,
        nmcNumber,
        experience,
        bio,
      ];
}
