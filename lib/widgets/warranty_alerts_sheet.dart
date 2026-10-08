import 'package:flutter/material.dart';
import '../services/data_engine_hub.dart';
import '../services/whatsapp_dispatcher_service.dart';

class WarrantyAlertsSheet extends StatelessWidget {
  final VoidCallback? onDispatchTicket;

  const WarrantyAlertsSheet({super.key, this.onDispatchTicket});

  static void show(BuildContext context, {VoidCallback? onDispatchTicket}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF030712),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => WarrantyAlertsSheet(onDispatchTicket: onDispatchTicket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hub = DataEngineHub();
    final critical = hub.criticalWarrantyAlerts;
    final upcoming = hub.upcomingWarrantyAlerts;
    final expired = hub.expiredWarrantyAssets;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notification_important_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PREVENTIVE MAINTENANCE & SLA RADAR",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        "Hardware warranty expiration & preventive overhaul alerts",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),

          // Overview KPI Row
          Row(
            children: [
              _statusChip("CRITICAL (<=30D)", "${critical.length}", const Color(0xFFEF4444)),
              const SizedBox(width: 6),
              _statusChip("UPCOMING (31-90D)", "${upcoming.length}", const Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              _statusChip("EXPIRED / VOID", "${expired.length}", const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 12),

          // List of Expiring Hardware
          Expanded(
            child: critical.isEmpty && upcoming.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, color: const Color(0xFF10B981).withValues(alpha: 0.6), size: 42),
                        const SizedBox(height: 8),
                        const Text("All assets have healthy manufacturer warranty SLAs.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      if (critical.isNotEmpty) ...[
                        _sectionTitle("CRITICAL ACTION REQUIRED (<= 30 DAYS REMAINING)", const Color(0xFFEF4444)),
                        ...critical.map((asset) => _buildAssetCard(context, asset, isCritical: true)),
                        const SizedBox(height: 10),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _sectionTitle("UPCOMING PREVENTIVE OVERHAUL (31 - 90 DAYS)", const Color(0xFFF59E0B)),
                        ...upcoming.map((asset) => _buildAssetCard(context, asset, isCritical: false)),
                        const SizedBox(height: 10),
                      ],
                      if (expired.isNotEmpty) ...[
                        _sectionTitle("OUT OF WARRANTY / VOID SLA", const Color(0xFF64748B)),
                        ...expired.map((asset) => _buildAssetCard(context, asset, isExpired: true)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _statusChip(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 1),
            Text(label, style: TextStyle(color: color, fontSize: 6.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    AssetWarrantyRecord asset, {
    bool isCritical = false,
    bool isExpired = false,
  }) {
    Color cardColor = isCritical
        ? const Color(0xFFEF4444)
        : (isExpired ? const Color(0xFF64748B) : const Color(0xFFF59E0B));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExpired ? Icons.cancel_outlined : Icons.alarm_rounded,
              color: cardColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      asset.serialNumber,
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isExpired ? "EXPIRED" : "${asset.daysRemaining}d LEFT",
                        style: TextStyle(color: cardColor, fontSize: 6.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text("${asset.itemName} • PO: ${asset.poId}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                const SizedBox(height: 2),
                Text(
                  asset.installedSite != null
                      ? "📍 Installed: ${asset.installedSite}"
                      : "🚐 In Van Stock: ${asset.assignedVanPlate}",
                  style: TextStyle(
                    color: asset.installedSite != null ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Action button to notify or dispatch PM
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 16),
            tooltip: "WhatsApp Supplier / Client Alert",
            onPressed: () {
              final message = """
⚠️️ *PREVENTIVE MAINTENANCE & WARRANTY NOTICE*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Hardware: ${asset.itemName}
Serial No: ${asset.serialNumber}
PO Reference: ${asset.poId}
Vendor: ${asset.vendorName}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: ${isExpired ? 'EXPIRED' : '${asset.daysRemaining} Days Remaining'}
Expiry Date: ${asset.warrantyEndDate.day}/${asset.warrantyEndDate.month}/${asset.warrantyEndDate.year}
Location: ${asset.installedSite ?? asset.assignedVanPlate}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_Auto-generated via FieldOps SLA Watchdog_
""";
              WhatsAppDispatcherService().sendSiteReport(
                context: context,
                recipientPhone: "+60123456789",
                message: message,
              );
            },
          ),
        ],
      ),
    );
  }
}
