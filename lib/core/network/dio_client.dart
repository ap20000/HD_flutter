import 'package:dio/dio.dart';
import '../constants/constants.dart';

class DioClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            request: true,
            requestBody: true,
            responseBody: true,
            error: true,
          ),
        );
}
