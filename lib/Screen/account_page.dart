import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qasioun_tv/Screen/login_page.dart';
import 'package:qasioun_tv/services/user_service.dart';
import 'package:qasioun_tv/model/user.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _loggedIn = false;
  AppUser? _currentUser;
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = true;
  bool _passwordVisible = false;

  final Color _backgroundColor = const Color(0xFF040C1A);
  final Color _boxColor = const Color(0xFF081830);
  final Color _accentColor = const Color(0xFFFDD835);

  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  String _selectedCountryCode = '+963';
  String _selectedSubscription = '12 ساعة';

  // قائمة الدول العربية كاملة
  final List<Map<String, String>> _countryCodes = [
    {'code': '+963', 'flag': '🇸🇾'}, {'code': '+966', 'flag': '🇸🇦'},
    {'code': '+971', 'flag': '🇦🇪'}, {'code': '+20', 'flag': '🇪🇬'},
    {'code': '+962', 'flag': '🇯🇴'}, {'code': '+961', 'flag': '🇱🇧'},
    {'code': '+974', 'flag': '🇶🇦'}, {'code': '+965', 'flag': '🇰🇼'},
    {'code': '+968', 'flag': '🇴🇲'}, {'code': '+973', 'flag': '🇧🇭'},
    {'code': '+249', 'flag': '🇸🇩'}, {'code': '+212', 'flag': '🇲🇦'},
    {'code': '+213', 'flag': '🇩🇿'}, {'code': '+216', 'flag': '🇹🇳'},
    {'code': '+218', 'flag': '🇱🇾'}, {'code': '+967', 'flag': '🇾🇪'},
    {'code': '+964', 'flag': '🇮🇶'}, {'code': '+970', 'flag': '🇵🇸'},
    {'code': '+252', 'flag': '🇸🇴'}, {'code': '+222', 'flag': '🇲🇷'},
    {'code': '+253', 'flag': '🇩🇯'}, {'code': '+269', 'flag': '🇰🇲'},
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);
    final user = await UserService.getCurrentUser();
    if (user != null) {
      setState(() {
        _loggedIn = true;
        _currentUser = user;
      });
      if (user.isAdmin) await _refreshUsersList();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refreshUsersList() async {
    final users = await UserService.getUsers();
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers
          .where((u) => u.username.toLowerCase().contains(query.toLowerCase()) || 
                        u.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // رسالة تحذير عند الحذف
  Future<void> _confirmDelete(AppUser user) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _boxColor,
        title: const Text("تنبيه الحذف", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("هل أنت متأكد من حذف حساب (${user.displayName}) نهائياً؟", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء", style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await UserService.deleteUser(user);
              Navigator.pop(ctx);
              _refreshUsersList();
            },
            child: const Text("حذف الآن", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // وظيفة لعرض سياسة الخصوصية
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _boxColor,
        title: const Text("سياسة الخصوصية", 
          style: TextStyle(color: Color(0xFFFDD835), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _privacySection(
                "1. المعلومات التي يقدمها المستخدم",
                "قد يطلب التطبيق من المستخدم تقديم بعض البيانات عند التسجيل أو استخدام الميزات، مثل:\n\n• الاسم الكامل (إن وجد)\n• رقم الهاتف\n• كلمة المرور أو بيانات تسجيل الدخول\n• أي معلومات يتم إرسالها عبر الدعم الفني أو نموذج التواصل"
              ),
              const SizedBox(height: 16),
              _privacySection(
                "2. مشاركة المعلومات",
                "لا نقوم ببيع أو تأجير بيانات المستخدمين.\nقد تتم مشاركة البيانات فقط مع:\n\n• مزودي الخدمات (الاستضافة، الدفع، البث المباشر)\n• شركاء الإعلانات (إن تم تفعيل الإعلانات داخل التطبيق)\n• الجهات القانونية عند وجود طلب رسمي أو التزام قانوني\n• شركاء المحتوى عند الحاجة لضمان حقوق البث\n\nيتم مشاركة البيانات بالحد الأدنى اللازم لتقديم الخدمة."
              ),
              const SizedBox(height: 16),
              _privacySection(
                "3. حماية البيانات",
                "نستخدم مجموعة من الإجراءات لحماية بيانات المستخدم، مثل:\n\n• تشفير الاتصال عبر HTTPS\n• أنظمة كشف ومنع الاختراق\n• تخزين آمن للبيانات\n\nومع ذلك، لا يمكن ضمان حماية مطلقة بنسبة 100%."
              ),
              
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("موافق", style: TextStyle(color: Color(0xFFFDD835))),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _privacySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  // وظيفة لعرض معلومات المستخدم المفصلة
  void _showUserDetails(AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _boxColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
          left: 20, right: 20, top: 20
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2)
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _accentColor,
                  child: const Icon(Icons.person, size: 50, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
              Center(
                child: Text(
                  "@${user.username}",
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 30),
              
              // قسم معلومات الحساب
              // اسم المستخدم مع زر النسخ
              _buildDetailRowWithCopy(
                icon: Icons.person_outline,
                title: "اسم المستخدم",
                value: user.username,
                copyText: user.username,
                copyLabel: "اسم المستخدم",
              ),
              
              // كلمة المرور مع زر النسخ
              _buildDetailRowWithCopy(
                icon: Icons.lock_outline,
                title: "كلمة المرور",
                value: user.password,
                copyText: user.password,
                copyLabel: "كلمة المرور",
                showValue: true, // عرض القيمة بشكل واضح
              ),
              
              _buildDetailRow(
                icon: Icons.phone,
                title: "رقم الهاتف",
                value: user.phone,
              ),
              _buildDetailRow(
                icon: Icons.code,
                title: "رمز الدولة",
                value: user.countryCode,
              ),
              _buildDetailRow(
                icon: Icons.admin_panel_settings,
                title: "صلاحية المستخدم",
                value: user.isAdmin ? "مدير" : "مستخدم عادي",
                valueColor: user.isAdmin ? Colors.green : Colors.blue,
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              
              // قسم معلومات الاشتراك
              const Text(
                "معلومات الاشتراك",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 10),
              
              if (user.trialHours > 0)
                _buildDetailRow(
                  icon: Icons.timer,
                  title: "التجربة",
                  value: "${user.trialHours} ساعة",
                  valueColor: Colors.orange,
                ),
              
              if (user.subscriptionMonths > 0)
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  title: "مدة الاشتراك",
                  value: "${user.subscriptionMonths} شهر",
                  valueColor: Colors.green,
                ),
              
              _buildDetailRow(
                icon: Icons.access_time,
                title: "الحالة",
                value: _getSubscriptionStatus(user),
                valueColor: _getStatusColor(user),
              ),
              
              if (user.trialEnd != null)
                _buildDetailRow(
                  icon: Icons.timer_off,
                  title: "انتهاء التجربة",
                  value: _formatDate(user.trialEnd!),
                  valueColor: Colors.orange,
                ),
              
              if (user.subscriptionEnd != null)
                _buildDetailRow(
                  icon: Icons.date_range,
                  title: "انتهاء الاشتراك",
                  value: _formatDate(user.subscriptionEnd!),
                  valueColor: Colors.green,
                ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              
              // العداد الخاص بالمستخدم
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor.withOpacity(0.3))
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "الوقت المتبقي",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14
                        ),
                      ),
                      const SizedBox(height: 8),
                      UserCountdownTimer(user: user),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "إغلاق",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لعرض صف مع زر النسخ
  Widget _buildDetailRowWithCopy({
    required IconData icon,
    required String title,
    required String value,
    required String copyText,
    required String copyLabel,
    bool showValue = true,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFDD835), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15
              ),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accentColor.withOpacity(0.3))
                  ),
                  child: Text(
                    showValue ? value : "••••••••",
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Courier', // خط ثابت لعرض النصوص بشكل أفضل
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    // نسخ النص إلى الحافظة
                    Clipboard.setData(ClipboardData(text: copyText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("تم نسخ $copyLabel"),
                        backgroundColor: _accentColor,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.content_copy, size: 16, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        "نسخ",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لعرض صف المعلومات
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFDD835), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 15
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // دالة لتنسيق التاريخ
  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // دالة للحصول على حالة الاشتراك
  String _getSubscriptionStatus(AppUser user) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (user.trialEnd != null && now < user.trialEnd!) {
      return "تجريبية";
    } else if (user.subscriptionEnd != null && now < user.subscriptionEnd!) {
      return "نشط";
    } else if (user.subscriptionEnd == null && user.trialEnd == null) {
      return "مدى الحياة";
    } else {
      return "منتهي";
    }
  }

  // دالة للحصول على لون الحالة
  Color _getStatusColor(AppUser user) {
    final status = _getSubscriptionStatus(user);
    switch (status) {
      case "نشط":
        return Colors.green;
      case "تجريبية":
        return Colors.orange;
      case "مدى الحياة":
        return const Color(0xFFFDD835);
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: _backgroundColor, body: const Center(child: CircularProgressIndicator(color: Color(0xFFFDD835))));
    if (!_loggedIn) return const LoginPage();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("حسابي", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _boxColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip, color: Color(0xFFFDD835)), 
            onPressed: _showPrivacyPolicy,
            tooltip: "سياسة الخصوصية",
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent), 
            onPressed: () async {
              await UserService.logout();
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => const LoginPage()), 
                (route) => false
              );
            },
            tooltip: "تسجيل الخروج",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUsersList,
        color: _accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              if (_currentUser!.isAdmin) _buildAdminPanel() else _buildSupportButton(),
              const SizedBox(height: 24),
              // زر سياسة الخصوصية للمستخدمين العاديين
              if (!_currentUser!.isAdmin) _buildPrivacyButton(),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentUser!.isAdmin 
          ? FloatingActionButton(
              backgroundColor: _accentColor, 
              child: const Icon(Icons.person_add, color: Colors.black), 
              onPressed: () => _showAddUserModal(),
            ) 
          : null,
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _boxColor, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: _accentColor.withOpacity(0.3))
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40, 
            backgroundColor: _accentColor, 
            child: const Icon(Icons.person, size: 50, color: Colors.black)
          ),
          const SizedBox(height: 15),
          Text(
            _currentUser!.displayName, 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          Text(
            "@${_currentUser!.username}", 
            style: const TextStyle(color: Colors.white60)
          ),
          const SizedBox(height: 20),
          UserCountdownTimer(user: _currentUser!),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(Icons.phone, size: 16, color: _accentColor),
              const SizedBox(width: 8),
              Text(_currentUser!.phone, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "إدارة المستخدمين (${_allUsers.length})", 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: _filterUsers,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "بحث...",
            prefixIcon: Icon(Icons.search, color: _accentColor),
            filled: true, 
            fillColor: _boxColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide.none
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredUsers.length,
          itemBuilder: (context, index) {
            final user = _filteredUsers[index];
            String subType = user.trialHours > 0 ? "تجربة 12 ساعة" : 
                            (user.subscriptionMonths == 0 ? "مدى الحياة" : "اشتراك ${user.subscriptionMonths} شهر");

            return Card(
              color: _boxColor,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  user.displayName, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subType, 
                      style: TextStyle(
                        color: _accentColor.withOpacity(0.8), 
                        fontSize: 13, 
                        fontWeight: FontWeight.w500
                      )
                    ),
                    UserCountdownTimer(user: user),
                  ],
                ),
                // إضافة زر المعلومات قبل زر الحذف
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر عرض المعلومات
                    IconButton(
                      icon: Icon(Icons.info_outline, color: Colors.blue[300]),
                      onPressed: () => _showUserDetails(user),
                      tooltip: "عرض التفاصيل",
                    ),
                    // زر الحذف
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent), 
                      onPressed: () => _confirmDelete(user),
                      tooltip: "حذف المستخدم",
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrivacyButton() {
    return ElevatedButton.icon(
      onPressed: _showPrivacyPolicy,
      icon: const Icon(Icons.privacy_tip, color: Color(0xFFFDD835)),
      label: const Text("سياسة الخصوصية", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _boxColor,
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: _accentColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildSupportButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final url = 'https://wa.me/963945245117';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        }
      },
      icon: const Icon(Icons.support_agent, color: Colors.white),
      label: const Text("الدعم الفني"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, 
        minimumSize: const Size(double.infinity, 50)
      ),
    );
  }

  void _showAddUserModal() {
    _displayName.clear(); 
    _username.clear(); 
    _password.clear(); 
    _phone.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _boxColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "إضافة مستخدم", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _displayName, 
                decoration: _inputDeco("الاسم الكامل"), 
                style: const TextStyle(color: Colors.white)
              ),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24), 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    dropdownColor: _boxColor,
                    underline: const SizedBox(),
                    items: _countryCodes.map((c) => DropdownMenuItem(
                      value: c['code'], 
                      child: Text(
                        "${c['flag']} ${c['code']}", 
                        style: const TextStyle(color: Colors.white, fontSize: 14)
                      )
                    )).toList(),
                    onChanged: (v) => setModalState(() => _selectedCountryCode = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phone, 
                    keyboardType: TextInputType.number, 
                    decoration: _inputDeco("الهاتف"), 
                    style: const TextStyle(color: Colors.white)
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _username, 
                decoration: _inputDeco("اليوزر نيم"), 
                style: const TextStyle(color: Colors.white)
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password, 
                decoration: _inputDeco("الباسورد"), 
                style: const TextStyle(color: Colors.white),
                obscureText: !_passwordVisible,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedSubscription,
                dropdownColor: _boxColor,
                style: const TextStyle(color: Colors.white),
                items: ['12 ساعة','1 أشهر','3 أشهر', '6 أشهر', '12 شهر', 'مدى الحياة']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
                onChanged: (v) => setModalState(() => _selectedSubscription = v!),
                decoration: _inputDeco("الاشتراك"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor, 
                  minimumSize: const Size(double.infinity, 50)
                ),
                onPressed: () async {
                  int? tEnd, sEnd; 
                  int tH = 0, sM = 0;
                  
                  if (_selectedSubscription == '12 ساعة') {
                    tEnd = DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch; 
                    tH = 12;
                  } else if (_selectedSubscription != 'مدى الحياة') {
                    sM = int.parse(_selectedSubscription.split(' ')[0]);
                    sEnd = DateTime.now().add(Duration(days: sM * 30)).millisecondsSinceEpoch;
                  }
                  
                  final newUser = AppUser(
                    username: _username.text.trim(), 
                    displayName: _displayName.text.trim(), 
                    phone: '$_selectedCountryCode ${_phone.text.trim()}',
                    countryCode: _selectedCountryCode, 
                    password: _password.text.trim(), 
                    isAdmin: false,
                    subscriptionMonths: sM, 
                    trialHours: tH, 
                    trialEnd: tEnd, 
                    subscriptionEnd: sEnd,
                  );
                  
                  await UserService.addUser(newUser);
                  Navigator.pop(context); 
                  _refreshUsersList();
                },
                child: const Text(
                  "إنشاء", 
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, 
    labelStyle: const TextStyle(color: Colors.white60), 
    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))
  );
}

class UserCountdownTimer extends StatefulWidget {
  final AppUser user;
  const UserCountdownTimer({super.key, required this.user});
  @override
  State<UserCountdownTimer> createState() => _UserCountdownTimerState();
}

class _UserCountdownTimerState extends State<UserCountdownTimer> {
  late Timer _timer;
  String _timeStr = "";
  
  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }
  
  @override
  void dispose() { 
    _timer.cancel(); 
    super.dispose(); 
  }
  
  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    int? end = widget.user.trialEnd ?? widget.user.subscriptionEnd;
    
    if (end == null) { 
      setState(() => _timeStr = "مدى الحياة"); 
      return; 
    }
    
    final diff = end - now;
    if (diff <= 0) { 
      setState(() => _timeStr = "منتهي"); 
      return; 
    }
    
    Duration d = Duration(milliseconds: diff);
    setState(() => _timeStr = "${d.inDays}ي ${d.inHours % 24}س ${d.inMinutes % 60}د ${d.inSeconds % 60}ث");
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(
      _timeStr, 
      style: TextStyle(
        color: _timeStr == "منتهي" ? Colors.red : const Color(0xFFFDD835), 
        fontWeight: FontWeight.bold, 
        fontSize: 14
      )
    );
  }
}