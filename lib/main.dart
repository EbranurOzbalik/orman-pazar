import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const OrmanPazarApp());
}

class OrmanPazarApp extends StatelessWidget {
  const OrmanPazarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.forestGreen,
          primary: AppConstants.forestGreen,
          secondary: AppConstants.woodBrown,
          surface: AppConstants.cardBackground,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: AppConstants.forestGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppConstants.cardBackground,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
