import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart'; // ← ADD THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // FOR WEB: Must provide options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized for ${DefaultFirebaseOptions.currentPlatform}');
  } catch (e, stack) {
    print('❌ Firebase error: $e');
    print('Stack: $stack');
  }

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

