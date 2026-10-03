import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CompletionModal extends StatelessWidget {
  final String workOrderId;
  final String downloadUrl;
  final String clientName;
  final String assetCode;
  final String totalDuration;
  final VoidCallback onDismiss;

  const CompletionModal({
    super.key,
    required this.workOrderId,
    required this.downloadUrl,
    required this.clientName,
    required this.assetCode,
    required this.totalDuration,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOffline = workOrderId == "OFFLINE-BUFFER";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0F1D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
            color: isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            isOffline ? 'SAVED TO LOCAL STORAGE' : 'TASK DISPATCHED & VERIFIED',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text('ID: $workOrderId â€¢ $clientName', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Asset: $assetCode", style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 12)),
                Text("Duration: $totalDuration", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isOffline) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF06B6D4), size: 18),
                label: const Text('VIEW SIGNED PDF ONLINE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF25D366))),
                icon: const Icon(Icons.share, color: Color(0xFF25D366), size: 18),
                label: const Text('DISPATCH VIA WHATSAPP', style: TextStyle(color: Color(0xFF25D366), fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final msg = "FieldOps Sheet ($workOrderId):\nClient: $clientName\nAsset: $assetCode\n\nLink:\n$downloadUrl";
                  launchUrl(Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}"), mode: LaunchMode.externalApplication);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
              onPressed: onDismiss,
              child: const Text('CLOSE & NEXT TASK', style: TextStyle(color: Color(0xFF070B14), fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
