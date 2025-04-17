import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'package:flutter/services.dart';

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

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Mặc định là light, sẽ cập nhật khi theme thay đổi
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themeData = themeProvider.themeData;
        
        // Màu chính - xanh dương nhạt (sử dụng từ theme provider)
        final primaryColor = themeData['auxiliaryText'];
        final secondaryColor = themeProvider.isDarkMode 
            ? themeData['backCardColor'] 
            : themeData['typeColor'];
            
        // Màu overlay cho các card từ theme provider
        final cardOverlayColor = themeData['backCardColor'];
        
        // Màu nền từ theme provider
        final backgroundColor = Colors.transparent;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ứng Dụng Thời Tiết',
          theme: ThemeData(
            primaryColor: primaryColor,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: backgroundColor,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeData['mainText'],
              ),
              iconTheme: IconThemeData(
                color: themeData['mainText'],
              ),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withOpacity(0.3),
              color: cardOverlayColor.withOpacity(0.8),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: cardOverlayColor.withOpacity(0.8),
              selectedColor: primaryColor,
              secondarySelectedColor: secondaryColor,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              labelStyle: TextStyle(color: themeData['mainText']),
              secondaryLabelStyle: TextStyle(color: themeData['mainText']),
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
            colorScheme: ColorScheme(
              primary: primaryColor,
              secondary: secondaryColor,
              surface: cardOverlayColor.withOpacity(0.8),
              background: backgroundColor,
              error: Colors.red,
              onPrimary: themeData['mainText'],
              onSecondary: themeData['mainText'],
              onSurface: themeData['mainText'],
              onBackground: themeData['mainText'],
              onError: Colors.white,
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: themeData['mainText']),
              bodyMedium: TextStyle(color: themeData['mainText']),
              titleLarge: TextStyle(color: themeData['mainText']),
              titleMedium: TextStyle(color: themeData['mainText']),
            ),
          ),
          home: MainScreen(),
        );
      }
    );
  }
}