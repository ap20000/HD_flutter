import 'package:hamro_doctor_mobile/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.token,
    super.avatar,
    super.gender,
    super.dob,
    super.address,
    super.bmiHeight,
    super.bmiWeight,
    super.bmiValue,
    super.speciality,
    super.qualification,
    super.nmcNumber,
    super.experience,
    super.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      token: token ?? json['token'],
      avatar: json['profile']?['avatar'],
      gender: json['profile']?['gender'],
      dob: json['profile']?['dob'],
      address: json['profile']?['address'],
      bmiHeight: (json['profile']?['bmi']?['height'] as num?)?.toDouble(),
      bmiWeight: (json['profile']?['bmi']?['weight'] as num?)?.toDouble(),
      bmiValue: (json['profile']?['bmi']?['value'] as num?)?.toDouble(),
      speciality: json['doctorDetails']?['speciality'],
      qualification: json['doctorDetails']?['qualification'],
      nmcNumber: json['doctorDetails']?['nmcNumber'],
      experience: (json['doctorDetails']?['experience'] as num?)?.toInt(),
      bio: json['doctorDetails']?['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'token': token,
      'profile': {
        'avatar': avatar,
        'gender': gender,
        'dob': dob,
        'address': address,
        'bmi': {
          'height': bmiHeight,
          'weight': bmiWeight,
          'value': bmiValue,
        },
      },
      'doctorDetails': {
        'speciality': speciality,
        'qualification': qualification,
        'nmcNumber': nmcNumber,
        'experience': experience,
        'bio': bio,
      },
    };
  }
}

