import 'package:equatable/equatable.dart';

class DoctorStats extends Equatable {
  final int noOfConsultations;
  final int articlesPublished;
  final int noOfStories;
  final double netEarnings;

  const DoctorStats({
    required this.noOfConsultations,
    required this.articlesPublished,
    required this.noOfStories,
    required this.netEarnings,
  });

  @override
  List<Object?> get props => [noOfConsultations, articlesPublished, noOfStories, netEarnings];
}

class Workplace extends Equatable {
  final String id;
  final String name;
  final String address;
  final List<OpdTime> opdTime;

  const Workplace({
    required this.id,
    required this.name,
    required this.address,
    required this.opdTime,
  });

  @override
  List<Object?> get props => [id, name, address, opdTime];
}

class OpdTime extends Equatable {
  final String day;
  final String startTime;
  final String endTime;

  const OpdTime({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [day, startTime, endTime];
}
