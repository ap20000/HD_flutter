import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart'; 
import '../../domain/usecases/update_avatar_usecase.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class FakeAuthBloc extends Cubit<AuthState> {
  FakeAuthBloc() : super(AuthInitial());
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;
  final SharedPreferences sharedPreferences;

  static const _cachedUserKey = 'CACHED_USER';

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.verifyOtpUseCase,
    required this.updateAvatarUseCase,
    required this.sharedPreferences,
  }) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateAvatarRequested>(_onUpdateAvatarRequested);

    _checkCachedUser();
  }

  void _checkCachedUser() {
    final userJsonString = sharedPreferences.getString(_cachedUserKey);
    if (userJsonString != null) {
      try {
        final userMap = json.decode(userJsonString);
        final user = UserModel.fromJson(userMap);
        emit(AuthAuthenticated(user));
      } catch (e) {
        // Corrupted cache, do nothing
      }
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(loginId: event.loginId, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (event.rememberMe && user is UserModel) {
          sharedPreferences.setString(_cachedUserKey, json.encode(user.toJson()));
        } else if (event.rememberMe) {
          // If the usecase returns User instead of UserModel, cast or map it.
          // Since AuthRepositoryImpl returns Right(userModel as User), it is a UserModel.
          final userModel = user as UserModel;
          sharedPreferences.setString(_cachedUserKey, json.encode(userModel.toJson()));
        }
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        role: event.role,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (message) => emit(AuthOtpSent(phone: event.phone, message: message)),
    );
  }

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await verifyOtpUseCase(
      VerifyOtpParams(phone: event.phone, code: event.code),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    sharedPreferences.remove(_cachedUserKey);
    emit(AuthUnauthenticated());
  }

  Future<void> _onUpdateAvatarRequested(
    UpdateAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await updateAvatarUseCase(
      UpdateAvatarParams(base64Image: event.base64Image),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
