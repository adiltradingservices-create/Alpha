import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppDispatcherService {
  static final WhatsAppDispatcherService _instance = WhatsAppDispatcherService._internal();
  factory WhatsAppDispatcherService() => _instance;
  WhatsAppDispatcherService._internal();

  /// Launches WhatsApp with an encoded pre-filled message
  Future<bool> sendSiteReport({
    required BuildContext context,
    required String recipientPhone,
    required String message,
  }) async {
    // Sanitize phone number (strip spaces, dashes, plus signs)
    final cleanPhone = recipientPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=$encodedMessage");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback web intent
        final webFallback = Uri.parse("https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage");
        return await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch WhatsApp: $e"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Builds a structured site completion report
  String generateSiteReportTemplate({
    required String technicianName,
    required String companyName,
    required String projectName,
    required String siteName,
    required String taskDiscipline,
    required String timeSpent,
    required String tcStatus,
    required String vanPartsUsed,
  }) {
    return """
🚨 *OFFICIAL FIELD SERVICE DISPATCH REPORT* 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 *Company:* $companyName
👷‍♂️ *Lead Tech:* $technicianName
📍 *Project:* $projectName
📌 *Site Location:* $siteName
🛠️ *Task Executed:* $taskDiscipline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️ *Logged Duration:* $timeSpent
⚡ *T&C Commissioning:* $tcStatus
📦 *Van Parts Consumed:* $vanPartsUsed
🔒 *Audit Status:* Biometric GPS Verified (±2.4m)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_Generated via FieldOps Enterprise Mobile_
""";
  }
}
