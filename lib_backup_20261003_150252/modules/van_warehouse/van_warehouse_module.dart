import 'package:flutter/material.dart';
import '../../core/app_module.dart';
import '../../services/locale_service.dart';

class VanWarehouseModule implements AppModule {
  @override
  String get moduleId => 'VAN_INVENTORY_SYSTEM';

  @override
  String get title => LocaleService.currentLanguage.value == AppLanguage.en
      ? 'CENTRAL & FIELD INVENTORY MASTER HUB'
      : 'HAB INDUK INVENTORI PUSAT, VAN & PROJEK';

  @override
  IconData get icon => Icons.inventory_2_rounded;

  @override
  Widget? buildTechnicianUI(BuildContext context) {
    return const _TechnicianDailyInventoryPod();
  }

  @override
  Widget? buildAdminUI(BuildContext context) {
    return const _AdminTriLedgerInventoryHub();
  }
}

// ---------------------------------------------------------------------------
// TECHNICIAN VIEW: DAILY RECONCILIATION + SERIAL NO SCANNER + SCRAP LOG
// ---------------------------------------------------------------------------
class _TechnicianDailyInventoryPod extends StatefulWidget {
  const _TechnicianDailyInventoryPod();

  @override
  State<_TechnicianDailyInventoryPod> createState() => _TechnicianDailyInventoryPodState();
}

class _TechnicianDailyInventoryPodState extends State<_TechnicianDailyInventoryPod> {
  int _selectedScope = 0;

  final List<Map<String, dynamic>> _vanItems = [
    {
      'sku': 'CAM-HIK-4MP',
      'name': 'Hikvision 4MP IP Dome (EXIR 30m)',
      'start': 8,
      'used': 0,
      'bin': 'Rack A1',
      'unit': 'units',
      'serials': <String>['SN-HIK-99210-A', 'SN-HIK-99211-B', 'SN-HIK-99212-C'],
    },
    {
      'sku': 'CBL-CAT6-UTP',
      'name': 'Schneider Actassi Cat6 UTP Drum (305m)',
      'start': 2,
      'used': 0,
      'bin': 'Trunk Drum 01',
      'unit': 'drums',
      'serials': <String>['DRUM-SCH-2026-01', 'DRUM-SCH-2026-02'],
    },
    {
      'sku': 'ACC-RJ45-PLUG',
      'name': 'Cat6 Pass-Through RJ45 Plugs',
      'start': 45,
      'used': 0,
      'bin': 'Drawer C1',
      'unit': 'pcs',
      'serials': <String>[],
    },
    {
      'sku': 'BOX-PVC-4X4',
      'name': 'Weatherproof Junction Box 4"x4"',
      'start': 16,
      'used': 0,
      'bin': 'Drawer C3',
      'unit': 'units',
      'serials': <String>[],
    },
  ];

  final List<Map<String, dynamic>> _centralStoreRequisitions = [
    {'sku': 'ELV-FIBER-PATCH', 'name': 'Corning LC-LC Duplex 5m Patch Cord', 'avail_hq': 120, 'req_qty': 0, 'unit': 'pcs'},
    {'sku': 'PWR-MCB-63A-3P', 'name': 'Hager 63A 3-Phase Main Switch', 'avail_hq': 25, 'req_qty': 0, 'unit': 'units'},
    {'sku': 'SRV-RACK-9U', 'name': '9U Wallmount Equipment Rack Cabinet', 'avail_hq': 8, 'req_qty': 0, 'unit': 'units'},
  ];

  final List<Map<String, dynamic>> _projectStagedItems = [
    {'code': 'PRJ-ALPHA-CCTV', 'item': 'Hikvision 64-Ch Enterprise 4K NVR', 'staged': 2, 'installed': 1, 'unit': 'units', 'sn': 'NVR-64-2026-X88'},
    {'code': 'PRJ-ALPHA-CCTV', 'item': '25X Speed Dome DarkFighter PTZ', 'staged': 4, 'installed': 2, 'unit': 'sets', 'sn': 'PTZ-DF-4401-K1'},
    {'code': 'PRJ-LDP-LIGHTING', 'item': 'Signify 60W LED Streetlight Fixture', 'staged': 24, 'installed': 16, 'unit': 'sets', 'sn': 'SIG-LED-60W-BATCH-B'},
  ];

  final List<Map<String, dynamic>> _scrapEntries = [
    {'item': 'Schneider Cat6 Drum #01 Offcut', 'balance_m': 38, 'scrap_copper_kg': 1.4, 'reclaim_bin': 'Van WVG 8812 Wire Bin'},
    {'item': '3-Core 2.5mm² Armored Cable Offcut', 'balance_m': 14, 'scrap_copper_kg': 3.8, 'reclaim_bin': 'Site Scrap Lockbox'},
  ];

  bool _isShiftReconciled = false;

  void _openSerialCaptureDialog(Map<String, dynamic> item) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;
    final List<String> serials = List<String>.from((item['serials'] as List?) ?? []);
    final snController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF0A1120),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1E293B))),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            isEn ? "WARRANTY SERIAL NO / MAC REGISTRY" : "PENDAFTARAN NO SIRI / MAC WARANTI",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    Text(item['name'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: snController,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            decoration: InputDecoration(
                              hintText: isEn ? "Scan or enter SN / MAC..." : "Imbas atau taip No Siri...",
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                              prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981), size: 16),
                              filled: true,
                              fillColor: const Color(0xFF161F30),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF26324D))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            if (snController.text.trim().isNotEmpty) {
                              setDialogState(() {
                                final newSn = snController.text.trim().toUpperCase();
                                serials.add(newSn);
                                item['serials'] = serials;
                                snController.clear();
                              });
                              setState(() {});
                            }
                          },
                          child: const Text("+ ADD", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text("REGISTERED UNITS (FOR 24-MO WARRANTY):", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...serials.map((sn) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF1E293B))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(sn, style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitDailyReconciliation() {
    setState(() => _isShiftReconciled = true);
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEn ? "Daily Shift Stock Reconciled & Logged to Central Hub!" : "Inventori Harian Berjaya Disahkan & Dihantar ke Hab Pusat!"),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF38BDF8), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? "DAILY INVENTORY AUDIT" : "INVENTORI HARIAN SHIFT",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            isEn ? "Van • Central HQ • Sites • Scrap" : "Van • Stor HQ • Tapak • Sisa",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _isShiftReconciled ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isShiftReconciled ? (isEn ? "CLOSED" : "SELESAI") : (isEn ? "LIVE" : "AKTIF"),
                  style: TextStyle(
                    color: _isShiftReconciled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                _scopeButton(0, isEn ? "1. VAN" : "1. VAN", const Color(0xFF0284C7)),
                const SizedBox(width: 4),
                _scopeButton(1, isEn ? "2. HQ" : "2. HQ", const Color(0xFFA855F7)),
                const SizedBox(width: 4),
                _scopeButton(2, isEn ? "3. SITES" : "3. TAPAK", const Color(0xFF10B981)),
                const SizedBox(width: 4),
                _scopeButton(3, isEn ? "4. SCRAP" : "4. SISA", const Color(0xFFF59E0B)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedScope == 0) ...[
            ..._vanItems.map((item) {
              final remaining = (item['start'] as int) - (item['used'] as int);
              final List<String> serials = List<String>.from((item['serials'] as List?) ?? []);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item['used'] as int) > 0 ? const Color(0xFF0284C7).withValues(alpha: 0.1) : const Color(0xFF030712),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (item['used'] as int) > 0 ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(item['bin'] as String, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text("Start: ${item['start']} • Balance: $remaining ${item['unit']}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                              if (serials.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _openSerialCaptureDialog(item),
                                  child: Text("• ${serials.length} SN(s)", style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (serials.isNotEmpty)
                      IconButton(
                        tooltip: "Register SN",
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8), size: 18),
                        onPressed: () => _openSerialCaptureDialog(item),
                      ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF64748B), size: 18),
                          onPressed: () {
                            if ((item['used'] as int) > 0) setState(() => item['used'] = (item['used'] as int) - 1);
                          },
                        ),
                        Text("${item['used']}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8), size: 18),
                          onPressed: () {
                            if ((item['used'] as int) < (item['start'] as int)) setState(() => item['used'] = (item['used'] as int) + 1);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else if (_selectedScope == 1) ...[
            ..._centralStoreRequisitions.map((req) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF030712),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req['name'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text("HQ Bulk Stock: ${req['avail_hq']} ${req['unit']}", style: const TextStyle(color: Color(0xFFA855F7), fontSize: 9)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA855F7),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(70, 26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Requisition PO for ${req['name']} generated from Central HQ Store!")),
                        );
                      },
                      child: Text(
                        isEn ? "PULL TO VAN" : "AMBIL KE VAN",
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else if (_selectedScope == 2) ...[
            ..._projectStagedItems.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF030712),
                  borderRadius: BorderRadius.circular(10),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                child: Text(p['code'] as String, style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(p['item'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text("Staged: ${p['staged']} • Installed: ${p['installed']} • Warranty: ${p['sn']}", overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(60, 26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        if ((p['installed'] as int) < (p['staged'] as int)) {
                          setState(() => p['installed'] = (p['installed'] as int) + 1);
                        }
                      },
                      child: Text(
                        isEn ? "+ INSTALL" : "+ PASANG",
                        style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            ..._scrapEntries.map((scrap) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF030712),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scrap['item'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            "Length: ${scrap['balance_m']}m • Scrap: ${scrap['scrap_copper_kg']} kg",
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                          Text("Reclaim: ${scrap['reclaim_bin']}", overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 7)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                      child: const Text("RECLAIMED", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isShiftReconciled ? const Color(0xFF1E293B) : const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(_isShiftReconciled ? Icons.check_circle_rounded : Icons.lock_clock_rounded, color: _isShiftReconciled ? const Color(0xFF10B981) : Colors.black, size: 14),
              label: Text(
                _isShiftReconciled
                    ? (isEn ? "SHIFT AUDITED & LOCKED" : "AUDIT SHIFT DIKUNCI")
                    : (isEn ? "CLOSE & RECONCILE DAILY SHIFT" : "TUTUP & AUDIT INVENTORI"),
                style: TextStyle(
                  color: _isShiftReconciled ? const Color(0xFF10B981) : Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: _isShiftReconciled ? null : _submitDailyReconciliation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeButton(int index, String label, Color accentColor) {
    final isSelected = _selectedScope == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedScope = index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (accentColor == const Color(0xFF10B981) || accentColor == const Color(0xFFF59E0B) ? Colors.black : Colors.white) : const Color(0xFF94A3B8),
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADMIN VIEW: TRI-LEDGER INVENTORY HUB WITH MOBILE-SAFE RESPONSIVE KPIS
// ---------------------------------------------------------------------------
class _AdminTriLedgerInventoryHub extends StatefulWidget {
  const _AdminTriLedgerInventoryHub();

  @override
  State<_AdminTriLedgerInventoryHub> createState() => _AdminTriLedgerInventoryHubState();
}

class _AdminTriLedgerInventoryHubState extends State<_AdminTriLedgerInventoryHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _productSearch = '';
  String _productCategoryFilter = 'ALL';

  final List<Map<String, dynamic>> _masterCatalog = [
    {
      'sku': 'CBL-CAT6-UTP',
      'barcode': '955512308822',
      'name': 'Schneider Actassi Cat6 UTP Drum (305m)',
      'category': 'CABLE',
      'unit': 'drums',
      'stock': 42,
      'cost': 340.0,
      'retail': 580.0,
      'reorder': 10,
      'location': 'HQ Puchong Rack D1',
    },
    {
      'sku': 'CAM-HIK-4MP',
      'barcode': '955512304910',
      'name': 'Hikvision 4MP IP Dome (EXIR 30m, PoE)',
      'category': 'CCTV',
      'unit': 'units',
      'stock': 65,
      'cost': 195.0,
      'retail': 380.0,
      'reorder': 15,
      'location': 'HQ Puchong Bin C2',
    },
    {
      'sku': 'LGT-60W-ST',
      'barcode': '955512309901',
      'name': 'Signify / Philips 60W IP66 LED Luminaire',
      'category': 'LIGHTING',
      'unit': 'sets',
      'stock': 30,
      'cost': 210.0,
      'retail': 480.0,
      'reorder': 8,
      'location': 'HQ Puchong Bay 04',
    },
    {
      'sku': 'SWT-24P-POE',
      'barcode': '955512301140',
      'name': 'Cisco CBS250 24-Port Gigabit PoE Managed Switch',
      'category': 'IT_NETWORK',
      'unit': 'units',
      'stock': 12,
      'cost': 1280.0,
      'retail': 2100.0,
      'reorder': 4,
      'location': 'HQ Puchong Locker S2',
    },
    {
      'sku': 'ACC-RJ45-PLUG',
      'barcode': '955512308821',
      'name': 'Cat6 Shielded RJ45 Modular Connectors (Pack of 50)',
      'category': 'HARDWARE',
      'unit': 'packs',
      'stock': 85,
      'cost': 25.0,
      'retail': 65.0,
      'reorder': 20,
      'location': 'HQ Puchong Drawer A1',
    },
    {
      'sku': 'PWR-MCB-32A-3P',
      'barcode': '955512307710',
      'name': 'Hager 32A 3-Phase Type C Circuit Breaker',
      'category': 'ELECTRICAL',
      'unit': 'units',
      'stock': 40,
      'cost': 65.0,
      'retail': 145.0,
      'reorder': 10,
      'location': 'HQ Puchong Rack B2',
    },
  ];

  final List<Map<String, dynamic>> _vans = [
    {'plate': 'WVG 8812', 'driver': 'Ahmad Faizal Bin Razali', 'model': 'Toyota HiAce (CCTV Lead)', 'cost_held': 7840.0, 'status': 'OPERATIONAL'},
    {'plate': 'BQK 4410', 'driver': 'Lee Wei Kang', 'model': 'Nissan NV200 (IT & Access)', 'cost_held': 5320.0, 'status': 'RESTOCK NEEDED'},
    {'plate': 'WXY 1120', 'driver': 'Rajesh Raman', 'model': 'Isuzu Skylift 16m (Lighting Lead)', 'cost_held': 11450.0, 'status': 'OPERATIONAL'},
  ];

  final List<Map<String, dynamic>> _projects = [
    {'code': 'PRJ-ALPHA-CCTV', 'name': 'Menara AlphaTech CCTV Overhaul', 'staged': 28400.0, 'billed': 19200.0, 'excess': 9200.0, 'status': 'IN EXECUTION'},
    {'code': 'PRJ-LDP-LIGHTING', 'name': 'LDP Highway Pole Retrofit', 'staged': 45600.0, 'billed': 38100.0, 'excess': 7500.0, 'status': 'COMMISSIONING'},
    {'code': 'PRJ-SUBANG-CLINIC', 'name': 'Klinik Kesihatan Subang ELV', 'staged': 16800.0, 'billed': 16800.0, 'excess': 0.0, 'status': 'COMPLETED'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCatalog {
    return _masterCatalog.where((item) {
      final matchesSearch = item['name'].toString().toLowerCase().contains(_productSearch.toLowerCase()) ||
          item['sku'].toString().toLowerCase().contains(_productSearch.toLowerCase()) ||
          item['barcode'].toString().toLowerCase().contains(_productSearch.toLowerCase());
      final matchesCategory = _productCategoryFilter == 'ALL' || item['category'] == _productCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _openGatePassModal(Map<String, dynamic> van) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;
    final docketId = "GP-2026-${van['plate']}-094";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0A1120),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1E293B))),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isEn ? "GATE PASS & DISPATCH DOCKET" : "PAS KEBENARAN & DOKET",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 16), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B)),
                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E293B))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("SECURITY PASS: $docketId", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                          const Text("MYINVOIS READY", style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Vehicle: ${van['plate']} (${van['model']})", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("Driver: ${van['driver']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
                      const Divider(color: Color(0xFF1E293B), height: 12),
                      const Text("CARGO:", style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      const Text("• 4x Hikvision 4MP IP Dome [SN Registered]", style: TextStyle(color: Colors.white, fontSize: 8)),
                      const Text("• 2x Schneider Cat6 UTP Drums (305m)", style: TextStyle(color: Colors.white, fontSize: 8)),
                      const SizedBox(height: 6),
                      Text("Valuation: RM ${(van['cost_held'] as double).toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.share_rounded, color: Colors.black, size: 14),
                    label: Text(
                      isEn ? "EXPORT DIGITAL GATE PASS" : "KONGSI PAS DIGITAL",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Gate Pass $docketId generated!"),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProductFormModal([Map<String, dynamic>? itemToEdit]) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    final skuController = TextEditingController(text: itemToEdit?['sku'] ?? '');
    final barcodeController = TextEditingController(text: itemToEdit?['barcode'] ?? '');
    final nameController = TextEditingController(text: itemToEdit?['name'] ?? '');
    final unitController = TextEditingController(text: itemToEdit?['unit'] ?? 'units');
    final stockController = TextEditingController(text: itemToEdit != null ? itemToEdit['stock'].toString() : '10');
    final costController = TextEditingController(text: itemToEdit != null ? itemToEdit['cost'].toString() : '0.00');
    final retailController = TextEditingController(text: itemToEdit != null ? itemToEdit['retail'].toString() : '0.00');
    final reorderController = TextEditingController(text: itemToEdit != null ? itemToEdit['reorder'].toString() : '5');
    final locationController = TextEditingController(text: itemToEdit?['location'] ?? 'HQ Puchong Central Shelf');

    String selectedCategory = itemToEdit?['category'] ?? 'CCTV';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0A1120),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(itemToEdit == null ? Icons.add_box_rounded : Icons.edit_note_rounded, color: const Color(0xFF10B981), size: 18),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemToEdit == null ? (isEn ? "REGISTER NEW PRODUCT" : "DAFTAR PRODUK BARU") : (isEn ? "UPDATE PRODUCT" : "KEMASKINI PRODUK"),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      isEn ? "Central Master Catalog Record" : "Rekod Katalog Induk HQ",
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 16),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1E293B), height: 16),

                        Row(
                          children: [
                            Expanded(child: _formField(isEn ? "SKU Code" : "Kod SKU", "e.g. CAM-HIK-4MP", skuController, Icons.qr_code_rounded)),
                            const SizedBox(width: 8),
                            Expanded(child: _formField(isEn ? "Barcode" : "Barcode", "955512300000", barcodeController, Icons.barcode_reader)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _formField(isEn ? "Product Name" : "Nama Produk", "e.g. Hikvision 4MP IP Dome", nameController, Icons.inventory_rounded),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isEn ? "Category" : "Kategori", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                    child: DropdownButton<String>(
                                      value: selectedCategory,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      dropdownColor: const Color(0xFF161F30),
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                      items: const [
                                        DropdownMenuItem(value: 'CCTV', child: Text("CCTV Systems")),
                                        DropdownMenuItem(value: 'CABLE', child: Text("Cables & Fiber")),
                                        DropdownMenuItem(value: 'LIGHTING', child: Text("Lighting")),
                                        DropdownMenuItem(value: 'IT_NETWORK', child: Text("Networking")),
                                        DropdownMenuItem(value: 'ELECTRICAL', child: Text("Electrical")),
                                        DropdownMenuItem(value: 'HARDWARE', child: Text("Hardware")),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedCategory = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _formField(isEn ? "Unit (UOM)" : "Unit (UOM)", "units / drums", unitController, Icons.straighten_rounded)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(child: _formField(isEn ? "Cost (RM)" : "Kos (RM)", "0.00", costController, Icons.attach_money_rounded, isNumeric: true)),
                            const SizedBox(width: 8),
                            Expanded(child: _formField(isEn ? "Retail (RM)" : "Jual (RM)", "0.00", retailController, Icons.price_check_rounded, isNumeric: true)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(child: _formField(isEn ? "Opening Qty" : "Kuantiti", "10", stockController, Icons.tag_rounded, isNumeric: true)),
                            const SizedBox(width: 8),
                            Expanded(child: _formField(isEn ? "Min Reorder" : "Minima", "5", reorderController, Icons.warning_amber_rounded, isNumeric: true)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _formField(isEn ? "Rack Location" : "Lokasi Rak", "HQ Shelf B2 / Van WVG 8812", locationController, Icons.location_on_rounded),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            if (itemToEdit != null) ...[
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF43F5E), size: 18),
                                onPressed: () {
                                  setState(() {
                                    _masterCatalog.remove(itemToEdit);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("SKU ${itemToEdit['sku']} removed"), backgroundColor: const Color(0xFFF43F5E)),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.save_rounded, color: Colors.black, size: 16),
                                  label: Text(
                                    itemToEdit == null ? (isEn ? "SAVE PRODUCT TO CATALOG" : "SIMPAN PRODUK") : (isEn ? "UPDATE PRODUCT" : "KEMASKINI REKOD"),
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                                  ),
                                  onPressed: () {
                                    if (skuController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;

                                    setState(() {
                                      final productData = {
                                        'sku': skuController.text.trim().toUpperCase(),
                                        'barcode': barcodeController.text.trim().isEmpty ? '955512399999' : barcodeController.text.trim(),
                                        'name': nameController.text.trim(),
                                        'category': selectedCategory,
                                        'unit': unitController.text.trim().isEmpty ? 'units' : unitController.text.trim(),
                                        'stock': int.tryParse(stockController.text.trim()) ?? 0,
                                        'cost': double.tryParse(costController.text.trim()) ?? 0.0,
                                        'retail': double.tryParse(retailController.text.trim()) ?? 0.0,
                                        'reorder': int.tryParse(reorderController.text.trim()) ?? 5,
                                        'location': locationController.text.trim().isEmpty ? 'HQ Storage' : locationController.text.trim(),
                                      };

                                      if (itemToEdit == null) {
                                        _masterCatalog.insert(0, productData);
                                      } else {
                                        itemToEdit.addAll(productData);
                                      }
                                    });

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(itemToEdit == null ? "Product '${skuController.text}' registered!" : "Product '${skuController.text}' updated!"),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _formField(String label, String hint, TextEditingController controller, IconData icon, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 10),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 9),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 12),
            filled: true,
            fillColor: const Color(0xFF161F30),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF10B981))),
          ),
        ),
      ],
    );
  }

  void _openDispatchModal() {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;
    String selectedSource = 'CENTRAL HQ WAREHOUSE';
    String selectedTarget = 'FLEET VAN: WVG 8812';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1120),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 16, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? "CENTRAL DISPATCH TRANSFER" : "AGIHAN STOK PUSAT",
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 16), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 8),

                  _modalSelector("SOURCE LEDGER", selectedSource, ['CENTRAL HQ WAREHOUSE', 'PROJECT: PRJ-ALPHA-CCTV (EXCESS)', 'PROJECT: PRJ-LDP-LIGHTING (EXCESS)'], (val) {
                    setModalState(() => selectedSource = val);
                  }),
                  const SizedBox(height: 8),

                  _modalSelector("DESTINATION TARGET", selectedTarget, ['FLEET VAN: WVG 8812', 'FLEET VAN: BQK 4410', 'FLEET VAN: WXY 1120', 'PROJECT SITE: PRJ-SUBANG-CLINIC'], (val) {
                    setModalState(() => selectedTarget = val);
                  }),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                      label: Text(
                        isEn ? "AUTHORIZE TRANSFER" : "LULUSKAN PINDAHAN",
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Transfer: $selectedSource ➔ $selectedTarget"),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalSelector(String label, String value, List<String> options, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF26324D))),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF161F30),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    final double totalHqCost = _masterCatalog.fold(0.0, (sum, i) => sum + ((i['stock'] as int) * (i['cost'] as double)));
    final double totalVanCost = _vans.fold(0.0, (sum, v) => sum + (v['cost_held'] as double));
    final double totalProjectStaged = _projects.fold(0.0, (sum, p) => sum + (p['staged'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 KPI Cards formatted to stack elements vertically to prevent mobile Row overflow
        Row(
          children: [
            _kpiCard(
              title: "RM ${(totalHqCost / 1000).toStringAsFixed(1)}k",
              label: isEn ? "HQ Stock" : "Stok HQ",
              tag: "${_masterCatalog.length}",
              color: const Color(0xFFA855F7),
              icon: Icons.store_rounded,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              title: "RM ${(totalVanCost / 1000).toStringAsFixed(1)}k",
              label: isEn ? "3 Vans" : "3 Buah Van",
              tag: "WHEELS",
              color: const Color(0xFF38BDF8),
              icon: Icons.airport_shuttle_rounded,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              title: "RM ${(totalProjectStaged / 1000).toStringAsFixed(1)}k",
              label: isEn ? "Sites" : "Tapak",
              tag: "3 PRJ",
              color: const Color(0xFF10B981),
              icon: Icons.foundation_rounded,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tabs and Action Buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                tabs: [
                  Tab(text: isEn ? "1. CATALOG" : "1. KATALOG"),
                  Tab(text: isEn ? "2. VANS" : "2. VAN"),
                  Tab(text: isEn ? "3. SITES" : "3. PROJEK"),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.add_box_rounded, color: Colors.black, size: 12),
                    label: Text(
                      isEn ? "+ REGISTER" : "+ DAFTAR",
                      style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                    onPressed: () => _openProductFormModal(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 12),
                    label: Text(
                      isEn ? "DISPATCH" : "AGIHAN",
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                    onPressed: _openDispatchModal,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Tab Views
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: MASTER CATALOG & PRODUCT MANAGEMENT
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            onChanged: (val) => setState(() => _productSearch = val),
                            decoration: InputDecoration(
                              hintText: isEn ? "Search SKU, barcode..." : "Cari SKU, barcode...",
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 12),
                              filled: true,
                              fillColor: const Color(0xFF030712),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF1E293B))),
                        child: DropdownButton<String>(
                          value: _productCategoryFilter,
                          underline: const SizedBox(),
                          dropdownColor: const Color(0xFF0B132B),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text("All")),
                            DropdownMenuItem(value: 'CCTV', child: Text("CCTV")),
                            DropdownMenuItem(value: 'CABLE', child: Text("Cables")),
                            DropdownMenuItem(value: 'LIGHTING', child: Text("Light")),
                            DropdownMenuItem(value: 'IT_NETWORK', child: Text("Network")),
                            DropdownMenuItem(value: 'ELECTRICAL', child: Text("Electric")),
                            DropdownMenuItem(value: 'HARDWARE', child: Text("Hardware")),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _productCategoryFilter = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredCatalog.length,
                      itemBuilder: (context, index) {
                        final item = _filteredCatalog[index];
                        final bool isLow = (item['stock'] as int) <= (item['reorder'] as int);

                        return InkWell(
                          onTap: () => _openProductFormModal(item),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isLow ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFF1E293B)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: const Color(0xFFA855F7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFA855F7), size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(3)),
                                            child: Text(item['category'] as String, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 6, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(item['name'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "SKU: ${item['sku']} • ${item['location']}",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 7, fontFamily: 'monospace'),
                                      ),
                                      Text(
                                        "Cost: RM ${(item['cost'] as double).toStringAsFixed(2)} • Sell: RM ${(item['retail'] as double).toStringAsFixed(2)}",
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${item['stock']} ${item['unit']}",
                                      style: TextStyle(color: isLow ? const Color(0xFFF59E0B) : Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      isLow ? "LOW BUFFER" : "OPTIMAL",
                                      style: TextStyle(color: isLow ? const Color(0xFFF59E0B) : const Color(0xFF64748B), fontSize: 6, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // TAB 2: FLEET VANS WITH ONE-TAP GATE PASS BUTTON
              ListView.builder(
                itemCount: _vans.length,
                itemBuilder: (context, index) {
                  final van = _vans[index];
                  final isLow = van['status'] == 'RESTOCK NEEDED';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isLow ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.airport_shuttle_rounded, color: Color(0xFF38BDF8), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(van['plate'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                Text("${van['model']} • ${van['driver']}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 8)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF10B981)),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: const Size(50, 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: () => _openGatePassModal(van),
                              child: const Text("PASS", style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 6),
                            Text("RM ${(van['cost_held'] as double).toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // TAB 3: PROJECT SITES
              ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final p = _projects[index];
                  final isDone = p['status'] == 'COMPLETED';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text("${p['code']} • ${p['name']}", overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p['status'] as String,
                              style: TextStyle(color: isDone ? const Color(0xFF64748B) : const Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Staged: RM ${(p['staged'] as double).toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
                            Text("Installed: RM ${(p['billed'] as double).toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                            Text("Excess: RM ${(p['excess'] as double).toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile-safe KPI card: elements stack vertically to never overflow
  Widget _kpiCard({required String title, required String label, required String tag, required Color color, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                  child: Text(tag, style: TextStyle(color: color, fontSize: 6, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
            Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
          ],
        ),
      ),
    );
  }
}
