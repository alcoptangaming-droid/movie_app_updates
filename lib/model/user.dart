class AppUser {
  final String username; // login username
  final String displayName;
  final String phone; // full phone with code
  final String countryCode;
  final String password;
  final bool isAdmin;
  final int subscriptionMonths; // 0 = lifetime, -1 = trial
  final int trialHours;
  final int? trialEnd; // epoch millis to represent trial expiry datetime
  final int? subscriptionEnd; // epoch millis to represent subscription expiry

  AppUser({
    required this.username,
    required this.displayName,
    required this.phone,
    required this.countryCode,
    required this.password,
    this.isAdmin = false,
    this.subscriptionMonths = 0,
    this.trialHours = 0,
    this.trialEnd,
    this.subscriptionEnd,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'phone': phone,
        'countryCode': countryCode,
        'password': password,
        'isAdmin': isAdmin,
        'subscriptionMonths': subscriptionMonths,
        'trialHours': trialHours,
        'trialEnd': trialEnd,
        'subscriptionEnd': subscriptionEnd,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        username: j['username'] ?? '',
        displayName: j['displayName'] ?? '',
        phone: j['phone'] ?? '',
        countryCode: j['countryCode'] ?? '',
        password: j['password'] ?? '',
        isAdmin: j['isAdmin'] ?? false,
        subscriptionMonths: j['subscriptionMonths'] ?? 0,
        trialHours: j['trialHours'] ?? 0,
        trialEnd: j['trialEnd'],
        subscriptionEnd: j['subscriptionEnd'],
      );
}
