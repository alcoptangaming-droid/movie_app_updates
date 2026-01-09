import 'package:flutter/foundation.dart'; // للتمييز بين الويب والموبايل
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:qasioun_tv/Screen/splash_screen.dart';

Future<void> main() async {
  // 1. التأكد من تثبيت أدوات فلاتر الأساسية
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ضبط اتجاه الشاشة ليكون عمودياً فقط (مناسب لأغلب تطبيقات الموبايل)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. تشغيل فايربيز بناءً على المنصة
  try {
    if (kIsWeb) {
      // إعدادات الويب باستخدام البيانات الخاصة بمشروعك 
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC8x4KI_ppVVcEU349iAwSnX2FkEomHdlo",
          authDomain: "qasiountv-5ef03.firebaseapp.com",
          projectId: "qasiountv-5ef03",
          storageBucket: "qasiountv-5ef03.firebasestorage.app",
          messagingSenderId: "720588387016",
          appId: "1:720588387016:web:4eebb33eb9d60e93d72bfd",
          measurementId: "G-5VLQYT7PFT",
        ),
      );
    } else {
      // للموبايل (Android & iOS)
      // سيعتمد تلقائياً على ملف google-services.json للأندرويد 
      // وعلى ملف GoogleService-Info.plist للـ iOS الذي قمت برفعه 
      await Firebase.initializeApp();
    }
    print("✅ تم تشغيل Firebase بنجاح");
  } catch (e) {
    // طباعة الخطأ في حال وجود مشكلة في الإعدادات
    print("❌ خطأ في تشغيل Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qasioun TV',
      debugShowCheckedModeBanner: false,
      // ضبط الثيم ليكون داكن (Dark Mode) كما في ملف pubspec الخاص بك 
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFDD835), // اللون الأصفر المميز
        scaffoldBackgroundColor: const Color(0xFF040C1A),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDD835),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFDD835),
          secondary: Color(0xFFFDD835),
          surface: Color(0xFF081830),
        ),
        useMaterial3: true,
      ),
      // ضبط اللغة الافتراضية للعربية
      locale: const Locale('ar', 'AE'),
      // الشاشة الافتتاحية للتطبيق
      home: const SplashScreen(),
    );
  }
}