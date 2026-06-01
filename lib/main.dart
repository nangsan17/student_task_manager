import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) await NotificationService().init();
  runApp(const SPTMApp());
}

class SPTMApp extends StatelessWidget {
  const SPTMApp({super.key});
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
          // Web: show as a centered phone-sized window
          if (kIsWeb) {
            content = Scaffold(
                backgroundColor: const Color(0xFF13131F),
                body: Center(
                    child: Container(
                        width: 390,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 50,
                                  spreadRadius: 5)
                            ]),
                        child: content)));
          }
          return content;
        },
        home: const _AuthGate(),
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
