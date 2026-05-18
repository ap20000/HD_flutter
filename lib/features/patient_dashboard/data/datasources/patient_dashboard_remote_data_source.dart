import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/dashboard_models.dart';

abstract class PatientDashboardRemoteDataSource {
  Future<List<DoctorModel>> getDoctors();
  Future<List<ArticleModel>> getArticles();
  Future<HealthRecordModel?> getLatestHealthRecord();
  Future<List<ConsultationModel>> getConsultations();
  Future<void> requestConsultation(String doctorId);
}

class PatientDashboardRemoteDataSourceImpl implements PatientDashboardRemoteDataSource {
  final Dio dio;

  PatientDashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<DoctorModel>> getDoctors() async {
    try {
      final response = await dio.get(ApiConstants.getDoctors);
      if (response.data['success']) {
        final List doctorsJson = response.data['doctors'] ?? [];
        return doctorsJson.map((json) => DoctorModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch doctors');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<List<ArticleModel>> getArticles() async {
    try {
      final response = await dio.get(ApiConstants.getArticles);
      if (response.data['success']) {
        final List articlesJson = response.data['articles'] ?? [];
        return articlesJson.map((json) => ArticleModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch articles');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<HealthRecordModel?> getLatestHealthRecord() async {
    try {
      final response = await dio.get(ApiConstants.getRecords);
      if (response.data['success']) {
        final bmiJson = response.data['bmi'];
        if (bmiJson == null) return null;
        return HealthRecordModel.fromJson(bmiJson);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch records');
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
        final List consultationsJson = response.data['consultations'] ?? [];
        return consultationsJson.map((json) => ConsultationModel.fromJson(json)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch consultations');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<void> requestConsultation(String doctorId) async {
    try {
      final response = await dio.post(
        ApiConstants.requestConsultation,
        data: {'doctorId': doctorId},
      );
      if (!response.data['success']) {
        throw ServerException(response.data['message'] ?? 'Failed to request consultation');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }
}
