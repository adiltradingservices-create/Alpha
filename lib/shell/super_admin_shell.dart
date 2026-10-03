import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/data_engine_hub.dart';
import '../services/locale_service.dart';

class CompanyTenant {
  final String id;
  String name;
  String registrationNumber;
  String countryCode; // 'MY', 'PK', 'GLOBAL'
  String planTier; // 'ENTERPRISE', 'PRO', 'TRIAL'
  int licenseSeats;
  bool isActive;
  DateTime renewalDate;

  CompanyTenant({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.countryCode,
    required this.planTier,
    required this.licenseSeats,
    required this.isActive,
    required this.renewalDate,
  });
}

class SuperAdminShell extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;
  final ValueChanged<UserSession>? onImpersonateCompany;

  const SuperAdminShell({
    super.key,
    required this.session,
    required this.onLogout,
    this.onImpersonateCompany,
  });

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _countryFilter = 'ALL';

  final List<CompanyTenant> _tenants = [
    CompanyTenant(
      id: 'TENANT-MY-001',
      name: 'AlphaTech Networks Sdn Bhd',
      registrationNumber: '202301048891 (1502812-M)',
      countryCode: 'MY',
      planTier: 'ENTERPRISE',
      licenseSeats: 25,
      isActive: true,
      renewalDate: DateTime(2027, 8, 30),
    ),
    CompanyTenant(
      id: 'TENANT-PK-001',
      name: 'Indus Smart Solutions (Pvt) Ltd',
      registrationNumber: 'NTN-7749102-4',
      countryCode: 'PK',
      planTier: 'ENTERPRISE',
      licenseSeats: 50,
      isActive: true,
      renewalDate: DateTime(2027, 5, 20),
    ),
    CompanyTenant(
      id: 'TENANT-GL-001',
      name: 'Vanguard Global Field Ops Inc',
      registrationNumber: 'EIN-88192011-US',
      countryCode: 'GLOBAL',
      planTier: 'ENTERPRISE',
      licenseSeats: 30,
      isActive: true,
      renewalDate: DateTime(2027, 12, 10),
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _triggerImpersonation(CompanyTenant tenant) {
    DataEngineHub().setActiveTenant(tenant.id);

    if (widget.onImpersonateCompany != null) {
      final impersonatedSession = UserSession.forRegion(
        id: 'admin_${tenant.id.toLowerCase()}',
        token: widget.session.token,
        name: '${tenant.name} HQ Admin',
        email: 'admin@${tenant.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}.com',
        role: 'ADMIN',
        tenantId: tenant.id,
        companyName: tenant.name,
        planTier: tenant.planTier,
        countryCode: tenant.countryCode,
      );
      widget.onImpersonateCompany!(impersonatedSession);
    }
  }

  void _openCompanyModal({CompanyTenant? editTenant}) {
    final isEditing = editTenant != null;
    final nameCtrl = TextEditingController(text: editTenant?.name ?? '');
    final regCtrl = TextEditingController(text: editTenant?.registrationNumber ?? '');
    final seatsCtrl = TextEditingController(text: editTenant != null ? '${editTenant.licenseSeats}' : '15');
    String country = editTenant?.countryCode ?? 'MY';
    String tier = editTenant?.planTier ?? 'ENTERPRISE';
    bool active = editTenant?.isActive ?? true;

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "EDIT ENTERPRISE TENANT" : "ONBOARD NEW TENANT COMPANY",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                        Icon(isEditing ? Icons.edit_note_rounded : Icons.domain_add_rounded, color: const Color(0xFF38BDF8), size: 18),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    _formField("COMPANY LEGAL NAME", nameCtrl, "e.g. Apex Security Solutions"),
                    const SizedBox(height: 8),
                    _formField("REGISTRATION / TAX NUMBER", regCtrl, "e.g. 20240109921 / NTN-1234567"),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("OPERATIONAL JURISDICTION", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: country,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'MY', child: Text("🇲🇾 Malaysia (ST/CIDB)")),
                                      DropdownMenuItem(value: 'PK', child: Text("🇵🇰 Pakistan (PEC/NEPRA)")),
                                      DropdownMenuItem(value: 'GLOBAL', child: Text("🌐 Global (IEC/OSHA)")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => country = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SUBSCRIPTION TIER", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: tier,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'ENTERPRISE', child: Text("ENTERPRISE")),
                                      DropdownMenuItem(value: 'PRO', child: Text("PRO TIER")),
                                      DropdownMenuItem(value: 'TRIAL', child: Text("TRIAL")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => tier = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(child: _formField("LICENSE SEATS ALLOCATED", seatsCtrl, "25")),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("TENANT STATUS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(active ? "ACTIVE" : "SUSPENDED", style: TextStyle(color: active ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.w900)),
                                    Switch(
                                      value: active,
                                      activeThumbColor: const Color(0xFF10B981),
                                      onChanged: (v) => setModalState(() => active = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: Text(
                          isEditing ? "SAVE TENANT CHANGES" : "PROVISION & ONBOARD TENANT",
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final seats = int.tryParse(seatsCtrl.text.trim()) ?? 10;

                          setState(() {
                            if (isEditing) {
                              editTenant.name = nameCtrl.text.trim();
                              editTenant.registrationNumber = regCtrl.text.trim();
                              editTenant.countryCode = country;
                              editTenant.planTier = tier;
                              editTenant.licenseSeats = seats;
                              editTenant.isActive = active;
                            } else {
                              _tenants.insert(
                                0,
                                CompanyTenant(
                                  id: 'TENANT-$country-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                  name: nameCtrl.text.trim(),
                                  registrationNumber: regCtrl.text.trim(),
                                  countryCode: country,
                                  planTier: tier,
                                  licenseSeats: seats,
                                  isActive: active,
                                  renewalDate: DateTime.now().add(const Duration(days: 365)),
                                ),
                              );
                            }
                          });
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

  Widget _formField(String label, TextEditingController ctrl, String hint) {
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
    final filteredTenants = _tenants.where((t) {
      final q = _searchCtrl.text.toLowerCase();
      final matchesSearch = t.name.toLowerCase().contains(q) || t.registrationNumber.toLowerCase().contains(q);
      if (!matchesSearch) return false;
      if (_countryFilter != 'ALL' && t.countryCode != _countryFilter) return false;
      return true;
    }).toList();

    final totalSeats = _tenants.fold<int>(0, (sum, t) => sum + t.licenseSeats);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A101D),
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFA855F7), size: 22),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("SAAS SUPER ADMIN COCKPIT", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                Text("Global Multi-Tenant Platform Engine", style: TextStyle(color: Color(0xFF64748B), fontSize: 8)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Switch Language",
            icon: const Icon(Icons.language_rounded, color: Color(0xFF38BDF8), size: 20),
            onPressed: () {
              LocaleService.toggleLanguage();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 18),
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Row(
            children: [
              _kpiCard("TOTAL TENANTS", "${_tenants.length}", Icons.apartment_rounded, const Color(0xFFA855F7)),
              const SizedBox(width: 8),
              _kpiCard("ACTIVE SEATS", "$totalSeats", Icons.badge_rounded, const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              _kpiCard("COMPLIANCE", "100%", Icons.verified_rounded, const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    decoration: InputDecoration(
                      hintText: "Search company name, NTN, reg #...",
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.domain_add_rounded, color: Colors.white, size: 16),
                  label: const Text("ONBOARD COMPANY", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                  onPressed: () => _openCompanyModal(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _filterTab('ALL', "ALL REGIONS (${_tenants.length})"),
              const SizedBox(width: 6),
              _filterTab('MY', "🇲🇾 MALAYSIA (${_tenants.where((t) => t.countryCode == 'MY').length})"),
              const SizedBox(width: 6),
              _filterTab('PK', "🇵🇰 PAKISTAN (${_tenants.where((t) => t.countryCode == 'PK').length})"),
              const SizedBox(width: 6),
              _filterTab('GLOBAL', "🌐 GLOBAL (${_tenants.where((t) => t.countryCode == 'GLOBAL').length})"),
            ],
          ),
          const SizedBox(height: 12),

          ...filteredTenants.map((tenant) {
            String flag = '🌐';
            if (tenant.countryCode == 'MY') flag = '🇲🇾';
            if (tenant.countryCode == 'PK') flag = '🇵🇰';

            return Container(
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Center(
                      child: Text(flag, style: const TextStyle(fontSize: 16)),
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
                            Flexible(
                              child: Text(tenant.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: tenant.isActive ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                tenant.isActive ? "ACTIVE" : "SUSPENDED",
                                style: TextStyle(
                                  color: tenant.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontSize: 6,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text("${tenant.registrationNumber} • Tier: ${tenant.planTier}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                        const SizedBox(height: 2),
                        Text("Seats: ${tenant.licenseSeats} • Region: ${tenant.countryCode}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.login_rounded, color: Color(0xFF10B981), size: 20),
                    tooltip: "Impersonate Tenant HQ",
                    onPressed: () => _triggerImpersonation(tenant),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 20),
                    tooltip: "Edit Company Profile",
                    onPressed: () => _openCompanyModal(editTenant: tenant),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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

  Widget _filterTab(String key, String title) {
    final isSelected = _countryFilter == key;
    return InkWell(
      onTap: () => setState(() => _countryFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA855F7).withValues(alpha: 0.2) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFFA855F7) : const Color(0xFF1E293B)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFA855F7) : const Color(0xFF64748B),
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
