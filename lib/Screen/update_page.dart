import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatelessWidget {
  final String updateUrl;
  final String currentVersion;
  final String newVersion;
  final String releaseNotes;
  final bool isForceUpdate;
  final bool isGithubRelease;
  final VoidCallback? onSkipUpdate; 

  const UpdatePage({
    super.key,
    required this.updateUrl,
    required this.currentVersion,
    required this.newVersion,
    required this.releaseNotes,
    this.isForceUpdate = false,
    this.isGithubRelease = true,
    this.onSkipUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040C1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // رمز أو شعار التطبيق
              Container(
                margin: const EdgeInsets.only(top: 40, bottom: 20),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF081830),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFFDD835).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Image.asset(
                    'assets/app/app.PNG',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDD835),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.system_update,
                          size: 60,
                          color: Colors.black,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // العنوان
              Text(
                isForceUpdate ? "تحديث إجباري" : "تحديث جديد متاح",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              if (isForceUpdate) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    "يجب التحديث للمتابعة",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // رسالة التحديث والانتظار
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1E40),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFFDD835).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFDD835),
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "حدث التطبيق وانتظر 24 ساعة",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "نعتذر عن الوقت الإضافي، لكن هذا في مصلحتك\nلتجربة أفضل وأكثر استقراراً",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // الإصدارات
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF081830),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFFDD835).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          "الإصدار الحالي",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentVersion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Icon(
                        Icons.arrow_forward,
                        color: const Color(0xFFFDD835).withOpacity(0.7),
                        size: 30,
                      ),
                    ),
                    
                    Column(
                      children: [
                        Text(
                          "الإصدار الجديد",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          newVersion,
                          style: const TextStyle(
                            color: Color(0xFFFDD835),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // قسم ملاحظات الإصدار (تمت معالجة الخط الأصفر هنا)
              Expanded(
                child: Material(
                  color: Colors.transparent, // للحفاظ على خلفية الـ Scaffold
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081830),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFDD835).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.description,
                              color: Color(0xFFFDD835),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isGithubRelease ? "تحديث من MediaFire" : "تحديث التطبيق",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "ما الجديد في هذا الإصدار:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              releaseNotes.isEmpty ? 
                              "• تحسينات كبيرة في الأداء والسرعة\n• إصلاح الأخطاء السابقة\n• تحسين تجربة المستخدم\n• تعزيز أمان التطبيق" : 
                              releaseNotes,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ملاحظة الوقت
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.blue.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "ستختفي صفحة التحديث تلقائياً بعد 24 ساعة",
                      style: TextStyle(
                        color: Colors.blue.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              // الأزرار
              Row(
                children: [
                  if (!isForceUpdate && onSkipUpdate != null)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onSkipUpdate,
                        child: const Text("لاحقاً"),
                      ),
                    ),
                  
                  if (!isForceUpdate && onSkipUpdate != null) const SizedBox(width: 15),
                  
                  // زر التحديث
                  Expanded(
                    flex: isForceUpdate ? 2 : 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD835),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(updateUrl))) {
                          await launchUrl(Uri.parse(updateUrl));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تعذر فتح رابط التحديث"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isGithubRelease ? Icons.download : Icons.update),
                          const SizedBox(width: 8),
                          const Text(
                            "تحديث الآن",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}