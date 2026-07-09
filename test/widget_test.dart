import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_doctor_mobile/injection_container.dart' as di;
import 'package:hamro_doctor_mobile/main.dart';

void main() {
  setUpAll(() async {
    // Avoid GetIt duplicate registrations if run repeatedly
    await di.sl.reset();
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    di.sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
    await di.init();
  });

  testWidgets('App initialization and splash page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that SplashPage starts loading and displays the progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Verify that the splash page texts are present
    expect(find.text('ThirdPole Health'), findsOneWidget);
    expect(find.text('Your Health, Our Priority'), findsOneWidget);

    // Advance clock to trigger and clear the navigation timer (3.2 seconds)
    await tester.pump(const Duration(seconds: 4));
  });
}
