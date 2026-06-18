import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamro_doctor_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/presentation/bloc/patient_dashboard_bloc.dart';
import 'injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Hamro Doctor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'features/auth/presentation/pages/otp_verification_page.dart';
// import 'features/auth/presentation/bloc/auth_bloc.dart';

// void main() {
//   runApp(const MyTestApp());
// }

// class MyTestApp extends StatelessWidget {
//   const MyTestApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: BlocProvider(
//         create: (_) => FakeAuthBloc(),
//         child: const OtpVerificationPage(phone: "+977 9800000000"),
//       ),
//     );
//   }
// }
