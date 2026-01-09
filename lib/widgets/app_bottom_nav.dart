import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final bool isAdmin;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = const Color(0xFF081830), // لون افتراضي متناسق
    this.selectedItemColor = const Color(0xFFFDD835), // اللون الأصفر المميز
    this.unselectedItemColor = Colors.white,
    required this.isAdmin,
  });

  // دالة فتح الواتساب الخاصة بالدعم الفني
  static Future<void> openWhatsApp() async {
    final msg = Uri.encodeComponent(
        'مرحباً فريق شركة سـوا الـمـتـحـدة\n\nأود الاستفسار عن خدمات تطبيق Qasuion TV');
    final url = 'https://wa.me/963945245117?text=$msg';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor,
      type: BottomNavigationBarType.fixed, // لضمان ظهور أكثر من 3 عناصر بشكل سليم
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'بحث',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.live_tv),
          label: 'بث مباشر',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.message, color: Colors.green), // زر الواتساب
          label: 'تواصل معنا',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'حسابي',
        ),
      ],
    );
  }
}