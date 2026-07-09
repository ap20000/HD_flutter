import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String loginId;
  final String password;
  final bool rememberMe;

  const LoginSubmitted({
    required this.loginId, 
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [loginId, password, rememberMe];
}

class RegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [name, email, phone, password, role];
}

class VerifyOtpSubmitted extends AuthEvent {
  final String phone;
  final String code;

  const VerifyOtpSubmitted({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}

class LogoutRequested extends AuthEvent {}

class UpdateAvatarRequested extends AuthEvent {
  final String base64Image;

  const UpdateAvatarRequested({required this.base64Image});

  @override
  List<Object?> get props => [base64Image];
}

class UpdateProfileRequested extends AuthEvent {
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

  const UpdateProfileRequested({
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

