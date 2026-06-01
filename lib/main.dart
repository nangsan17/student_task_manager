import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) await NotificationService().init();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(SPTMApp(showOnboarding: !onboardingDone));
}

class SPTMApp extends StatelessWidget {
  final bool showOnboarding;
  const SPTMApp({super.key, required this.showOnboarding});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'SPTM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          Widget content = MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(MediaQuery.of(context)
                      .textScaleFactor
                      .clamp(0.85, 1.15))),
              child: child!);
          if (kIsWeb) {
            content = Scaffold(
                backgroundColor: const Color(0xFF0F0F1A),
                body: Center(
                    child: Container(
                        width: 390,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 60,
                                  spreadRadius: 8)
                            ]),
                        child: content)));
          }
          return content;
        },
        home: showOnboarding ? const OnboardingScreen() : const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)));
        }
        return snap.hasData ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
