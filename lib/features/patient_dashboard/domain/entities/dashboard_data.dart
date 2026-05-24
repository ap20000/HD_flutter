import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String id;
  final String name;
  final String specialty;
  final String? profilePicture;
  final double rating;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.profilePicture,
    this.rating = 0.0,
  });

  @override
  List<Object?> get props => [id, name, specialty, profilePicture, rating];
}

class Article extends Equatable {
  final String id;
  final String title;
  final String content;
  final String author;
  final String? thumbnail;
  final String createdAt;

  const Article({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.thumbnail,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, content, author, thumbnail, createdAt];
}

class HealthRecord extends Equatable {
  final String id;
  final double weight;
  final double height;
  final double bmi;
  final String date;

  const HealthRecord({
    required this.id,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.date,
  });

  @override
  List<Object?> get props => [id, weight, height, bmi, date];
}

class Consultation extends Equatable {
  final String id;
  final String doctorName;
  final String? patientName;
  final String? patientAvatar;
  final String doctorSpecialty;
  final String status;
  final String createdAt;
  final List<Map<String, dynamic>> messages;

  const Consultation({
    required this.id,
    required this.doctorName,
    this.patientName,
    this.patientAvatar,
    required this.doctorSpecialty,
    required this.status,
    required this.createdAt,
    this.messages = const [],
  });

  @override
  List<Object?> get props => [
        id,
        doctorName,
        patientName,
        patientAvatar,
        doctorSpecialty,
        status,
        createdAt,
        messages,
      ];
}
