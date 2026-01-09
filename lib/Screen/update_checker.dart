import 'package:flutter/material.dart';
import 'package:qasioun_tv/services/update_service.dart';
import 'package:qasioun_tv/Screen/update_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  static bool _isDialogOpen = false; // لمنع فتح أكثر من نافذة
  
  static Future<void> checkAndShowUpdate(BuildContext context, {bool fromHomePage = false}) async {
    // منع التحقق المتكرر إذا كانت النافذة مفتوحة
    if (_isDialogOpen) {
      print('⏸️ نافذة التحديث مفتوحة بالفعل، تخطي التحقق');
      return;
    }
    
    try {
      print('🔍 === بدء التحقق من التحديثات ===');
      
      // الحصول على إصدار التطبيق الحالي
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      
      print('📱 معلومات الإصدار:');
      print('  - الإصدار: $currentVersion');
      print('  - رقم البناء: $buildNumber');
      print('  - اسم الحزمة: ${packageInfo.packageName}');
      
      // ✅ التحقق من وجود تحديث مع إرسال إصدار المستخدم الحقيقي
      print('🎯 جاري التحقق مع UpdateService...');
      final updateInfo = await UpdateService.checkForUpdate(currentVersion);
      
      print('📊 نتيجة التحقق من UpdateService:');
      print('  - update_available: ${updateInfo['update_available']}');
      print('  - current_version: ${updateInfo['current_version']}');
      print('  - latest_version: ${updateInfo['latest_version']}');
      print('  - force_update: ${updateInfo['force_update']}');
      print('  - success: ${updateInfo['success']}');
      print('  - error: ${updateInfo['error']}');
      
      // فقط إذا كان هناك تحديث متاح، عرض صفحة التحديث
      if (updateInfo['update_available'] == true && updateInfo['success'] == true) {
        print('🚀 هناك تحديث متاح! عرض صفحة التحديث...');
        print('📋 سبب العرض:');
        print('  - المستخدم بإصدار: ${updateInfo['current_version']}');
        print('  - هناك إصدار أحدث: ${updateInfo['latest_version']}');
        
        _isDialogOpen = true;
        
        Navigator.of(context).push(
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
                      print('⏸️ المستخدم ضغط "لاحقاً"');
                      _isDialogOpen = false;
                      Navigator.of(context).pop();
                    },
            ),
          ),
        ).then((_) {
          _isDialogOpen = false;
          print('✅ نافذة التحديث أغلقت');
        });
        
      } else {
        print('✅ لا يوجد تحديث متاح');
        print('📋 سبب عدم العرض:');
        if (updateInfo['success'] == false) {
          print('  - فشل عملية التحقق: ${updateInfo['error']}');
        } else if (updateInfo['update_available'] == false) {
          print('  - المستخدم محدث بالفعل');
        }
        
        if (fromHomePage && context.mounted) {
          // إذا كان التحقق من الصفحة الرئيسية، عرض رسالة للمستخدم
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ التطبيق محدث للإصدار الأخير'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ خطأ في التحقق من التحديث: $e');
      print('📋 تفاصيل الخطأ:');
      print('  - نوع الخطأ: ${e.runtimeType}');
      print('  - رسالة الخطأ: ${e.toString()}');
      
      if (fromHomePage && context.mounted) {
        // عرض رسالة خطأ للمستخدم
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ تعذر التحقق من التحديثات'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    print('🔍 === انتهى التحقق من التحديثات ===');
  }
  
  // ✅ دالة جديدة: التحقق السريع إذا كان هناك تحديث (دون عرض)
  static Future<bool> hasUpdateAvailable() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final updateInfo = await UpdateService.checkForUpdate(currentVersion);
      return updateInfo['update_available'] == true && updateInfo['success'] == true;
    } catch (e) {
      print('❌ خطأ في التحقق السريع: $e');
      return false;
    }
  }
  
  // ✅ دالة جديدة: الحصول على معلومات التحديث فقط
  static Future<Map<String, dynamic>?> getUpdateInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final updateInfo = await UpdateService.checkForUpdate(currentVersion);
      if (updateInfo['update_available'] == true && updateInfo['success'] == true) {
        return updateInfo;
      }
      return null;
    } catch (e) {
      print('❌ خطأ في الحصول على معلومات التحديث: $e');
      return null;
    }
  }
  
  // ✅ دالة جديدة: التحقق وإرجاع النتيجة مع الرسالة
  static Future<Map<String, dynamic>> checkUpdateWithMessage() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final updateInfo = await UpdateService.checkForUpdate(currentVersion);
      
      String message = 'تعذر التحقق من التحديثات';
      Color color = Colors.orange;
      bool hasUpdate = false;
      
      if (updateInfo['success'] == true) {
        if (updateInfo['update_available'] == true) {
          message = 'تحديث جديد متاح (${updateInfo['latest_version']})';
          color = Colors.blue;
          hasUpdate = true;
        } else {
          message = 'التطبيق محدث';
          color = Colors.green;
        }
      } else {
        message = 'فشل الاتصال بالسيرفر';
        color = Colors.orange;
      }
      
      return {
        'has_update': hasUpdate,
        'message': message,
        'color': color,
        'data': updateInfo,
      };
    } catch (e) {
      return {
        'has_update': false,
        'message': 'خطأ في التحقق: $e',
        'color': Colors.red,
        'data': null,
      };
    }
  }
  
  // ✅ دالة جديدة: التحقق وإرجاع تحليل مفصل
  static Future<Map<String, dynamic>> getDetailedUpdateAnalysis() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final updateInfo = await UpdateService.checkForUpdate(currentVersion);
      
      return {
        'user_version': currentVersion,
        'server_response': updateInfo,
        'analysis': _analyzeUpdateResult(currentVersion, updateInfo),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  // ✅ دالة خاصة لتحليل النتيجة
  static Map<String, dynamic> _analyzeUpdateResult(String userVersion, Map<String, dynamic> updateInfo) {
    final analysis = <String, dynamic>{};
    
    analysis['should_show_update'] = updateInfo['update_available'] == true;
    analysis['is_success'] = updateInfo['success'] == true;
    analysis['user_version'] = userVersion;
    analysis['target_version'] = updateInfo['latest_version'];
    
    // تحليل السبب
    if (!updateInfo['success']) {
      analysis['reason'] = 'فشل الاتصال بالسيرفر';
    } else if (updateInfo['update_available']) {
      analysis['reason'] = 'يوجد إصدار أحدث ($userVersion -> ${updateInfo['latest_version']})';
    } else {
      analysis['reason'] = 'المستخدم محدث بالفعل ($userVersion)';
    }
    
    // نصيحة بناءً على النتيجة
    if (updateInfo['update_available']) {
      analysis['advice'] = 'يجب عرض صفحة التحديث';
    } else {
      analysis['advice'] = 'لا يجب عرض صفحة التحديث';
    }
    
    return analysis;
  }
}