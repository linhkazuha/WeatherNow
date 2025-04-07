import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Màu chính - xanh dương nhạt
    const primaryColor = Color(0xFF64B5F6);
    const secondaryColor = Color(0xFF90CAF9);
    const backgroundColor = Color(0xFFE3F2FD);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ứng Dụng Thời Tiết',
      theme: ThemeData(
        primaryColor: primaryColor,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.blue.withOpacity(0.2),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: primaryColor,
          secondarySelectedColor: secondaryColor,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TextStyle(color: Colors.black87),
          secondaryLabelStyle: TextStyle(color: Colors.white),
          brightness: Brightness.light,
        ),
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: backgroundColor,
        ),
      ),
      home: MainScreen(),
    );
  }
}