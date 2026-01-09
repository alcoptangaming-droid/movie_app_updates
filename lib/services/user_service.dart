import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qasioun_tv/model/user.dart';

class UserService {
  static const String _kCurrentUser = 'current_user';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================================================
  // 1. إدارة الجلسة المحلية (Session Management)
  // =========================================================

  /// جلب بيانات المستخدم الحالي من الذاكرة المحلية مع التحقق من الصلاحية
  static Future<AppUser?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kCurrentUser);
      if (s == null) return null;
      
      final user = AppUser.fromJson(json.decode(s));
      final now = DateTime.now().millisecondsSinceEpoch;

      // حساب الإدمن مستثنى من انتهاء الصلاحية التلقائي هنا
      if (user.username == 'QASUION') return user;

      // التحقق من انتهاء الصلاحية (تجريبي أو اشتراك رسمي)
      bool isExpired = false;
      if (user.subscriptionEnd != null && user.subscriptionEnd != 0 && now > user.subscriptionEnd!) {
        isExpired = true;
      } else if (user.trialEnd != null && user.trialEnd != 0 && now > user.trialEnd!) {
        isExpired = true;
      }

      if (isExpired) {
        await logout();
        return null;
      }
      return user;
    } catch (e) {
      print("Error getting current user: $e");
      return null;
    }
  }

  static Future<void> saveCurrentUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentUser, json.encode(user.toJson()));
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUser);
  }

  // =========================================================
  // 2. العمليات السحابية والمراقبة اللحظية
  // =========================================================

  /// فتح بث مباشر لمراقبة مستند المستخدم في Firestore
  /// يستخدم لطرد المستخدم فوراً عند الحذف أو انتهاء الاشتراك
  static Stream<DocumentSnapshot> userStatusStream(String username) {
    return _db.collection('users').doc(username).snapshots();
  }

  static Future<void> addUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.username).set(user.toJson());
      print("User added successfully to Cloud");
    } on FirebaseException catch (e) {
      print("Firebase Error: ${e.code}");
      rethrow;
    } catch (e) {
      print("Error adding user: $e");
      rethrow;
    }
  }

  static Future<void> updateUser(AppUser updatedUser) async {
    try {
      await _db.collection('users').doc(updatedUser.username).set(updatedUser.toJson(), SetOptions(merge: true));
      
      final currentUser = await getCurrentUser();
      if (currentUser?.username == updatedUser.username) {
        await saveCurrentUser(updatedUser);
      }
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  static Future<List<AppUser>> getUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching cloud users: $e");
      return [];
    }
  }

  static Future<void> deleteUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.username).delete();
      final currentUser = await getCurrentUser();
      if (currentUser?.username == user.username) {
        await logout();
      }
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  // =========================================================
  // 3. نظام تسجيل الدخول
  // =========================================================

  static Future<bool> login(String username, String password) async {
    // حساب الإدمن الثابت
    if (username == 'QASUION' && password == 'qasiountv0666') {
      final admin = AppUser(
        username: 'QASUION',
        displayName: 'Admin',
        phone: '+963945245117',
        countryCode: '+963',
        password: 'qasiountv0666',
        isAdmin: true,
        subscriptionMonths: 0,
        trialHours: 0,
        trialEnd: null,
        subscriptionEnd: null,
      );
      await saveCurrentUser(admin);
      return true;
    }

    try {
      final doc = await _db.collection('users').doc(username).get();
      
      if (doc.exists && doc.data() != null) {
        final foundUser = AppUser.fromJson(doc.data()!);
        
        if (foundUser.password == password) {
          // التحقق من الصلاحية قبل السماح بالدخول
          final now = DateTime.now().millisecondsSinceEpoch;
          if ((foundUser.subscriptionEnd != null && foundUser.subscriptionEnd != 0 && now > foundUser.subscriptionEnd!) ||
              (foundUser.trialEnd != null && foundUser.trialEnd != 0 && now > foundUser.trialEnd!)) {
            return false; // لا يسمح بالدخول إذا كان الاشتراك منتهياً
          }
          
          await saveCurrentUser(foundUser);
          return true;
        }
      }
    } catch (e) {
      print("Login error: $e");
    }
    
    return false;
  }

  static Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }
}