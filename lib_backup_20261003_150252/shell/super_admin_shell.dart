import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/module_registry.dart';
import '../models/user_session.dart';

class SuperAdminShell extends StatefulWidget {
  final UserSession session;
  final Function(UserSession) onImpersonateCompany;
  final VoidCallback onLogout;

  const SuperAdminShell({
    super.key,
    required this.session,
    required this.onImpersonateCompany,
    required this.onLogout,
  });

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  String _searchCompany = '';

  final List<Map<String, dynamic>> _tenants = [
    {
      'id': 'tenant_alphatec_01',
      'name': 'AlphaTech Networks Sdn Bhd',
      'brand': 'AlphaTech IT & Electrical',
      'country': 'MY',
      'flag': '🇲🇾',
      'currency': 'RM',
      'reg_body': 'CIDB G7 & ST (PW4/A4)',
      'roc': '201901048821 (1358912-W)',
      'tax_id': 'SST-W10-1808-320000',
      'director': 'Ir. Hazwan Bin Roslan',
      'city': 'Puchong, Selangor',
      'plan': 'ENTERPRISE SUITE',
      'status': 'ACTIVE',
      'tech_count': 18,
      'van_count': 4,
      'mrr': 'RM 2,800 / mo',
      'specializations': ['CCTV Megapixel', 'Street Lighting', 'Fiber ELV'],
      'enabled_modules': ['CREDENTIALS_GATEKEEPER', 'BIOMETRICS_TELEMETRY', 'VAN_INVENTORY_SYSTEM', 'TESTING_COMMISSIONING'],
    },
    {
      'id': 'tenant_lahore_cctv_02',
      'name': 'Lahore Smart Surveillance & Infra Ltd',
      'brand': 'SafeCity Infra PK',
      'country': 'PK',
      'flag': '🇵🇰',
      'currency': 'PKR ₨',
      'reg_body': 'PEC C-3 (EE02/EE06)',
      'roc': 'CUIN: 0148821',
      'tax_id': 'NTN: 8841920-1 (PRA Reg)',
      'director': 'Engr. M. Usman Tariq (PE-44812)',
      'city': 'Gulberg III, Lahore',
      'plan': 'ENTERPRISE SUITE',
      'status': 'ACTIVE',
      'tech_count': 26,
      'van_count': 6,
      'mrr': 'PKR 185k / mo',
      'specializations': ['SafeCity Surveillance', 'High-Mast Lighting', 'Access Control'],
      'enabled_modules': ['CREDENTIALS_GATEKEEPER', 'BIOMETRICS_TELEMETRY', 'VAN_INVENTORY_SYSTEM', 'TESTING_COMMISSIONING'],
    },
  ];

  List<Map<String, dynamic>> get _filteredTenants {
    return _tenants.where((t) {
      final q = _searchCompany.toLowerCase();
      return t['name'].toString().toLowerCase().contains(q) ||
          t['id'].toString().toLowerCase().contains(q) ||
          t['director'].toString().toLowerCase().contains(q) ||
          t['city'].toString().toLowerCase().contains(q) ||
          t['country'].toString().toLowerCase().contains(q);
    }).toList();
  }

  void _openEnterpriseOnboardModal() {
    String selectedCountry = 'MY';
    String selectedGrade = 'G7 (Unlimited)';
    String selectedPlan = 'ENTERPRISE SUITE';
    String paymentTerms = 'Net 30 Days';

    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final rocController = TextEditingController();
    final directorController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final taxIdController = TextEditingController();
    final techQuotaController = TextEditingController(text: '15');
    final vanQuotaController = TextEditingController(text: '4');
    final mrrController = TextEditingController(text: '2,800');

    final Set<String> activeSpecializations = {'CCTV IP Surveillance', 'Smart Street Lighting'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070D18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 14,
                left: 16,
                right: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.domain_add_rounded, color: Color(0xFFA855F7), size: 18),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ENTERPRISE TENANT PROVISIONING", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                                  Text("Statutory Compliance & Operations Dossier Setup", style: TextStyle(color: Color(0xFF64748B), fontSize: 8)),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 16),

                      // 1. Regional Jurisdiction Selector
                      const Text("1. REGIONAL JURISDICTION & STATUTORY DOMAIN", style: TextStyle(color: Color(0xFFA855F7), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _marketCard('MY', 'Malaysia 🇲🇾', 'CIDB • ST • SST 8%', selectedCountry, (c) {
                            setModalState(() {
                              selectedCountry = c;
                              selectedGrade = 'G7 (Unlimited)';
                              mrrController.text = '2,800';
                            });
                          }),
                          const SizedBox(width: 6),
                          _marketCard('PK', 'Pakistan 🇵🇰', 'PEC • NEPRA • FBR', selectedCountry, (c) {
                            setModalState(() {
                              selectedCountry = c;
                              selectedGrade = 'C-3 (Medium)';
                              mrrController.text = '185,000';
                            });
                          }),
                          const SizedBox(width: 6),
                          _marketCard('GLOBAL', 'Global 🌐', 'IEC • OSHA • VAT', selectedCountry, (c) {
                            setModalState(() {
                              selectedCountry = c;
                              selectedGrade = 'Tier-1 Certified';
                              mrrController.text = '650';
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 2. Corporate Identity
                      const Text("2. CORPORATE & EXECUTIVE IDENTITY", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      _field("Full Legal Registered Name", selectedCountry == 'PK' ? "e.g. Islamabad Smart Utility Solutions Pvt Ltd" : "e.g. MegaPower Electrical & CCTV Sdn Bhd", nameController, Icons.business_rounded),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _field("Trade / App Brand Name", "e.g. MegaPower Infra", brandController, Icons.branding_watermark_rounded)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _field(
                              selectedCountry == 'PK' ? "CUIN / Incorporation No" : "SSM / ROC Number",
                              selectedCountry == 'PK' ? "CUIN: 0098412" : "202601004812 (1450211-T)",
                              rocController,
                              Icons.verified_user_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _field(selectedCountry == 'PK' ? "PEC Engineer / Director" : "Managing Director", selectedCountry == 'PK' ? "Engr. Asif Khan (PE)" : "Ir. Daniel Wong", directorController, Icons.person_rounded)),
                          const SizedBox(width: 6),
                          Expanded(child: _field("Official Contact Tel", selectedCountry == 'PK' ? "+92 42 3578 9900" : "+60 3-8080 9900", phoneController, Icons.phone_rounded)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _field("Operations Base & HQ Address", selectedCountry == 'PK' ? "e.g. Plot 44-B, Industrial Area, Gulberg III, Lahore" : "e.g. Level 8, Puchong Financial Corporate Centre, Selangor", addressController, Icons.location_on_rounded),
                      const SizedBox(height: 12),

                      // 3. Technical Licensing & Specializations
                      Text("3. STATUTORY LICENSING (${selectedCountry == 'PK' ? 'PEC / NEPRA' : (selectedCountry == 'MY' ? 'CIDB / SURUHANJAYA TENAGA' : 'IEC / OSHA')})", style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedCountry == 'PK' ? "PEC License Grade" : (selectedCountry == 'MY' ? "CIDB Contractor Grade" : "Engineering Tier"), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                  child: DropdownButton<String>(
                                    value: selectedGrade,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: const Color(0xFF161F30),
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                    items: (selectedCountry == 'PK'
                                        ? ['C-6 (Upto 25M)', 'C-5 (Upto 65M)', 'C-4 (Upto 200M)', 'C-3 (Medium)', 'C-A (Unlimited)']
                                        : (selectedCountry == 'MY'
                                            ? ['G1 (Below 200k)', 'G2 (Below 500k)', 'G3 (Below 1M)', 'G4 (Below 3M)', 'G5 (Below 5M)', 'G7 (Unlimited)']
                                            : ['Tier-1 Certified', 'Tier-2 Certified', 'Global Partner']))
                                        .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedGrade = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _field(
                              selectedCountry == 'PK' ? "NTN / Tax ID (FBR)" : "LHDN SST Tax ID",
                              selectedCountry == 'PK' ? "NTN: 8841920-1" : "SST-W10-1808-9900",
                              taxIdController,
                              Icons.receipt_long_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      const Text("Contractor Trade Disciplines (Pre-configure Module Data):", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          'CCTV IP Surveillance',
                          'Smart Street Lighting',
                          '3-Phase Power (PW4/EE11)',
                          'Fiber Optic & ELV',
                          'Access Control Biometrics',
                          'Highway High-Mast Lighting',
                        ].map((spec) {
                          final isSelected = activeSpecializations.contains(spec);
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                isSelected ? activeSpecializations.remove(spec) : activeSpecializations.add(spec);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF030712),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B)),
                              ),
                              child: Text(
                                spec,
                                style: TextStyle(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // 4. Quotas & Commercial Billing
                      const Text("4. FLEET QUOTAS & COMMERCIAL LICENSE", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _field("Tech Quota", "15", techQuotaController, Icons.engineering_rounded, isNum: true)),
                          const SizedBox(width: 6),
                          Expanded(child: _field("Van Fleet Slots", "4", vanQuotaController, Icons.airport_shuttle_rounded, isNum: true)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _field(
                              "Monthly Fee (${selectedCountry == 'PK' ? 'PKR ₨' : (selectedCountry == 'MY' ? 'RM' : '\$')})",
                              "Fee",
                              mrrController,
                              Icons.payments_rounded,
                              isNum: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Platform Tier", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                  child: DropdownButton<String>(
                                    value: selectedPlan,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: const Color(0xFF161F30),
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                    items: const [
                                      DropdownMenuItem(value: 'STARTER TIER', child: Text("Starter Tier")),
                                      DropdownMenuItem(value: 'PROFESSIONAL TIER', child: Text("Professional Tier")),
                                      DropdownMenuItem(value: 'ENTERPRISE SUITE', child: Text("Enterprise Suite")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedPlan = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Payment Terms", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                  child: DropdownButton<String>(
                                    value: paymentTerms,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: const Color(0xFF161F30),
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                    items: const [
                                      DropdownMenuItem(value: 'Net 30 Days', child: Text("Net 30 Days")),
                                      DropdownMenuItem(value: 'Net 60 Days', child: Text("Net 60 Days")),
                                      DropdownMenuItem(value: 'Milestone Progress', child: Text("Milestone Progress")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => paymentTerms = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Final Submit Action
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA855F7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                          label: Text(
                            "PROVISION & DEPLOY ${selectedCountry == 'PK' ? 'PAKISTAN 🇵🇰' : (selectedCountry == 'MY' ? 'MALAYSIA 🇲🇾' : 'GLOBAL 🌐')} TENANT",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                          ),
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) return;

                            final flag = selectedCountry == 'PK' ? '🇵🇰' : (selectedCountry == 'MY' ? '🇲🇾' : '🌐');
                            final currency = selectedCountry == 'PK' ? 'PKR ₨' : (selectedCountry == 'MY' ? 'RM' : '\$');
                            final regBody = selectedCountry == 'PK'
                                ? 'PEC $selectedGrade'
                                : (selectedCountry == 'MY' ? 'CIDB $selectedGrade & ST' : 'IEC / OSHA $selectedGrade');

                            setState(() {
                              _tenants.insert(0, {
                                'id': 'tenant_${DateTime.now().millisecondsSinceEpoch}',
                                'name': nameController.text.trim(),
                                'brand': brandController.text.trim().isEmpty ? nameController.text.trim() : brandController.text.trim(),
                                'country': selectedCountry,
                                'flag': flag,
                                'currency': currency,
                                'reg_body': regBody,
                                'roc': rocController.text.trim().isEmpty ? 'REG-2026-ACTIVE' : rocController.text.trim(),
                                'tax_id': taxIdController.text.trim().isEmpty ? 'TAX-ACTIVE' : taxIdController.text.trim(),
                                'director': directorController.text.trim().isEmpty ? 'Managing Director' : directorController.text.trim(),
                                'city': addressController.text.trim().isEmpty ? 'HQ Base' : addressController.text.trim(),
                                'plan': selectedPlan,
                                'status': 'ACTIVE',
                                'tech_count': int.tryParse(techQuotaController.text.trim()) ?? 10,
                                'van_count': int.tryParse(vanQuotaController.text.trim()) ?? 2,
                                'mrr': '$currency ${mrrController.text.trim()} / mo',
                                'specializations': activeSpecializations.toList(),
                                'enabled_modules': ['CREDENTIALS_GATEKEEPER', 'BIOMETRICS_TELEMETRY', 'VAN_INVENTORY_SYSTEM', 'TESTING_COMMISSIONING'],
                              });
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Tenant '${nameController.text}' provisioned with $selectedGrade & Tax Engine!"),
                                backgroundColor: const Color(0xFFA855F7),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _marketCard(String code, String title, String subtitle, String selected, Function(String) onSelect) {
    final isSelected = code == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(code),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFA855F7).withValues(alpha: 0.2) : const Color(0xFF161F30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFFA855F7) : const Color(0xFF26324D)),
          ),
          child: Column(
            children: [
              Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900)),
              Text(subtitle, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller, IconData icon, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 9),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 8),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 12),
            filled: true,
            fillColor: const Color(0xFF161F30),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFA855F7))),
          ),
        ),
      ],
    );
  }

  void _openTenantModuleConfig(Map<String, dynamic> tenant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1120),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> activeMods = List<String>.from(tenant['enabled_modules'] as List);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(tenant['flag'] as String, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "TENANT MODULE RIGHTS",
                                    style: TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                                  ),
                                ],
                              ),
                              Text(
                                tenant['name'] as String,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B)),
                    const SizedBox(height: 10),

                    _moduleToggleItem(
                      id: 'CREDENTIALS_GATEKEEPER',
                      name: 'Module 1: Statutory Dossier (${tenant['reg_body']})',
                      isActive: activeMods.contains('CREDENTIALS_GATEKEEPER'),
                      onChanged: (val) {
                        setModalState(() {
                          val ? activeMods.add('CREDENTIALS_GATEKEEPER') : activeMods.remove('CREDENTIALS_GATEKEEPER');
                          tenant['enabled_modules'] = activeMods;
                        });
                        setState(() {});
                      },
                    ),
                    _moduleToggleItem(
                      id: 'BIOMETRICS_TELEMETRY',
                      name: 'Module 2: Google ML Kit Biometric Telemetry',
                      isActive: activeMods.contains('BIOMETRICS_TELEMETRY'),
                      onChanged: (val) {
                        setModalState(() {
                          val ? activeMods.add('BIOMETRICS_TELEMETRY') : activeMods.remove('BIOMETRICS_TELEMETRY');
                          tenant['enabled_modules'] = activeMods;
                        });
                        setState(() {});
                      },
                    ),
                    _moduleToggleItem(
                      id: 'VAN_INVENTORY_SYSTEM',
                      name: 'Module 3: Master Inventory Hub & Van Stores',
                      isActive: activeMods.contains('VAN_INVENTORY_SYSTEM'),
                      onChanged: (val) {
                        setModalState(() {
                          val ? activeMods.add('VAN_INVENTORY_SYSTEM') : activeMods.remove('VAN_INVENTORY_SYSTEM');
                          tenant['enabled_modules'] = activeMods;
                        });
                        setState(() {});
                      },
                    ),
                    _moduleToggleItem(
                      id: 'TESTING_COMMISSIONING',
                      name: 'Module 4: Smart Testing & Commissioning (T&C)',
                      isActive: activeMods.contains('TESTING_COMMISSIONING'),
                      onChanged: (val) {
                        setModalState(() {
                          val ? activeMods.add('TESTING_COMMISSIONING') : activeMods.remove('TESTING_COMMISSIONING');
                          tenant['enabled_modules'] = activeMods;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA855F7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Module rights updated for ${tenant['name']}"),
                              backgroundColor: const Color(0xFFA855F7),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text("APPLY SUBSCRIPTION RIGHTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
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

  Widget _moduleToggleItem({
    required String id,
    required String name,
    required bool isActive,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? const Color(0xFFA855F7).withValues(alpha: 0.4) : const Color(0xFF26324D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                Text("Plugin ID: $id", style: const TextStyle(color: Color(0xFF64748B), fontSize: 8)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: isActive,
              activeThumbColor: const Color(0xFFA855F7),
              activeTrackColor: const Color(0xFF581C87),
              inactiveThumbColor: const Color(0xFF64748B),
              inactiveTrackColor: const Color(0xFF1E293B),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToCompanyAdmin(Map<String, dynamic> tenant) {
    final String cCode = tenant['country'] ?? 'MY';
    final tenantSession = UserSession(
      id: 'usr_director_${tenant['id']}',
      token: 'impersonated_token',
      name: tenant['director'] as String,
      email: 'ops@alphatec.my',
      role: 'ADMIN',
      tenantId: tenant['id'] as String,
      companyName: tenant['name'] as String,
      planTier: tenant['plan'] as String,
      countryCode: cCode,
      currencySymbol: tenant['currency'] ?? 'RM',
      regulatoryBody: tenant['reg_body'] ?? (cCode == 'PK' ? 'PEC & NEPRA' : 'CIDB & ST'),
      taxEngine: cCode == 'PK' ? 'FBR Digital Invoicing (PRA/SRB)' : 'LHDN MyInvois (SST 8%)',
    );

    final Map<String, bool> parsed = {};
    for (var m in (tenant['enabled_modules'] as List)) {
      parsed[m.toString()] = true;
    }
    context.read<ModuleRegistry>().loadFromBackend(parsed);

    widget.onImpersonateCompany(tenantSession);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1E),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1E293B)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7E22CE)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.public_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "FIELDOPS GLOBAL ROOT",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6),
                  ),
                  Text(
                    "Malaysia 🇲🇾 • Pakistan 🇵🇰 • Global 🌐",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 20),
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _superMetricCard("GLOBAL RECURRING MRR", "RM 42,850.00", "MYR & PKR Multi-Currency", const Color(0xFF10B981), Icons.payments_rounded),
            const SizedBox(height: 6),
            _superMetricCard("ACTIVE SUBSCRIBERS", "${_tenants.length} Tenants", "🇲🇾 Malaysia & 🇵🇰 Pakistan", const Color(0xFF38BDF8), Icons.business_rounded),
            const SizedBox(height: 6),
            _superMetricCard("FIELD WORKFORCE", "110 Active Techs", "36 Mobile Vans Deployed", const Color(0xFFA855F7), Icons.engineering_rounded),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "SUBSCRIBER TENANTS",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 28),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 12),
                  label: const Text(
                    "+ ONBOARD",
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                  onPressed: _openEnterpriseOnboardModal,
                ),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 34,
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 10),
                onChanged: (val) => setState(() => _searchCompany = val),
                decoration: InputDecoration(
                  hintText: "Search company, ROC, NTN, city...",
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 12),
                  filled: true,
                  fillColor: const Color(0xFF0B132B),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                ),
              ),
            ),
            const SizedBox(height: 10),

            ..._filteredTenants.map((tenant) {
              final String status = tenant['status'] as String;
              final bool isActive = status == 'ACTIVE';
              final String flag = tenant['flag'] ?? '🌐';
              final List enabledMods = tenant['enabled_modules'] as List;
              final List specs = (tenant['specializations'] as List?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? const Color(0xFF1E293B) : const Color(0xFFF43F5E).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(flag, style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant['name'] as String,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "${tenant['country']} • ${tenant['plan']}",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${tenant['mrr']}",
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              fontSize: 6,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Reg: ${tenant['roc']} • ${tenant['tax_id']} • Lead: ${tenant['director']}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 7),
                    ),
                    Text(
                      "Base: ${tenant['city']} • Authority: ${tenant['reg_body']}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7),
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 12),

                    if (specs.isNotEmpty) ...[
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: specs.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                            ),
                            child: Text(s.toString(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 6, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                    ],

                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: enabledMods.map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            m.toString().replaceAll('_', ' '),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 6, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFA855F7)),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: const Size(50, 26),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => _openTenantModuleConfig(tenant),
                            child: const Text("MODULES", style: TextStyle(color: Color(0xFFA855F7), fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: const Size(50, 26),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () => _jumpToCompanyAdmin(tenant),
                            child: Text(
                              "ENTER ${tenant['country']}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _superMetricCard(String label, String value, String subtext, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                Text(subtext, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
