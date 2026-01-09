import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:math' as math;

class UpdateService {
  // رابط الـ JSON
  static const String updateJsonUrl = 'https://api.npoint.io/443dc58abab893b77935';
  
  // رابط APK احتياطي
  static const String fallbackApkUrl = 'https://github.com/etopiaapp-cmyk/casioun_tv/releases/latest/download/app-release.apk';
  
  // ✅ الدالة الرئيسية - منطق جديد تماماً
  static Future<Map<String, dynamic>> checkForUpdate(String userCurrentVersion) async {
    try {
      print('🎯 === بدء التحقق من التحديثات ===');
      print('📱 إصدار المستخدم الحقيقي: $userCurrentVersion');
      
      // ⭐⭐ **التحقق الأول: إذا كان المستخدم محدثاً (1.1.0 أو أعلى)** ⭐⭐
      final bool isUserUpdated = _isVersionAtLeast(userCurrentVersion, '1.1.0');
      
      if (isUserUpdated) {
        print('🎉 ⭐⭐ المستخدم محدث (1.1.0 أو أعلى) ⭐⭐');
        print('⏸️ **تجاهل كل إعدادات التحديث من JSON**');
        
        return _createForceNoUpdateResponse(
          userVersion: userCurrentVersion,
          reason: 'user_already_updated_to_1_1_0',
          message: 'المستخدم محدث بالإصدار $userCurrentVersion - لا تحديث',
        );
      }
      
      // جلب إعدادات التحديث من السيرفر (للمستخدمين القدامى فقط)
      print('📡 جلب إعدادات التحديث للمستخدمين القدامى...');
      final response = await http.get(
        Uri.parse(updateJsonUrl),
        headers: {'Cache-Control': 'no-cache'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ تم جلب بيانات JSON بنجاح');
        
        // قراءة القيم من JSON
        final bool updateEnabled = _parseBool(data['update_available'], false);
        
        // ⭐ إذا كان التحديث معطلاً في JSON، لا تعرض
        if (!updateEnabled) {
          print('⏸️ التحديث معطل في السيرفر');
          return _createNoUpdateResponse(
            userVersion: userCurrentVersion,
            reason: 'update_disabled_in_json',
          );
        }
        
        final String targetVersion = data['target_version']?.toString() ?? 
                                    data['latest_version']?.toString() ?? '1.1.0';
        
        final String minVersion = data['min_version']?.toString() ?? '1.0.0';
        
        final bool forceUpdate = _parseBool(data['force_update'], false);
        
        print('📊 إعدادات التحديث من السيرفر:');
        print('  - التحديث مفعّل: $updateEnabled');
        print('  - الإصدار المستهدف: $targetVersion');
        print('  - الحد الأدنى للإصدار: $minVersion');
        print('  - تحديث إجباري: $forceUpdate');
        
        // ⭐⭐ **التحقق الثاني: هل المستخدم بإصدار قديم؟**
        final bool isOldVersion = _isVersionLessOrEqual(userCurrentVersion, minVersion);
        
        if (!isOldVersion) {
          print('🚀 المستخدم ليس بإصدار قديم ($userCurrentVersion > $minVersion)');
          return _createNoUpdateResponse(
            userVersion: userCurrentVersion,
            reason: 'user_version_newer_than_min',
          );
        }
        
        // ⭐⭐ **التحقق الثالث: هل هناك إصدار أحدث؟**
        final bool hasNewerVersion = _isVersionGreater(targetVersion, userCurrentVersion);
        
        if (!hasNewerVersion) {
          print('⚠️ لا يوجد إصدار أحدث ($targetVersion <= $userCurrentVersion)');
          return _createNoUpdateResponse(
            userVersion: userCurrentVersion,
            reason: 'no_newer_version_available',
          );
        }
        
        // ⭐⭐ **كل الشروط متحققة: هناك تحديث للمستخدم القديم**
        print('✅ ⭐⭐ هناك تحديث للمستخدم القديم ⭐⭐');
        print('  - المستخدم: $userCurrentVersion');
        print('  - الإصدار الجديد: $targetVersion');
        print('  - تحديث إجباري من JSON: $forceUpdate');
        
        // ⭐ هنا فقط نستخدم forceUpdate من JSON
        return {
          'update_available': true,
          'current_version': userCurrentVersion,
          'latest_version': targetVersion,
          'download_url': data['download_url']?.toString() ?? fallbackApkUrl,
          'release_notes': data['release_notes']?.toString() ?? 'تحديث جديد متوفر',
          'force_update': forceUpdate, // ⭐ للمستخدمين القدامى فقط
          'github_release': _parseBool(data['github_release'], false),
          'success': true,
          'reason': 'update_for_old_version',
          'note': 'للمستخدمين بإصدار 1.0.0 فقط',
        };
        
      } else {
        print('⚠️ فشل جلب بيانات التحديث');
        return _getDefaultResponse(userCurrentVersion, reason: 'fetch_failed');
      }
    } catch (e) {
      print('❌ خطأ في التحقق: $e');
      return _getDefaultResponse(userCurrentVersion, reason: 'exception: $e');
    }
  }
  
  // ✅ ⭐⭐ الدالة الحاسمة: تحقق إذا كان الإصدار >= الإصدار المحدد
  static bool _isVersionAtLeast(String userVersion, String minVersion) {
    try {
      print('🔍 التحقق: هل $userVersion >= $minVersion ؟');
      
      if (_areVersionsEqual(userVersion, minVersion)) {
        print('  ✅ نعم، متساويان');
        return true;
      }
      
      final bool isGreater = _isVersionGreater(userVersion, minVersion);
      print('  ${isGreater ? '✅ نعم، أحدث' : '❌ لا، أقدم'}');
      return isGreater;
      
    } catch (e) {
      print('❌ خطأ في _isVersionAtLeast: $e');
      return false;
    }
  }
  
  // ✅ دالة خاصة: إنشاء رد "لا تحديث إطلاقاً"
  static Map<String, dynamic> _createForceNoUpdateResponse({
    required String userVersion,
    required String reason,
    required String message,
  }) {
    print('⏸️ ⭐⭐ رد قوي: لا تحديث للمستخدم المحدث ⭐⭐');
    print('  - السبب: $message');
    
    return {
      'update_available': false,  // ⭐⭐ مهما حدث
      'current_version': userVersion,
      'latest_version': userVersion,
      'download_url': '',
      'release_notes': '',
      'force_update': false,      // ⭐⭐ حتى لو كان true في JSON
      'github_release': false,
      'success': true,
      'reason': reason,
      'message': message,
      'force_block': true,        // ⭐⭐ علامة حجب قوي
    };
  }
  
  // ✅ دالة مساعدة: إنشاء رد "لا يوجد تحديث"
  static Map<String, dynamic> _createNoUpdateResponse({
    required String userVersion,
    required String reason,
  }) {
    return {
      'update_available': false,
      'current_version': userVersion,
      'latest_version': userVersion,
      'download_url': '',
      'release_notes': '',
      'force_update': false,
      'github_release': false,
      'success': true,
      'reason': reason,
    };
  }
  
  // ✅ دالة مساعدة: هل الإصداران متساويان؟
  static bool _areVersionsEqual(String version1, String version2) {
    try {
      final v1 = _cleanVersion(version1);
      final v2 = _cleanVersion(version2);
      return v1 == v2;
    } catch (e) {
      return false;
    }
  }
  
  // ✅ دالة مساعدة: هل الإصدار الأول <= الثاني؟
  static bool _isVersionLessOrEqual(String version1, String version2) {
    try {
      if (_areVersionsEqual(version1, version2)) return true;
      
      final v1 = _cleanVersion(version1);
      final v2 = _cleanVersion(version2);
      
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      
      final maxLength = math.max(parts1.length, parts2.length);
      
      for (int i = 0; i < maxLength; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        
        if (p1 < p2) return true;
        if (p1 > p2) return false;
      }
      
      return true;
    } catch (e) {
      print('❌ خطأ في _isVersionLessOrEqual: $e');
      return false;
    }
  }
  
  // ✅ دالة مساعدة: هل الإصدار الأول > الثاني؟
  static bool _isVersionGreater(String version1, String version2) {
    try {
      if (_areVersionsEqual(version1, version2)) return false;
      
      final v1 = _cleanVersion(version1);
      final v2 = _cleanVersion(version2);
      
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      
      for (int i = 0; i < parts1.length; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        
        if (p1 > p2) return true;
        if (p1 < p2) return false;
      }
      
      return false;
    } catch (e) {
      print('❌ خطأ في _isVersionGreater: $e');
      return false;
    }
  }
  
  // ✅ تنظيف الإصدار
  static String _cleanVersion(String version) {
    return version.replaceAll(RegExp(r'[^0-9.]'), '');
  }
  
  // ✅ تحويل القيم إلى boolean
  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }
  
  // ✅ استجابة افتراضية عند الخطأ
  static Map<String, dynamic> _getDefaultResponse(String userVersion, {String reason = 'error'}) {
    return {
      'update_available': false,
      'current_version': userVersion,
      'latest_version': userVersion,
      'download_url': '',
      'release_notes': '',
      'force_update': false,
      'github_release': false,
      'success': false,
      'reason': reason,
    };
  }
  
  // ✅ دالة للحصول على الإصدار الحالي
  static Future<String> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.1.0';
    }
  }
}