import '../../domain/entities/surgical_log.dart';

class SurgicalLogModel extends SurgicalLog {
  const SurgicalLogModel({
    required super.id,
    required super.procedure,
    required super.date,
    required super.hospital,
    required super.surgeon,
    required super.notes,
  });

  factory SurgicalLogModel.fromJson(Map<String, dynamic> json) {
    return SurgicalLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      procedure: json['procedure'] ?? '',
      date: json['date'] ?? json['createdAt']?.toString().split('T').first ?? 'Today',
      hospital: json['hospital'] ?? '',
      surgeon: json['surgeon'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'procedure': procedure,
      'date': date,
      'hospital': hospital,
      'surgeon': surgeon,
      'notes': notes,
    };
  }
}
