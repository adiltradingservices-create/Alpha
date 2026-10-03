import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/module_registry.dart';
import '../models/user_session.dart';
import '../screens/multi_activity_workspace_screen.dart';
import '../services/central_operations_store.dart';
import '../services/locale_service.dart';
import '../services/whatsapp_dispatcher_service.dart';

class TechnicianShell extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const TechnicianShell({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  State<TechnicianShell> createState() => _TechnicianShellState();
}

class _TechnicianShellState extends State<TechnicianShell> {
  final CentralOperationsStore _store = CentralOperationsStore();

  void _openMultiActivityWorkspace(TechnicianEntity tech) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MultiActivityWorkspaceScreen(
          projectName: "Field Service (${tech.assignedSite})",
          siteLocation: tech.assignedSite,
          technicianName: tech.name,
          companyName: _store.companyName,
          initialClientName: "Direct Site Owner / Facility Mgr",
        ),
      ),
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
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFF1E293B))),
          ),
          body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: content),
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
            backgroundColor: const Color(0xFF0A101D),
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_store.themeAccentColor, const Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(currentTech.name.substring(0, 1), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentTech.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                      Text("${_store.companyName} • Fleet: ${currentTech.vehiclePlate}", overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.language_rounded, color: Color(0xFF94A3B8), size: 18), onPressed: LocaleService.toggleLanguage),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 18), onPressed: widget.onLogout),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // 1. LIVE HQ DISPATCH CARD
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("ACTIVE HQ DISPATCH ASSIGNMENT", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.w900)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(currentTech.currentStatus.replaceAll('_', ' '), style: const TextStyle(color: Color(0xFF10B981), fontSize: 6, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(currentTech.assignedSite, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Assigned Vehicle: ${currentTech.vehiclePlate}", style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 8)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. MULTI-DISCIPLINE WORKSPACE ACTION
              InkWell(
                onTap: () => _openMultiActivityWorkspace(currentTech),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF065F46)]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _store.themeAccentColor.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.checklist_rtl_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("EXECUTE SITE TASKS & PDF DOCKET", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                            Text("Interactive checklist, van parts deduction & official A4 docket", style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 7)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. CORE SITE TOOLS
              const Text("CENTRAL AUTHORIZED TOOLS", style: TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),

              Row(
                children: [
                  if (_store.enableBiometrics)
                    _actionChip(
                      title: "Attendance",
                      icon: Icons.face_retouching_natural_rounded,
                      color: _store.themeAccentColor,
                      onTap: () {
                        final mod = registry.activeModules.firstWhere((m) => m.moduleId == 'BIOMETRICS_TELEMETRY');
                        _openModuleScreen(context, "SITE ATTENDANCE", mod.buildTechnicianUI(context) ?? const SizedBox.shrink());
                      },
                    ),
                  if (_store.enableBiometrics && _store.enableVanStores) const SizedBox(width: 8),
                  if (_store.enableVanStores)
                    _actionChip(
                      title: "Van Stores",
                      icon: Icons.airport_shuttle_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        final mod = registry.activeModules.firstWhere((m) => m.moduleId == 'VAN_INVENTORY_SYSTEM');
                        _openModuleScreen(context, "VAN STOCK", mod.buildTechnicianUI(context) ?? const SizedBox.shrink());
                      },
                    ),
                  if (_store.enableVanStores && _store.enableSignOff) const SizedBox(width: 8),
                  if (_store.enableSignOff)
                    _actionChip(
                      title: "Sign-Off",
                      icon: Icons.draw_rounded,
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        final mod = registry.activeModules.firstWhere((m) => m.moduleId == 'CLIENT_ENDORSEMENT');
                        _openModuleScreen(context, "CLIENT SIGN-OFF", mod.buildTechnicianUI(context) ?? const SizedBox.shrink());
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. WHATSAPP INSTANT PUSH
              if (_store.enableWhatsApp)
                InkWell(
                  onTap: () => WhatsAppDispatcherService().sendSiteReport(
                    context: context,
                    recipientPhone: "+60123456789",
                    message: "🚨 *FIELD SERVICE DISPATCH UPDATE* 🚨\nLead Tech: ${currentTech.name}\nSite: ${currentTech.assignedSite}\nStatus: Active On-Site",
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF062316), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4))),
                    child: const Row(
                      children: [
                        Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("DISPATCH SITE REPORT VIA WHATSAPP", style: TextStyle(color: Color(0xFF25D366), fontSize: 8, fontWeight: FontWeight.w900)),
                              Text("1-Tap instant dispatch to Client / HQ In-Charge", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF25D366), size: 16),
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

  Widget _actionChip({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
