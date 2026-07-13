import '../../domain/entities/medical_record.dart';

class MedicalRecordModel extends MedicalRecord {
  const MedicalRecordModel({
    required super.id,
    required super.title,
    required super.recordType,
    required super.date,
    required super.fileSize,
    super.sharedWith,
    super.shareDuration,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      recordType: json['recordType'] ?? 'Report',
      date: json['date'] ?? json['createdAt']?.toString().split('T').first ?? 'Today',
      fileSize: json['fileSize'] ?? '1.2 MB • PDF',
      sharedWith: json['sharedWith']?['name'],
      shareDuration: json['shareDuration'] != null ? '${json['shareDuration']}h left' : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'recordType': recordType,
      'date': date,
      'fileSize': fileSize,
      'sharedWith': sharedWith,
      'shareDuration': shareDuration,
    };
  }
}
