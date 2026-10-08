import '../modules/biometrics/biometrics_module.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/module_registry.dart';
import '../models/user_session.dart';
import '../screens/multi_activity_workspace_screen.dart';
import '../screens/technician_field_view.dart';
import '../services/central_operations_store.dart';
import '../services/locale_service.dart';
import '../services/whatsapp_dispatcher_service.dart';

class TechnicianShell extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;
  final VoidCallback? onSwitchToAdmin;

  const TechnicianShell({
    super.key,
    required this.session,
    required this.onLogout,
    this.onSwitchToAdmin,
  });

  @override
  State<TechnicianShell> createState() => _TechnicianShellState();
}

class _TechnicianShellState extends State<TechnicianShell> {
  final CentralOperationsStore _store = CentralOperationsStore();

  /// Unified Job Execution Hub: Merges Tasks, Scanning, Photos, and Docket Generation
  void _openUnifiedJobHub(TechnicianEntity tech) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070D18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("JOB EXECUTION & FIELD DOCKET", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                            Text("Site: ${tech.assignedSite} • Van ${tech.vehiclePlate}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B), height: 18),

                // Primary Execution Modes
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SELECT WORK ORDER STEP", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 7.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),

                      // Step 1: Work Order Checklist & Milestone Execution
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => MultiActivityWorkspaceScreen(
                                projectName: "Field Service (${tech.assignedSite})",
                                siteLocation: tech.assignedSite,
                                technicianName: tech.name,
                                companyName: _store.companyName,
                                initialClientName: "Direct Site Owner / Facility Mgr",
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.checklist_rtl_rounded, color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("1. Complete Checklist & A4 Work Order", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    Text("Service ticket milestones, cabling, termination & testing", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 6.5)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981), size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Step 2: Optical Barcode / Serial & Photo Proof Capture
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => TechnicianFieldView(
                                session: widget.session,
                                onSwitchToAdmin: () => Navigator.pop(c),
                                onLogout: widget.onLogout,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("2. Scan Hardware Serials & Photo Docket", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                    Text("Camera barcode recognition, photo evidence & site docket", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 6.5)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Job Overview Details
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricBadge("DISPATCH", tech.currentStatus.replaceAll('_', ' '), const Color(0xFF10B981)),
                      Container(width: 1, height: 24, color: const Color(0xFF1E293B)),
                      _metricBadge("VEHICLE", tech.vehiclePlate, const Color(0xFF38BDF8)),
                      Container(width: 1, height: 24, color: const Color(0xFF1E293B)),
                      _metricBadge("GPS TELEMETRY", "SYNCED", const Color(0xFFA855F7)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _metricBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 5.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _openModuleScreen(BuildContext context, String title, Widget content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF030712),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B1120),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B))),
          ),
          body: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: content)),
        ),
      ),
    );
  }

  void _showWalkaroundModal(BuildContext context, TechnicianEntity tech) {
    final odoCtrl = TextEditingController(text: '84520');
    bool tiresChecked = true;
    bool safetyGearChecked = true;
    bool fuelChecked = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070D18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF38BDF8).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fact_check_rounded, color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DAILY VEHICLE WALKAROUND CHECKLIST", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      Text("Pre-Departure Inspection • Van ${tech.vehiclePlate}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B), height: 18),
              CheckboxListTile(
                value: tiresChecked,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text("Tire Condition & Wheel Nuts Checked", style: TextStyle(color: Colors.white, fontSize: 8.5)),
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setModalState(() => tiresChecked = val ?? false),
              ),
              CheckboxListTile(
                value: safetyGearChecked,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text("Safety Gear Present (Cones, Fire Extinguisher, Ladder Racks)", style: TextStyle(color: Colors.white, fontSize: 8.5)),
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setModalState(() => safetyGearChecked = val ?? false),
              ),
              CheckboxListTile(
                value: fuelChecked,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text("Fluid Levels & Fuel Level Adequate", style: TextStyle(color: Colors.white, fontSize: 8.5)),
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setModalState(() => fuelChecked = val ?? false),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: odoCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 9),
                decoration: InputDecoration(
                  labelText: "ODOMETER READING (KM)",
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5),
                  prefixIcon: const Icon(Icons.speed_rounded, color: Color(0xFF38BDF8), size: 16),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                  label: const Text("SIGN-OFF & SUBMIT TO HQ", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: const Color(0xFF10B981), content: Text("Vehicle ${tech.vehiclePlate} walkaround logged at ${odoCtrl.text} KM")),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseModal(BuildContext context, TechnicianEntity tech) {
    final amountCtrl = TextEditingController();
    String expenseType = widget.session.countryCode == 'PK' ? 'M-TAG TOLL' : 'TOUCH N GO / TOLL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070D18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFFF59E0B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("FUEL & TOLL EXPENSE LOGGER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      Text("Instant Van Claim • Vehicle ${tech.vehiclePlate}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B), height: 18),
              DropdownButtonFormField<String>(
                initialValue: expenseType,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 8.5),
                decoration: InputDecoration(
                  labelText: "EXPENSE CATEGORY",
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(value: widget.session.countryCode == 'PK' ? 'M-TAG TOLL' : 'TOUCH N GO / TOLL', child: Text(widget.session.countryCode == 'PK' ? 'M-TAG TOLL' : 'TOUCH N GO / TOLL')),
                  const DropdownMenuItem(value: 'DIESEL / FUEL', child: Text('DIESEL / FUEL')),
                  const DropdownMenuItem(value: 'PARKING / ENTRY', child: Text('PARKING / ENTRY')),
                  const DropdownMenuItem(value: 'MISC REPAIR', child: Text('MISC HARDWARE')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => expenseType = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 9),
                decoration: InputDecoration(
                  labelText: widget.session.countryCode == 'PK' ? "AMOUNT (PKR)" : "AMOUNT (MYR)",
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5),
                  prefixIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF59E0B), size: 16),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 14),
                  label: const Text("RECORD EXPENSE CLAIM", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900)),
                  onPressed: () {
                    if (amountCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: const Color(0xFFF59E0B), content: Text("Logged $expenseType: ${amountCtrl.text.trim()} to fleet finance")),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = context.watch<ModuleRegistry>();

    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final currentTech = _store.technicians.firstWhere(
          (t) => t.name.toLowerCase() == widget.session.name.toLowerCase(),
          orElse: () => _store.technicians.first,
        );

        return Scaffold(
          backgroundColor: const Color(0xFF030712),
          appBar: AppBar(
            backgroundColor: const Color(0xFF070D18),
            elevation: 0,
            titleSpacing: 14,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_store.themeAccentColor, const Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(currentTech.name.substring(0, 1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentTech.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      Text("${_store.companyName} • Van: ${currentTech.vehiclePlate}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.language_rounded, color: Color(0xFF94A3B8), size: 16), onPressed: LocaleService.toggleLanguage),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 16), onPressed: widget.onLogout),
              const SizedBox(width: 2),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            children: [
              // 1. DYNAMIC SHIFT PUNCH & BIOMETRIC TELEMETRY COCKPIT
              BiometricsModule.buildQuickPunchCockpit(
                onPunchCompleted: () => setState(() {}),
              ),
              const SizedBox(height: 14),

              // 2. UNIFIED DISPATCH HERO CARD WITH COMBINED ACTION
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF091428)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                            const Text("ASSIGNED WORK ORDER TARGET", style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(currentTech.currentStatus.replaceAll('_', ' '), style: const TextStyle(color: Color(0xFF10B981), fontSize: 6, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(currentTech.assignedSite, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text("Van Plate: ${currentTech.vehiclePlate} • Integrated Scanner & PDF Docket", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 6.5)),
                    const SizedBox(height: 10),

                    // Unified Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                        label: const Text("START WORK ORDER & SCAN HARDWARE", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                        onPressed: () => _openUnifiedJobHub(currentTech),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. CORE OPERATIONAL MODULE TILES (Clean 3-Column Hub)
              const Text("CORE FIELD WORKSPACE", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _gridActionCard(
                      title: "Work Order Hub",
                      subtitle: "Tasks, QR & Docket",
                      icon: Icons.checklist_rtl_rounded,
                      accentColor: const Color(0xFF10B981),
                      onTap: () => _openUnifiedJobHub(currentTech),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _gridActionCard(
                      title: "Van Mobile Depot",
                      subtitle: "Stock, steppers & tools",
                      icon: Icons.airport_shuttle_rounded,
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () {
                        final mod = registry.activeModules.firstWhere((m) => m.moduleId == 'VAN_INVENTORY_SYSTEM');
                        _openModuleScreen(context, "VAN INVENTORY & TOOLS", mod.buildTechnicianUI(context) ?? const SizedBox.shrink());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _gridActionCard(
                      title: "Site Attendance",
                      subtitle: "Biometrics & GPS",
                      icon: Icons.face_retouching_natural_rounded,
                      accentColor: const Color(0xFFA855F7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => Scaffold(
                              backgroundColor: const Color(0xFF030712),
                              appBar: AppBar(
                                backgroundColor: const Color(0xFF0B1120),
                                elevation: 0,
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                  onPressed: () => Navigator.pop(c),
                                ),
                                title: const Text("ATTENDANCE TELEMETRY & AUDIT", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                              ),
                              body: const SafeArea(child: Padding(padding: EdgeInsets.all(12), child: AdminAttendanceLedgerView())),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. VEHICLE & FIELD UTILITIES
              const Text("FLEET & EXPENSE UTILITIES", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _quickUtilityButton(
                      icon: Icons.fact_check_rounded,
                      label: "Walkaround",
                      color: const Color(0xFF38BDF8),
                      onTap: () => _showWalkaroundModal(context, currentTech),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _quickUtilityButton(
                      icon: Icons.local_gas_station_rounded,
                      label: "Fuel / Toll",
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showExpenseModal(context, currentTech),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _quickUtilityButton(
                      icon: Icons.draw_rounded,
                      label: "Client Sign",
                      color: const Color(0xFF10B981),
                      onTap: () {
                        final mod = registry.activeModules.firstWhere((m) => m.moduleId == 'CLIENT_ENDORSEMENT');
                        _openModuleScreen(context, "CLIENT SIGN-OFF", mod.buildTechnicianUI(context) ?? const SizedBox.shrink());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. WHATSAPP HQ COMMUNICATOR
              if (_store.enableWhatsApp)
                InkWell(
                  onTap: () {
                    final targetPhone = widget.session.countryCode == 'PK' ? '923001234567' : '60123456789';
                    WhatsAppDispatcherService().sendSiteReport(
                      context: context,
                      recipientPhone: targetPhone,
                      message: "🚨 *FIELD SERVICE DISPATCH UPDATE* 🚨\nLead Tech: ${currentTech.name}\nSite: ${currentTech.assignedSite}\nVan Plate: ${currentTech.vehiclePlate}\nStatus: Active On-Site",
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF062316),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 14),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SEND SITUATION REPORT TO HQ", style: TextStyle(color: Color(0xFF25D366), fontSize: 7.5, fontWeight: FontWeight.w900)),
                              Text("1-Tap instant dispatch telemetry to HQ In-Charge", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 6)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF25D366), size: 14),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _gridActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
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
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: accentColor, size: 16),
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

  Widget _quickUtilityButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}