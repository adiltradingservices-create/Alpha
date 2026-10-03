import 'package:flutter/material.dart';
import '../models/business_activity.dart';
import '../models/user_session.dart';
import '../services/central_operations_store.dart';
import '../services/locale_service.dart';
import '../services/whatsapp_dispatcher_service.dart';

class AdminShell extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const AdminShell({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final CentralOperationsStore _store = CentralOperationsStore();
  final TextEditingController _searchCtrl = TextEditingController();
  int _currentTab = 0; // 0 = Field Techs, 1 = Van Stock, 2 = Whitelist & Config

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDispatchDialog(TechnicianEntity tech) {
    final siteCtrl = TextEditingController(text: tech.assignedSite);
    String status = tech.currentStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A101D),
          title: Text("DISPATCH REASSIGN: ${tech.name.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TARGET SITE / PREMISES", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: siteCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 9),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF161F30),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(height: 10),
              const Text("STATUS UPDATE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                value: status,
                dropdownColor: const Color(0xFF161F30),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'ON_SITE', child: Text("ON ACTIVE SITE", style: TextStyle(color: Color(0xFF10B981)))),
                  DropdownMenuItem(value: 'STANDBY', child: Text("STANDBY / WORKSHOP", style: TextStyle(color: Color(0xFFF59E0B)))),
                  DropdownMenuItem(value: 'OFFLINE', child: Text("OFFLINE", style: TextStyle(color: Color(0xFF64748B)))),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => status = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL", style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _store.themeAccentColor),
              onPressed: () {
                _store.updateTechnicianSite(tech.id, siteCtrl.text.trim(), status);
                Navigator.pop(ctx);
              },
              child: const Text("PUSH DISPATCH", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _openOnboardTechModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: widget.session.countryCode == 'PK' ? '+92 300 ' : '+60 12-');
    final idCtrl = TextEditingController();
    final licenseCtrl = TextEditingController(text: 'ST PW4 / PEC');
    final vehicleCtrl = TextEditingController(text: 'WVG 8812');
    final siteCtrl = TextEditingController(text: 'Central HQ / Standby');
    final selectedDisciplines = <BusinessActivityType>{BusinessActivityType.cctv};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A101D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ONBOARD NEW FIELD TECHNICIAN", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                        Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF10B981), size: 18),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    _modalField("FULL LEGAL NAME", nameCtrl, "Mohd Syamil"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("MOBILE CONTACT", phoneCtrl, "+60 12-xxxxxxx")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField(widget.session.countryCode == 'PK' ? "CNIC NUMBER" : "MYKAD NRIC", idCtrl, "880101-10-xxxx")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("LICENSE / PERMIT CODE", licenseCtrl, "ST PW4 / PEC")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("ASSIGNED VAN PLATE", vehicleCtrl, "WVG 8812")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _modalField("INITIAL ASSIGNED SITE", siteCtrl, "Menara AlphaTech • Server Room"),
                    const SizedBox(height: 10),

                    const Text("AUTHORIZED DISCIPLINES", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: BusinessActivity.getCategories().map((cat) {
                        final isSel = selectedDisciplines.contains(cat.type);
                        return FilterChip(
                          label: Text(cat.title),
                          selected: isSel,
                          selectedColor: cat.accentColor,
                          backgroundColor: const Color(0xFF161F30),
                          labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: isSel ? cat.accentColor : const Color(0xFF26324D))),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedDisciplines.add(cat.type);
                              } else if (selectedDisciplines.length > 1) {
                                selectedDisciplines.remove(cat.type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _store.themeAccentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: const Text("REGISTER & ACTIVATE TECHNICIAN", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          _store.addTechnician(
                            TechnicianEntity(
                              id: 'TECH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              nationalId: idCtrl.text.trim().isEmpty ? 'PENDING' : idCtrl.text.trim(),
                              licenseCode: licenseCtrl.text.trim().isEmpty ? 'GENERAL' : licenseCtrl.text.trim(),
                              vehiclePlate: vehicleCtrl.text.trim().isEmpty ? 'STANDBY' : vehicleCtrl.text.trim(),
                              assignedSite: siteCtrl.text.trim(),
                              currentStatus: 'STANDBY',
                              disciplines: selectedDisciplines.toList(),
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SizedBox(
          height: 34,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 8),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7),
              filled: true,
              fillColor: const Color(0xFF161F30),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final techs = _store.technicians.where((t) {
          final q = _searchCtrl.text.toLowerCase();
          return t.name.toLowerCase().contains(q) || t.assignedSite.toLowerCase().contains(q) || t.phone.contains(q);
        }).toList();

        final colorPalette = [
          const Color(0xFF10B981), // Emerald
          const Color(0xFF38BDF8), // Cyan
          const Color(0xFFA855F7), // Purple
          const Color(0xFFF59E0B), // Amber
          const Color(0xFFEF4444), // Crimson
        ];

        final companyNameCtrl = TextEditingController(text: _store.companyName);
        final taglineCtrl = TextEditingController(text: _store.companyTagline);

        return Scaffold(
          backgroundColor: const Color(0xFF030712),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A101D),
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Icon(Icons.hub_rounded, color: _store.themeAccentColor, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_store.companyName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                    const Text("CENTRALIZED OPERATIONS CONTROL", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.language_rounded, color: Color(0xFF94A3B8), size: 18), onPressed: LocaleService.toggleLanguage),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 18), onPressed: widget.onLogout),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _currentTab,
            children: [
              // TAB 0: Field Techs & Live Dispatch
              ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Row(
                    children: [
                      _kpiCard("ACTIVE FORCE", "${_store.technicians.length}", Icons.groups_rounded, const Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      _kpiCard("DISPATCHED", "${_store.technicians.where((t) => t.currentStatus == 'ON_SITE').length}", Icons.location_on_rounded, const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _kpiCard("STANDBY", "${_store.technicians.where((t) => t.currentStatus == 'STANDBY').length}", Icons.pause_circle_rounded, const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                            decoration: InputDecoration(
                              hintText: "Search active technician, site, vehicle plate...",
                              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _store.themeAccentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                          label: const Text("ONBOARD", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                          onPressed: _openOnboardTechModal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...techs.map((tech) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tech.currentStatus == 'ON_SITE' ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                border: Border.all(color: tech.currentStatus == 'ON_SITE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                              ),
                              child: Center(
                                child: Text(tech.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                                      Text(tech.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text(tech.currentStatus.replaceAll('_', ' '), style: TextStyle(color: tech.currentStatus == 'ON_SITE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text("${tech.vehiclePlate} • ${tech.phone}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7)),
                                  const SizedBox(height: 2),
                                  Text("Site: ${tech.assignedSite}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_to_mobile_rounded, color: Color(0xFF38BDF8), size: 18),
                              onPressed: () => _showDispatchDialog(tech),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16),
                              onPressed: () => WhatsAppDispatcherService().sendSiteReport(
                                context: context,
                                recipientPhone: tech.phone,
                                message: "Dispatch Update from HQ: Proceed to ${tech.assignedSite}.",
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),

              // TAB 1: Central Van Stores Ledger
              ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text("CENTRALIZED FLEET VAN STOCK ALLOCATION", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ..._store.vanInventoryStock.entries.map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1E293B))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text("${entry.value} IN STOCK", style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),

              // TAB 2: SYSTEM CONFIG & FULL WHITELISTING
              ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  const Text("ENTERPRISE CONFIGURATION & WHITELISTING", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  const Divider(color: Color(0xFF1E293B), height: 16),

                  // 1. BRANDING
                  _configSectionTitle("1. WHITE-LABEL BRANDING"),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _configTextField("COMPANY LEGAL NAME", companyNameCtrl),
                        const SizedBox(height: 8),
                        _configTextField("COMPANY TAGLINE", taglineCtrl),
                        const SizedBox(height: 10),
                        const Text("THEME ACCENT COLOR", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: colorPalette.map((col) {
                            final isSel = _store.themeAccentColor.toARGB32() == col.toARGB32();
                            return InkWell(
                              onTap: () {
                                _store.updateConfig(
                                  name: companyNameCtrl.text.trim(),
                                  tagline: taglineCtrl.text.trim(),
                                  accent: col,
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                                ),
                                child: isSel ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _store.themeAccentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: () {
                              _store.updateConfig(
                                name: companyNameCtrl.text.trim(),
                                tagline: taglineCtrl.text.trim(),
                                accent: _store.themeAccentColor,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Branding saved!"), backgroundColor: Color(0xFF10B981)));
                            },
                            child: const Text("SAVE BRANDING", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. FEATURE WHITELISTING
                  _configSectionTitle("2. TECHNICIAN FEATURE WHITELISTING"),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
                    child: Column(
                      children: [
                        _whitelistSwitch("Biometrics Face & GPS Attendance", _store.enableBiometrics, (v) => _store.updateConfig(biometrics: v)),
                        const Divider(color: Color(0xFF1E293B), height: 10),
                        _whitelistSwitch("Mobile Van Inventory Stores", _store.enableVanStores, (v) => _store.updateConfig(vanStores: v)),
                        const Divider(color: Color(0xFF1E293B), height: 10),
                        _whitelistSwitch("Testing & Commissioning Engine", _store.enableTesting, (v) => _store.updateConfig(testing: v)),
                        const Divider(color: Color(0xFF1E293B), height: 10),
                        _whitelistSwitch("Client Touch Digital Sign-Off", _store.enableSignOff, (v) => _store.updateConfig(signOff: v)),
                        const Divider(color: Color(0xFF1E293B), height: 10),
                        _whitelistSwitch("One-Tap WhatsApp Site Dispatch", _store.enableWhatsApp, (v) => _store.updateConfig(whatsApp: v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (idx) => setState(() => _currentTab = idx),
            backgroundColor: const Color(0xFF0A101D),
            selectedItemColor: _store.themeAccentColor,
            unselectedItemColor: const Color(0xFF64748B),
            selectedFontSize: 8,
            unselectedFontSize: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.groups_rounded, size: 18), label: "Field Techs"),
              BottomNavigationBarItem(icon: Icon(Icons.airport_shuttle_rounded, size: 18), label: "Van Stock"),
              BottomNavigationBarItem(icon: Icon(Icons.tune_rounded, size: 18), label: "Config"),
            ],
          ),
        );
      },
    );
  }

  Widget _configSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6));
  }

  Widget _configTextField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SizedBox(
          height: 34,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161F30),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _whitelistSwitch(String title, bool val, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        Switch(
          value: val,
          onChanged: onChanged,
          activeThumbColor: _store.themeAccentColor,
        ),
      ],
    );
  }
}
