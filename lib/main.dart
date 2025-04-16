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
    // Màu overlay cho các card - #2B3866 với opacity 80%
    const cardOverlayColor = Color(0xFF2B3866);
    // Thay đổi background color thành transparent
    const backgroundColor = Colors.transparent;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ứng Dụng Thời Tiết',
      theme: ThemeData(
        primaryColor: primaryColor,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withOpacity(0.3),
          // Thêm màu card với độ trong suốt theo yêu cầu
          color: cardOverlayColor.withOpacity(0.8),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardOverlayColor.withOpacity(0.8),
          selectedColor: primaryColor,
          secondarySelectedColor: secondaryColor,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TextStyle(color: Colors.white),
          secondaryLabelStyle: TextStyle(color: Colors.white),
          brightness: Brightness.dark,
        ),
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardOverlayColor.withOpacity(0.8),
          background: backgroundColor,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: MainScreen(),
    );
  }
}
