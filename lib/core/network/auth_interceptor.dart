import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  static String? token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}
