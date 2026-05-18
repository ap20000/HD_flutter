import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String loginId;
  final String password;

  const LoginSubmitted({required this.loginId, required this.password});

  @override
  List<Object?> get props => [loginId, password];
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
