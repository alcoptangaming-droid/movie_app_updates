import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportChatFab extends StatelessWidget {
  const SupportChatFab({super.key});

  static const _phone = '963945245117';
  static const _message = '''مرحباً فريق شركة سـوا الـمـتـحـدة

أنا هنا لطلب تجديد اشتراكي في تطبيق qasuion.tv

شـركـة ســوا الـمـتـحـدة لـلـتـصـمـيم والـبـرمـجـة  www.saway.store''';

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _launchWhatsApp,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      child: const Icon(Icons.headset_mic),
    );
  }

  void _launchWhatsApp() async {
    final encoded = Uri.encodeComponent(_message);
    // Build a properly encoded WhatsApp URL
    final realUri = Uri.parse('https://wa.me/$_phone?text=$encoded');
    if (!await launchUrl(realUri, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      print('Could not launch WhatsApp');
    }
  }
}
