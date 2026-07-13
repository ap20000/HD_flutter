import 'package:equatable/equatable.dart';

class Medicine extends Equatable {
  final String id;
  final String name;
  final String generic;
  final String category;
  final String manufacturer;
  final String formulation;
  final String details;

  const Medicine({
    required this.id,
    required this.name,
    required this.generic,
    required this.category,
    required this.manufacturer,
    required this.formulation,
    required this.details,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        generic,
        category,
        manufacturer,
        formulation,
        details,
      ];
}
