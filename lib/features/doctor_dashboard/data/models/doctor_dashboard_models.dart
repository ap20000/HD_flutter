import 'package:hamro_doctor_mobile/features/doctor_dashboard/domain/entities/doctor_dashboard_data.dart';

class DoctorStatsModel extends DoctorStats {
  const DoctorStatsModel({
    required super.noOfConsultations,
    required super.articlesPublished,
    required super.noOfStories,
    required super.netEarnings,
  });

  factory DoctorStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorStatsModel(
      noOfConsultations: json['noOfConsultations'] ?? 0,
      articlesPublished: json['articlesPublished'] ?? 0,
      noOfStories: json['noOfStories'] ?? 0,
      netEarnings: (json['netEarnings'] ?? 0.0).toDouble(),
    );
  }
}

class WorkplaceModel extends Workplace {
  const WorkplaceModel({
    required super.id,
    required super.name,
    required super.address,
    required super.opdTime,
  });

  factory WorkplaceModel.fromJson(Map<String, dynamic> json) {
    return WorkplaceModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      opdTime: (json['opdTime'] as List? ?? [])
          .map((e) => OpdTimeModel.fromJson(e))
          .toList(),
    );
  }
}

class OpdTimeModel extends OpdTime {
  const OpdTimeModel({
    required super.day,
    required super.startTime,
    required super.endTime,
  });

  factory OpdTimeModel.fromJson(Map<String, dynamic> json) {
    return OpdTimeModel(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }
}
