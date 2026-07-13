import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/medical_record_model.dart';

abstract class MedicalRecordsRemoteDataSource {
  Future<List<MedicalRecordModel>> getMedicalRecords();
  Future<MedicalRecordModel> uploadMedicalRecord({
    required String title,
    required String recordType,
    required String fileUrl,
  });
  Future<void> shareMedicalRecord({
    required String recordId,
    required String doctorId,
    required int durationInHours,
  });
}

class MedicalRecordsRemoteDataSourceImpl implements MedicalRecordsRemoteDataSource {
  final Dio dio;

  MedicalRecordsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<MedicalRecordModel>> getMedicalRecords() async {
    try {
      final response = await dio.get(ApiConstants.records);
      if (response.data['success'] == true) {
        final List list = response.data['records'] ?? [];
        return list.map((item) => MedicalRecordModel.fromJson(item)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to fetch medical records');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MedicalRecordModel> uploadMedicalRecord({
    required String title,
    required String recordType,
    required String fileUrl,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.records,
        data: {
          'title': title,
          'recordType': recordType,
          'fileUrl': fileUrl,
          'fileType': 'pdf',
        },
      );
      if (response.data['success'] == true) {
        return MedicalRecordModel.fromJson(response.data['record']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to upload medical record');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> shareMedicalRecord({
    required String recordId,
    required String doctorId,
    required int durationInHours,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.shareRecord(recordId),
        data: {
          'doctorId': doctorId,
          'durationInHours': durationInHours,
        },
      );
      if (response.data['success'] != true) {
        throw ServerException(response.data['message'] ?? 'Failed to share medical record');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
