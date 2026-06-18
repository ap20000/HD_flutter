import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/patient_dashboard/presentation/pages/patient_dashboard_page.dart';
import '../../features/doctor_dashboard/presentation/pages/doctor_dashboard_page.dart';
import '../../features/auth/domain/entities/user.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationPage(phone: phone);
        },
      ),
      GoRoute(
        path: '/patient-dashboard',
        builder: (context, state) {
          final user = state.extra as User?;
          if (user == null) {
            // In a real API integration, if user is not provided, redirect to login or throw.
            throw Exception('User data is required to access Patient Dashboard');
          }
          return PatientDashboardPage(user: user);
        },
      ),
      GoRoute(
        path: '/doctor-dashboard',
        builder: (context, state) {
          final user = state.extra as User?;
          if (user == null) {
            throw Exception('User data is required to access Doctor Dashboard');
          }
          return DoctorDashboardPage(user: user);
        },
      ),
    ],
  );
}
