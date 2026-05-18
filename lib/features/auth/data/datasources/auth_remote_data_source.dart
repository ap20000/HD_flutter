import 'package:dio/dio.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import '../../../../core/network/auth_interceptor.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String loginId, String password);
  Future<String> register(String name, String email, String phone, String password, String role);
  Future<UserModel> verifyOtp(String phone, String code);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String loginId, String password) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {
          'loginId': loginId,
          'password': password,
        },
      );

      if (response.data['success']) {
        final token = response.data['token'];
        AuthInterceptor.token = token;
        return UserModel.fromJson(
          response.data['user'],
          token: token,
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<String> register(String name, String email, String phone, String password, String role) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        },
      );

      if (response.data['success']) {
        return response.data['message'] ?? 'Registration successful';
      } else {
        throw ServerException(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<UserModel> verifyOtp(String phone, String code) async {
    try {
      final response = await dio.post(
        ApiConstants.verifyOtp,
        data: {
          'phone': phone,
          'code': code,
        },
      );

      if (response.data['success']) {
        final token = response.data['token'];
        AuthInterceptor.token = token;
        return UserModel.fromJson(
          response.data['user'],
          token: token,
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Verification failed');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }
}
