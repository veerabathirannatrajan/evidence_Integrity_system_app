import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase WITH options for web
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized for ${DefaultFirebaseOptions.currentPlatform}');
  } catch (e, stack) {
    print('❌ Firebase initialization error: $e');
    print('Stack trace: $stack');
  }

  runApp(const EvidenceApp());
}

class EvidenceApp extends StatelessWidget {
  const EvidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'EvidenceChain',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6DFF)),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}