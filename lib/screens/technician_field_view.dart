import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../modules/biometrics/biometrics_module.dart';
import '../screens/multi_activity_workspace_screen.dart';
import '../services/central_operations_store.dart';
import '../services/data_engine_hub.dart';
import '../widgets/barcode_scanner_modal.dart';

class TechnicianFieldView extends StatefulWidget {
  final UserSession session;
  final VoidCallback onSwitchToAdmin;
  final VoidCallback onLogout;

  const TechnicianFieldView({
    super.key,
    required this.session,
    required this.onSwitchToAdmin,
    required this.onLogout,
  });

  @override
  State<TechnicianFieldView> createState() => _TechnicianFieldViewState();
}

class _TechnicianFieldViewState extends State<TechnicianFieldView> {
  final DataEngineHub _hub = DataEngineHub();
  final AttendanceDataStore _attendanceStore = AttendanceDataStore();

  TechnicianEntity get _currentTech {
    if (_hub.technicians.isNotEmpty) {
      return _hub.technicians.first;
    }
    return TechnicianEntity(
      id: 'TECH-01',
      tenantId: widget.session.tenantId,
      name: widget.session.name.isNotEmpty ? widget.session.name : 'Field Lead',
      phone: '+60123456789',
      nationalId: 'MY-TECH',
      licenseCode: 'CERT-01',
      vehiclePlate: 'WVG 8812',
      assignedSite: 'Site Station Beta',
      currentStatus: 'ON_SITE',
      disciplines: [],
    );
  }

  void _openAttendanceHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070D18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) {
          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("MY ATTENDANCE & PUNCH HISTORY", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 8),
              BiometricsModule.buildHistoryLogsView(),
            ],
          );
        },
      ),
    );
  }

  void _openBarcodeScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerModal(
        onScanned: (codes) {
          Navigator.pop(ctx);
          final serial = codes.isNotEmpty ? codes.first : 'SCANNED-ITEM';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hardware [$serial] installed at ${_currentTech.assignedSite}!"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tech = _currentTech;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070D18),
        elevation: 0,
        titleSpacing: 10,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(tech.name.substring(0, 1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tech.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  Text("Van: ${tech.vehiclePlate} • ${tech.assignedSite}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _attendanceStore,
            builder: (context, _) {
              final isClockedIn = _attendanceStore.isCurrentlyCheckedIn;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isClockedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: (isClockedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: isClockedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                    const SizedBox(width: 4),
                    Text(isClockedIn ? "CLOCKED-IN" : "OFF-DUTY", style: TextStyle(color: isClockedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 6.5, fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 18),
            tooltip: "My Attendance History",
            onPressed: _openAttendanceHistoryModal,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF070D18),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0B132B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.engineering_rounded, color: Color(0xFF10B981), size: 28),
                  const SizedBox(height: 8),
                  Text(tech.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  Text("Vehicle: ${tech.vehiclePlate} • Field Lead", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5)),
                ],
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.history_rounded, color: Color(0xFF38BDF8), size: 18),
              title: const Text("My Attendance Logs", style: TextStyle(color: Colors.white, fontSize: 8.5)),
              onTap: () {
                Navigator.pop(context);
                _openAttendanceHistoryModal();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF10B981), size: 18),
              title: const Text("Scan Hardware Barcode", style: TextStyle(color: Colors.white, fontSize: 8.5)),
              onTap: () {
                Navigator.pop(context);
                _openBarcodeScanner();
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFA855F7), size: 18),
              title: const Text("Switch to Admin Portal", style: TextStyle(color: Colors.white, fontSize: 8.5)),
              onTap: widget.onSwitchToAdmin,
            ),
            const Divider(color: Color(0xFF1E293B)),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              title: const Text("Logout Session", style: TextStyle(color: Color(0xFFEF4444), fontSize: 8.5, fontWeight: FontWeight.bold)),
              onTap: widget.onLogout,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          children: [
            // 1. PRIMARY WORK ORDER HERO BANNER
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF091428)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          const Text("ACTIVE FIELD WORK ORDER", style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(tech.currentStatus.replaceAll('_', ' '), style: const TextStyle(color: Color(0xFF10B981), fontSize: 6, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(tech.assignedSite, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text("Van Plate: ${tech.vehiclePlate} • Milestones, Hardware QR & Sign-off", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 6.5)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                      label: const Text("EXECUTE WORK ORDER & SCAN HARDWARE", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => MultiActivityWorkspaceScreen(
                              projectName: "Field Service (${tech.assignedSite})",
                              siteLocation: tech.assignedSite,
                              technicianName: tech.name,
                              companyName: CentralOperationsStore().companyName,
                              initialClientName: "Direct Site Owner / Facility Mgr",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. MODULAR BIOMETRIC QUICK PUNCH COCKPIT (Plugs directly from BiometricsModule)
            BiometricsModule.buildQuickPunchCockpit(
              onPunchCompleted: () {
                setState(() {});
              },
            ),
            const SizedBox(height: 14),

            // 3. OPERATIONAL QUICK TOOLS
            const Text("FIELD OPERATIONAL TOOLS", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _toolCard(
                    title: "Hardware Scanner",
                    subtitle: "Optical barcode check",
                    icon: Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF38BDF8),
                    onTap: _openBarcodeScanner,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toolCard(
                    title: "My Attendance",
                    subtitle: "Thumbnails & log history",
                    icon: Icons.history_rounded,
                    color: const Color(0xFFA855F7),
                    onTap: _openAttendanceHistoryModal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6)),
          ],
        ),
      ),
    );
  }
}