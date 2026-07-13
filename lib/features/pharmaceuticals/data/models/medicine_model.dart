import '../../domain/entities/medicine.dart';

class MedicineModel extends Medicine {
  const MedicineModel({
    required super.id,
    required super.name,
    required super.generic,
    required super.category,
    required super.manufacturer,
    required super.formulation,
    required super.details,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      generic: json['generic'] ?? '',
      category: json['category'] ?? '',
      manufacturer: json['manufacturer'] ?? 'General',
      formulation: json['formulation'] ?? 'Tablet',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'generic': generic,
      'category': category,
      'manufacturer': manufacturer,
      'formulation': formulation,
      'details': details,
    };
  }
}
