import 'package:edu_kids_app/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_provider.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'services/notification_service.dart';
import 'services/global_event_reminder_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  await NotificationService.scheduleDailyReminder();
  await NotificationService.scheduleStreakWarning(0);
  await GlobalEventReminderService.init();
  await GlobalEventReminderService.scheduleAllGlobalEventReminders();
  await AudioService.init();
  await AudioService.playHomeBgm();

  runApp(const EduKidsApp());
}

class EduKidsApp extends StatelessWidget {
  const EduKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'EduKids - Belajar Seru!',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const AppWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminLoginScreen(),
        },
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const SplashScreen();
        }
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
