import '../../domain/entities/dashboard_data.dart';

class DoctorModel extends Doctor {
  const DoctorModel({
    required super.id,
    required super.name,
    required super.specialty,
    super.profilePicture,
    super.rating,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['doctorDetails']?['speciality'] ?? '',
      profilePicture: json['profile']?['avatar'],
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.title,
    required super.content,
    required super.author,
    super.thumbnail,
    required super.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      author: json['author']?['name'] ?? 'Admin',
      thumbnail: json['featureImage'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class HealthRecordModel extends HealthRecord {
  const HealthRecordModel({
    required super.id,
    required super.weight,
    required super.height,
    required super.bmi,
    required super.date,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['_id'] ?? '',
      weight: (json['weight'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
      bmi: (json['value'] ?? 0.0).toDouble(),
      date: json['lastUpdated'] ?? '',
    );
  }
}

class ConsultationModel extends Consultation {
  const ConsultationModel({
    required super.id,
    required super.doctorName,
    super.patientName,
    super.patientAvatar,
    required super.doctorSpecialty,
    required super.status,
    required super.createdAt,
    super.messages,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['_id'] ?? '',
      doctorName: json['doctor']?['name'] ?? 'Doctor',
      patientName: json['patient']?['name'] ?? 'Patient',
      patientAvatar: json['patient']?['profile']?['avatar'],
      doctorSpecialty: json['doctor']?['doctorDetails']?['specialty'] ?? 'Specialist',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
      messages: (json['messages'] as List?)?.map((m) => {
        'senderId': m['sender'] ?? '',
        'text': m['text'] ?? '',
        'timestamp': m['timestamp'] ?? '',
      }).toList() ?? const [],
    );
  }
}
