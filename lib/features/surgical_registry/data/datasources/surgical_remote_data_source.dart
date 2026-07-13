import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/surgical_log_model.dart';

abstract class SurgicalRemoteDataSource {
  Future<List<SurgicalLogModel>> getSurgicalLogs();
  Future<SurgicalLogModel> addSurgicalLog({
    required String procedure,
    required String hospital,
    required String surgeon,
    required String notes,
  });
}

class SurgicalRemoteDataSourceImpl implements SurgicalRemoteDataSource {
  final Dio dio;

  SurgicalRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SurgicalLogModel>> getSurgicalLogs() async {
    try {
      final response = await dio.get(ApiConstants.surgicalProducts);
      if (response.data['success'] == true) {
        final List list = response.data['products'] ?? [];
        return list.map((item) => SurgicalLogModel.fromJson(item)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load surgical items');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<SurgicalLogModel> addSurgicalLog({
    required String procedure,
    required String hospital,
    required String surgeon,
    required String notes,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.surgicalProducts,
        data: {
          'procedure': procedure,
          'hospital': hospital,
          'surgeon': surgeon,
          'notes': notes,
        },
      );
      if (response.data['success'] == true) {
        return SurgicalLogModel.fromJson(response.data['product']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to post surgical details');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
