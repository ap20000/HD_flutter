import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/doctor_dashboard_models.dart';
import '../../../patient_dashboard/data/models/dashboard_models.dart';

abstract class DoctorDashboardRemoteDataSource {
  Future<DoctorStatsModel> getStats();
  Future<List<WorkplaceModel>> getWorkplaces();
  Future<List<ConsultationModel>> getConsultations();
  Future<bool> updateStatus(bool isOnline);
  Future<void> respondToConsultation(String consultationId, String status);
  Future<ConsultationModel> getConsultationById(String id);
}

class DoctorDashboardRemoteDataSourceImpl implements DoctorDashboardRemoteDataSource {
  final Dio dio;

  DoctorDashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DoctorStatsModel> getStats() async {
    try {
      final response = await dio.get(ApiConstants.getDoctorStats);
      if (response.data['success']) {
        return DoctorStatsModel.fromJson(response.data['stats']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch stats');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<List<WorkplaceModel>> getWorkplaces() async {
    try {
      final response = await dio.get(ApiConstants.getDoctorHospitals);
      if (response.data['success']) {
        final List list = response.data['hospitals'] ?? [];
        return list.map((e) => WorkplaceModel.fromJson(e)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch hospitals');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<List<ConsultationModel>> getConsultations() async {
    try {
      final response = await dio.get(ApiConstants.getConsultations);
      if (response.data['success']) {
        final List list = response.data['consultations'] ?? [];
        return list.map((e) => ConsultationModel.fromJson(e)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch consultations');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<bool> updateStatus(bool isOnline) async {
    try {
      final response = await dio.patch(
        ApiConstants.updateDoctorStatus,
        data: {'isOnline': isOnline},
      );
      if (response.data['success']) {
        return response.data['isOnline'];
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to update status');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<void> respondToConsultation(String consultationId, String status) async {
    try {
      final response = await dio.patch(
        ApiConstants.respondToConsultation(consultationId),
        data: {'status': status},
      );
      if (!response.data['success']) {
        throw ServerException(response.data['message'] ?? 'Failed to respond to consultation');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<ConsultationModel> getConsultationById(String id) async {
    try {
      final response = await dio.get('/api/${ApiConstants.apiVersion}/consultations/$id');
      if (response.data['success']) {
        return ConsultationModel.fromJson(response.data['consultation']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch consultation details');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }
}
