import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? token;
  final String? avatar;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
    this.avatar,
  });

  @override
  List<Object?> get props => [id, name, email, phone, role, token, avatar];
}
