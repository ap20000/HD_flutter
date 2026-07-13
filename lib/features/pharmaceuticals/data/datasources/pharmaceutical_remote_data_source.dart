import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/medicine_model.dart';

abstract class PharmaceuticalRemoteDataSource {
  Future<List<MedicineModel>> getMedicines();
  Future<MedicineModel> addMedicine({
    required String name,
    required String generic,
    required String category,
    required String details,
  });
}

class PharmaceuticalRemoteDataSourceImpl implements PharmaceuticalRemoteDataSource {
  final Dio dio;

  PharmaceuticalRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<MedicineModel>> getMedicines() async {
    try {
      final response = await dio.get(ApiConstants.pharmaMedicines);
      if (response.data['success'] == true) {
        final List list = response.data['medicines'] ?? [];
        return list.map((item) => MedicineModel.fromJson(item)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load medicines');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MedicineModel> addMedicine({
    required String name,
    required String generic,
    required String category,
    required String details,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.pharmaMedicines,
        data: {
          'name': name,
          'generic': generic,
          'category': category,
          'details': details,
        },
      );
      if (response.data['success'] == true) {
        return MedicineModel.fromJson(response.data['medicine']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to post medicine listing');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
