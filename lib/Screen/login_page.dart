import 'package:flutter/material.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/Screen/HomePage.dart';
import 'package:qasioun_tv/widgets/app_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false; // لمتابعة حالة الاتصال بالسحابة

  // الهوية البصرية للتطبيق
  final Color _backgroundColor = const Color(0xFF040C1A);
  final Color _boxColor = const Color(0xFF081830);
  final Color _accentColor = const Color(0xFFFDD835);
  final Color _textColor = Colors.white;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  // دالة تسجيل الدخول السحابية المعدلة
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // استدعاء دالة تسجيل الدخول التي تبحث في Firestore
      final bool success = await UserService.login(
        _username.text.trim(),
        _password.text.trim(),
      );

      if (success) {
        if (mounted) {
          // الانتقال للصفحة الرئيسية عند نجاح الدخول
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("اسم المستخدم أو كلمة المرور غير صحيحة", textAlign: TextAlign.center),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ في الاتصال بالسحابة: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('تسجيل دخول', style: TextStyle(color: Colors.white)),
        backgroundColor: _boxColor,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/app/app.PNG', fit: BoxFit.contain), //
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار التطبيق
                Image.asset(
                  'assets/app/app.PNG',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'مرحباً بك',
                  style: TextStyle(color: _textColor, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  'الرجاء إدخال بيانات الدخول السحابية الخاصة بك',
                  style: TextStyle(color: _textColor.withOpacity(0.6), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // حقل اسم المستخدم
                _buildInputContainer(
                  child: TextFormField(
                    controller: _username,
                    style: TextStyle(color: _textColor),
                    textAlign: TextAlign.right,
                    decoration: _inputDecoration('اسم المستخدم', Icons.person),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'ادخل اسم المستخدم' : null,
                  ),
                ),
                const SizedBox(height: 20),

                // حقل كلمة المرور
                _buildInputContainer(
                  child: TextFormField(
                    controller: _password,
                    obscureText: !_passwordVisible,
                    style: TextStyle(color: _textColor),
                    textAlign: TextAlign.right,
                    decoration: _inputDecoration('كلمة المرور', Icons.lock).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          color: _textColor.withOpacity(0.6),
                        ),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'ادخل كلمة المرور' : null,
                  ),
                ),
                const SizedBox(height: 30),

                // زر تسجيل الدخول مع مؤشر تحميل
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'دخول',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF040C1A)),
                          ),
                  ),
                ),
                const SizedBox(height: 15),

                // زر اتصل بنا (واتساب)
                _buildWhatsAppButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _boxColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _textColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 4), blurRadius: 8)
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      hintText: hint,
      hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: _accentColor.withOpacity(0.8)),
    );
  }

  Widget _buildWhatsAppButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          final msg = Uri.encodeComponent('مرحباً فريق شركة سـوا الـمـتـحـدة\nأنا هنا لطلب الإشتراك في تطبيق qasuion.tv');
          final uri = Uri.parse('https://wa.me/963945245117?text=$msg');
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            print('Could not launch WhatsApp');
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: _textColor,
          side: BorderSide(color: _textColor.withOpacity(0.3), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent),
            SizedBox(width: 8),
            Text('اتصل بنا (واتساب)', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}