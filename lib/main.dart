import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ ADDED
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against duplicate-app error on hot restart
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 🔥 FIREBASE APP CHECK (ADDED - SAFE FOR ALL PLATFORMS)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,     // Android (dev)
    appleProvider: AppleProvider.debug,         // iOS/macOS
    webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_KEY'), // Web (optional)
  );

  runApp(const EvidenceApp());
}

class EvidenceApp extends StatelessWidget {
  const EvidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: 'EvidenceChain',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.light,
          darkTheme: ThemeProvider.dark,
          themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}