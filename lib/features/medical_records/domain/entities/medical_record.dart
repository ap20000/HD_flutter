import 'package:equatable/equatable.dart';

class MedicalRecord extends Equatable {
  final String id;
  final String title;
  final String recordType;
  final String date;
  final String fileSize;
  final String? sharedWith;
  final String? shareDuration;

  const MedicalRecord({
    required this.id,
    required this.title,
    required this.recordType,
    required this.date,
    required this.fileSize,
    this.sharedWith,
    this.shareDuration,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        recordType,
        date,
        fileSize,
        sharedWith,
        shareDuration,
      ];
}
