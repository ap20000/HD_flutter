import 'package:dio/dio.dart';
import 'package:hamro_doctor_mobile/core/network/dio_client.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import '../../../../core/network/auth_interceptor.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String loginId, String password);
  Future<String> register(
    String name,
    String email,
    String phone,
    String password,
    String role,
  );
  Future<UserModel> verifyOtp(String phone, String code);
  Future<UserModel> updateAvatar(String base64Image);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String loginId, String password) async {
    try {
      print('================ LOGIN REQUEST ================');
      print('URL: ${dio.options.baseUrl}${ApiConstants.login}');
      print('loginId: $loginId');

      final response = await dio.post(
        ApiConstants.login,
        data: {'loginId': loginId, 'password': password},
      );

      print('================ LOGIN RESPONSE ================');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.data['success']) {
        final token = response.data['token'];
        AuthInterceptor.token = token;

        return UserModel.fromJson(response.data['user'], token: token);
      } else {
        throw ServerException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      print('================ DIO ERROR ================');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      print('Error: ${e.error}');
      print('Status Code: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request Data: ${e.requestOptions.data}');

      throw ServerException(
        e.response?.data?['message'] ?? e.message ?? 'Connection error',
      );
    } catch (e, stackTrace) {
      print('================ UNKNOWN ERROR ================');
      print(e);
      print(stackTrace);

      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> register(
    String name,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'username': name.isNotEmpty ? name : phone,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        },
      );

      if (response.data['success']) {
        return response.data['message'] ?? 'Registration successful';
      } else {
        throw ServerException(
          response.data['message'] ?? 'Registration failed',
        );
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
        data: {'phone': phone, 'code': code},
      );

      if (response.data['success']) {
        final token = response.data['token'];
        AuthInterceptor.token = token;
        return UserModel.fromJson(response.data['user'], token: token);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Verification failed',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }

  @override
  Future<UserModel> updateAvatar(String base64Image) async {
    try {
      final response = await dio.post(
        ApiConstants.uploadAvatar,
        data: {'image': base64Image},
      );

      if (response.data['success']) {
        return UserModel.fromJson(
          response.data['user'],
          token: AuthInterceptor.token,
        );
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to update avatar',
        );
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Connection error');
    }
  }
}
