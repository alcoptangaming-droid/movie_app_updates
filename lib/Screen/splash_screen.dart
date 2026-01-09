import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qasioun_tv/Screen/HomePage.dart';
import 'package:qasioun_tv/Screen/login_page.dart';
import 'package:qasioun_tv/Screen/update_page.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // ⏱ بعد 3 ثوانٍ نبدأ عملية التهيئة
    Timer(const Duration(seconds: 3), _initializeApp);
  }

  Future<void> _initializeApp() async {
    try {
      print('🔍 === بدء تهيئة التطبيق ===');
      
      // ✅ 1. الحصول على إصدار التطبيق الحقيقي للمستخدم
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      final packageName = packageInfo.packageName;
      
      print('📱 معلومات الإصدار الحقيقي:');
      print('  - الإصدار: $currentVersion');
      print('  - رقم البناء: $buildNumber');
      print('  - اسم الحزمة: $packageName');
      
      // ✅ 2. التحقق من وجود تحديث (مع إرسال إصدار المستخدم الحقيقي)
      print('🎯 جاري التحقق من التحديثات...');
      final updateInfo = await UpdateService.checkForUpdate(currentVersion);
      
      print('📊 نتيجة التحقق من التحديث:');
      print('  - هل هناك تحديث؟: ${updateInfo['update_available']}');
      print('  - إصدار المستخدم: ${updateInfo['current_version']}');
      print('  - الإصدار الجديد: ${updateInfo['latest_version']}');
      print('  - تحديث إجباري: ${updateInfo['force_update']}');
      print('  - عملية ناجحة: ${updateInfo['success']}');
      
      // ✅ 3. إذا كان هناك تحديث متاح للمستخدم
      if (updateInfo['update_available'] == true && updateInfo['success'] == true) {
        print('🚀 هناك تحديث متاح! عرض صفحة التحديث...');
        
        // الانتقال إلى صفحة التحديث
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UpdatePage(
                updateUrl: updateInfo['download_url'],
                currentVersion: currentVersion,
                newVersion: updateInfo['latest_version'],
                releaseNotes: updateInfo['release_notes'],
                isForceUpdate: updateInfo['force_update'],
                isGithubRelease: updateInfo['github_release'],
                onSkipUpdate: updateInfo['force_update'] == true 
                    ? null 
                    : () {
                        print('⏸️ المستخدم ضغط "لاحقاً" - الانتقال للتطبيق');
                        _goToAppPage();
                      },
              ),
            ),
          );
        }
      } else {
        print('✅ لا يوجد تحديث، الانتقال مباشرة للتطبيق...');
        // ✅ الانتقال إلى التطبيق مباشرة
        _goToAppPage();
      }
    } catch (e) {
      print('❌ خطأ في عملية التهيئة: $e');
      print('⚠️ بسبب الخطأ، ننتقل للتطبيق مباشرة...');
      
      // في حالة الخطأ، اذهب للتطبيق مباشرة
      if (mounted) {
        _goToAppPage();
      }
    }
  }

  void _goToAppPage() async {
    try {
      print('🏠 الانتقال إلى الصفحة المناسبة...');
      
      final user = await UserService.getCurrentUser();
      
      if (user == null) {
        print('👤 لا يوجد مستخدم مسجل، الانتقال لصفحة تسجيل الدخول');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        print('👤 المستخدم مسجل بالفعل، الانتقال للصفحة الرئيسية');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      print('❌ خطأ في _goToAppPage: $e');
      // في حالة الخطأ، اذهب لصفحة تسجيل الدخول
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020814),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app/splash.png',
              width: 500,
              height: 400,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFFFDD835),
              strokeWidth: 3,
            ),
            const SizedBox(height: 15),
            const Text(
              'جاري التحميل...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'الإصدار: ${snapshot.data!.version}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }
}