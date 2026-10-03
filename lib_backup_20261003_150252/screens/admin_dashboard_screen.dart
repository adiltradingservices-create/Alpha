import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/user_session.dart';
import '../services/locale_service.dart';
import '../widgets/language_selector.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;
  const AdminDashboardScreen({super.key, required this.session, required this.onLogout});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _workOrders = [];
  List<dynamic> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      final headers = {
        'x-tenant-id': widget.session.tenantId,
        'x-user-role': widget.session.role,
      };

      final woRes = await http.get(
        Uri.parse("https://api.alphatechnetworks.com/api/admin/work-orders"),
        headers: headers,
      );
      final invRes = await http.get(
        Uri.parse("https://api.alphatechnetworks.com/api/inventory"),
        headers: headers,
      );

      if (mounted) {
        setState(() {
          _workOrders = jsonDecode(woRes.body);
          _inventory = jsonDecode(invRes.body);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalBilledRM {
    double total = 0.0;
    for (var wo in _workOrders) {
      total += double.tryParse(wo['grand_total']?.toString() ?? '0') ?? 0.0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.currentLanguage,
      builder: (context, _, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF030712),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1120),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.session.companyName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(widget.session.planTier, style: const TextStyle(fontSize: 8, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Text(LocaleService.tr('ops_center'), style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              const LanguageSelector(isCompact: true),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
                onPressed: _fetchAdminData,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185)),
                onPressed: widget.onLogout,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : RefreshIndicator(
                  onRefresh: _fetchAdminData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _metricCard(LocaleService.tr('total_billing'), "RM ${_totalBilledRM.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            _metricCard(LocaleService.tr('site_orders'), "${_workOrders.length}", Icons.assignment_turned_in_rounded, const Color(0xFF0284C7)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  LocaleService.tr('compliance_notice'),
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(LocaleService.tr('recent_audits'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text("${_workOrders.length} ${LocaleService.tr('verified_badge')}", style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_workOrders.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
                            child: Center(
                              child: Text(LocaleService.tr('no_jobs'), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ),
                          )
                        else
                          ..._workOrders.map((wo) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1E293B)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                            child: Text(wo['id'] ?? '', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 11)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(wo['asset_code'] ?? 'AM-01', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Text("RM ${wo['grand_total'] ?? '0.00'}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(wo['client_name'] ?? 'Direct Client', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                  const SizedBox(height: 3),
                                  Text("Tech: ${wo['technician_name'] ?? 'Assigned'} â€¢ Duration: ${wo['total_duration'] ?? '00:00:00'}",
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 36,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF1E293B),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFF38BDF8)),
                                            label: Text(LocaleService.tr('view_pdf'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              final url = "https://api.alphatechnetworks.com/api/work-orders/${wo['id']}/download";
                                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 36,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFF25D366)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          icon: const Icon(Icons.share, size: 14, color: Color(0xFF25D366)),
                                          label: const Text("WhatsApp", style: TextStyle(color: Color(0xFF25D366), fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            final url = "https://api.alphatechnetworks.com/api/work-orders/${wo['id']}/download";
                                            final msg = "Pengesahan Tugasan Siap (${wo['id']})\nPelanggan: ${wo['client_name']}\nJumlah: RM ${wo['grand_total']}\n\nPDF: $url";
                                            launchUrl(Uri.parse("https://wa.me/?text=${Uri.encodeComponent(msg)}"), mode: LaunchMode.externalApplication);
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(LocaleService.tr('price_book_title'), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                            Text(LocaleService.tr('sst_calculated'), style: const TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._inventory.map((item) {
                          final int stock = int.tryParse(item['stock_on_hand']?.toString() ?? '0') ?? 0;
                          final bool isLowStock = stock <= 10;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(item['title'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                          if (isLowStock) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(color: const Color(0xFFE11D48).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                              child: Text(LocaleService.tr('replenish'), style: const TextStyle(color: Color(0xFFFB7185), fontSize: 8, fontWeight: FontWeight.w900)),
                                            ),
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text("${item['category']} â€¢ SKU: ${item['sku']} â€¢ ${LocaleService.tr('balance_unit')}: $stock unit", style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("RM ${item['selling_price'] ?? '0.00'}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 13)),
                                    Text("${LocaleService.tr('cost_prefix')}: RM ${item['cost_price'] ?? '0.00'}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                  Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

