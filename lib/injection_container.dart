import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'core/constants/constants.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/verify_otp_usecase.dart';
import 'features/auth/domain/usecases/update_avatar_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/patient_dashboard/data/datasources/patient_dashboard_remote_data_source.dart';
import 'features/patient_dashboard/data/repositories/patient_dashboard_repository_impl.dart';
import 'features/patient_dashboard/domain/repositories/patient_dashboard_repository.dart';
import 'features/patient_dashboard/domain/usecases/dashboard_usecases.dart';
import 'features/patient_dashboard/presentation/bloc/patient_dashboard_bloc.dart';
import 'features/doctor_dashboard/data/datasources/doctor_dashboard_remote_data_source.dart';
import 'features/doctor_dashboard/data/repositories/doctor_dashboard_repository_impl.dart';
import 'features/patient_dashboard/domain/usecases/request_consultation_usecase.dart';
import 'features/doctor_dashboard/domain/repositories/doctor_dashboard_repository.dart';
import 'features/doctor_dashboard/domain/usecases/doctor_dashboard_usecases.dart';
import 'features/doctor_dashboard/presentation/bloc/doctor_dashboard_bloc.dart';
import 'core/services/socket_service.dart';
import 'features/consultation_room/core/webrtc_helper.dart';
import 'features/consultation_room/presentation/bloc/consultation_room_bloc.dart';

import 'core/network/auth_interceptor.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      verifyOtpUseCase: sl(),
      updateAvatarUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PatientDashboardBloc(
      getDoctorsUseCase: sl(),
      getArticlesUseCase: sl(),
      getLatestHealthRecordUseCase: sl(),
      getConsultationsUseCase: sl(),
      requestConsultationUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => DoctorDashboardBloc(
      getStatsUseCase: sl(),
      getWorkplacesUseCase: sl(),
      getConsultationsUseCase: sl(),
      updateStatusUseCase: sl(),
      respondToConsultationUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ConsultationRoomBloc(
      socketService: sl(),
      webrtcHelper: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAvatarUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorsUseCase(sl()));
  sl.registerLazySingleton(() => GetArticlesUseCase(sl()));
  sl.registerLazySingleton(() => GetLatestHealthRecordUseCase(sl()));
  sl.registerLazySingleton(() => GetConsultationsUseCase(sl()));
  sl.registerLazySingleton(() => RequestConsultationUseCase(sl()));

  sl.registerLazySingleton(() => GetDoctorStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorWorkplacesUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorConsultationsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDoctorStatusUseCase(sl()));
  sl.registerLazySingleton(() => RespondToConsultationUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<PatientDashboardRepository>(
    () => PatientDashboardRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<DoctorDashboardRepository>(
    () => DoctorDashboardRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<PatientDashboardRemoteDataSource>(
    () => PatientDashboardRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<DoctorDashboardRemoteDataSource>(
    () => DoctorDashboardRemoteDataSourceImpl(dio: sl()),
  );

  // External
  sl.registerLazySingleton(() {
    final dio = Dio();
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.interceptors.add(AuthInterceptor());
    return dio;
  });

  // Services & Helpers
  sl.registerLazySingleton(() => SocketService());
  sl.registerLazySingleton(() => WebRTCHelper());
}
