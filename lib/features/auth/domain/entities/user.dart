import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? token;
  final String? avatar;
  
  // Profile fields
  final String? gender;
  final String? dob;
  final String? address;
  final double? bmiHeight;
  final double? bmiWeight;
  final double? bmiValue;
  
  // Doctor details
  final String? speciality;
  final String? qualification;
  final String? nmcNumber;
  final int? experience;
  final String? bio;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token,
    this.avatar,
    this.gender,
    this.dob,
    this.address,
    this.bmiHeight,
    this.bmiWeight,
    this.bmiValue,
    this.speciality,
    this.qualification,
    this.nmcNumber,
    this.experience,
    this.bio,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        role,
        token,
        avatar,
        gender,
        dob,
        address,
        bmiHeight,
        bmiWeight,
        bmiValue,
        speciality,
        qualification,
        nmcNumber,
        experience,
        bio,
      ];
}

