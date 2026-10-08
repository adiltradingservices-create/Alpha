import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../models/tenant_subscription.dart';
import '../services/central_operations_store.dart';

class SuperAdminShell extends StatefulWidget {
  final UserSession session;
  final Function(UserSession impersonatedSession) onImpersonateCompany;
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
  final CentralOperationsStore _store = CentralOperationsStore();
  String _searchFilter = '';

  List<TenantSubscription> get _clients => _store.clients;

  void _applySubscriptionToStore(TenantSubscription client) {
    _store.updateConfig(
      name: client.companyName,
      biometrics: client.enableBiometrics,
      vanStores: client.enableVanStores,
      testing: client.enableTestingCommissioning,
      signOff: client.enableClientEndorsement,
    );
  }

  void _impersonate(TenantSubscription client) {
    _applySubscriptionToStore(client);

    final isPk = client.countryCode == 'PK';
    final isSg = client.countryCode == 'SG';

    final impersonated = UserSession(
      id: "SA-IMP-${client.tenantId}",
      token: "TOKEN-SA-${client.tenantId}",
      name: "${client.companyName} Superuser",
      email: client.contactEmail,
      role: 'ADMIN',
      tenantId: client.tenantId,
      companyName: client.companyName,
      planTier: client.tier.name.toUpperCase(),
      countryCode: client.countryCode,
      currencySymbol: isPk ? 'PKR ' : (isSg ? 'SGD' : 'RM'),
      regulatoryBody: client.regulatoryBody.isNotEmpty
          ? client.regulatoryBody
          : (isPk ? 'PEC & NEPRA' : (isSg ? 'BCA / EMA' : 'CIDB & ST')),
      taxEngine: client.taxEngine.isNotEmpty
          ? client.taxEngine
          : (isPk ? 'FBR Digital (18%)' : (isSg ? 'IRAS GST (9%)' : 'LHDN MyInvois (SST 8%)')),
      taxRate: client.taxRate > 0 ? client.taxRate : (isPk ? 0.18 : (isSg ? 0.09 : 0.08)),
    );

    widget.onImpersonateCompany(impersonated);
  }

  void _openTenantEditorModal({TenantSubscription? existingTenant}) {
    final isEditing = existingTenant != null;

    final companyCtrl = TextEditingController(text: existingTenant?.companyName ?? '');
    final regNoCtrl = TextEditingController(text: existingTenant?.registrationNumber ?? 'ROC-2026-');
    final tenantIdCtrl = TextEditingController(
      text: existingTenant?.tenantId ?? "TENANT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
    );
    final emailCtrl = TextEditingController(text: existingTenant?.contactEmail ?? '');
    final phoneCtrl = TextEditingController(text: existingTenant?.contactPhone ?? '+60 12-');
    final maxTechsCtrl = TextEditingController(text: (existingTenant?.maxTechnicians ?? 25).toString());
    final maxVansCtrl = TextEditingController(text: (existingTenant?.maxVans ?? 10).toString());

    String country = existingTenant?.countryCode ?? 'MY';
    SubscriptionTier tier = existingTenant?.tier ?? SubscriptionTier.professional;
    TenantStatus status = existingTenant?.status ?? TenantStatus.active;
    DateTime expiryDate = existingTenant?.validUntil ?? DateTime.now().add(const Duration(days: 365));

    bool biometrics = existingTenant?.enableBiometrics ?? true;
    bool vanStores = existingTenant?.enableVanStores ?? true;
    bool testing = existingTenant?.enableTestingCommissioning ?? true;
    bool signOff = existingTenant?.enableClientEndorsement ?? true;
    bool cloudSync = existingTenant?.enableCloudSync ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isEditing ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.domain_add_rounded,
                                color: isEditing ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? "MANAGE TENANT ENTITY & LICENSING" : "ENTERPRISE TENANT ONBOARDING",
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  isEditing ? "Tenant ID: ${existingTenant.tenantId}" : "Configure multi-region regulatory and module profile",
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Legal Entity & Identity
                    _sectionHeader("1. LEGAL ENTITY & IDENTIFICATION", Icons.business_rounded),
                    const SizedBox(height: 8),
                    _inputField(label: "REGISTERED CORPORATE NAME", ctrl: companyCtrl, hint: "e.g. IDSB Technologies Sdn Bhd"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _inputField(label: "BUSINESS REG NO (ROC / SSM / SECP)", ctrl: regNoCtrl, hint: "e.g. 202401029384 (1598-A)")),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _inputField(
                            label: "TENANT CODE / IDENTIFIER",
                            ctrl: tenantIdCtrl,
                            hint: "TENANT-MY-01",
                            enabled: !isEditing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _inputField(label: "PRIMARY BILLING / ADMIN EMAIL", ctrl: emailCtrl, hint: "corporate@domain.com")),
                        const SizedBox(width: 8),
                        Expanded(child: _inputField(label: "EMERGENCY OPS PHONE", ctrl: phoneCtrl, hint: "+60 12-345 6789")),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Regional Compliance & Tax Engine
                    _sectionHeader("2. REGIONAL COMPLIANCE & STATUTORY TAX", Icons.gavel_rounded),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("JURISDICTION / REGION", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF020617),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF1E293B)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: country,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF0F172A),
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5),
                                    items: const [
                                      DropdownMenuItem(value: 'MY', child: Text("[MY] Malaysia (CIDB & ST / SST 8%)")),
                                      DropdownMenuItem(value: 'PK', child: Text("[PK] Pakistan (PEC / FBR 18%)")),
                                      DropdownMenuItem(value: 'SG', child: Text("[SG] Singapore (BCA / GST 9%)")),
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
                              const Text("ACCOUNT STATUS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF020617),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF1E293B)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<TenantStatus>(
                                    value: status,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF0F172A),
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5),
                                    items: const [
                                      DropdownMenuItem(value: TenantStatus.active, child: Text("ACTIVE / HEALTHY")),
                                      DropdownMenuItem(value: TenantStatus.gracePeriod, child: Text("GRACE PERIOD")),
                                      DropdownMenuItem(value: TenantStatus.suspended, child: Text("SUSPENDED / LOCKED")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => status = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Subscription Tier & Operational Quotas
                    _sectionHeader("3. SUBSCRIPTION TIER & RESOURCE LIMITS", Icons.tune_rounded),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SERVICE TIER", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF020617),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF1E293B)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<SubscriptionTier>(
                                    value: tier,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF0F172A),
                                    style: const TextStyle(color: Colors.white, fontSize: 8.5),
                                    items: const [
                                      DropdownMenuItem(value: SubscriptionTier.starter, child: Text("Starter (Base Ops)")),
                                      DropdownMenuItem(value: SubscriptionTier.professional, child: Text("Professional Tier")),
                                      DropdownMenuItem(value: SubscriptionTier.enterpriseCustom, child: Text("Enterprise Custom")),
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
                        const SizedBox(width: 8),
                        Expanded(child: _inputField(label: "MAX FIELD TECHS QUOTA", ctrl: maxTechsCtrl, hint: "50")),
                        const SizedBox(width: 8),
                        Expanded(child: _inputField(label: "MAX VAN FLEETS QUOTA", ctrl: maxVansCtrl, hint: "20")),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Module Entitlements Switchboard
                    _sectionHeader("4. MODULAR ENTITLEMENTS SWITCHBOARD", Icons.extension_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _dialogToggleChip("Biometrics Attendance", biometrics, (v) => setModalState(() => biometrics = v)),
                        _dialogToggleChip("Van Stores & Barcode", vanStores, (v) => setModalState(() => vanStores = v)),
                        _dialogToggleChip("Testing & Commissioning", testing, (v) => setModalState(() => testing = v)),
                        _dialogToggleChip("Client Sign-Off & Photos", signOff, (v) => setModalState(() => signOff = v)),
                        _dialogToggleChip("Cloud Offline Sync", cloudSync, (v) => setModalState(() => cloudSync = v)),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Submit Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditing ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(isEditing ? Icons.check_circle_rounded : Icons.save_rounded, size: 16),
                        label: Text(
                          isEditing ? "SAVE & COMMIT TENANT CHANGES" : "INITIALIZE & PROVISION ENTERPRISE TENANT",
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          if (companyCtrl.text.trim().isEmpty) return;

                          final cCode = country;
                          final isPk = cCode == 'PK';
                          final isSg = cCode == 'SG';

                          final currency = isPk ? 'PKR' : (isSg ? 'SGD' : 'MYR');
                          final regBody = isPk ? 'PEC & NEPRA' : (isSg ? 'BCA / EMA' : 'CIDB & ST');
                          final taxEngine = isPk ? 'FBR Digital (18%)' : (isSg ? 'IRAS GST (9%)' : 'LHDN MyInvois (SST 8%)');
                          final taxRate = isPk ? 0.18 : (isSg ? 0.09 : 0.08);

                          if (isEditing) {
                            existingTenant.updateDetails(
                              companyName: companyCtrl.text.trim(),
                              registrationNumber: regNoCtrl.text.trim(),
                              contactEmail: emailCtrl.text.trim(),
                              contactPhone: phoneCtrl.text.trim(),
                              countryCode: country,
                              currency: currency,
                              regulatoryBody: regBody,
                              taxEngine: taxEngine,
                              taxRate: taxRate,
                              tier: tier,
                              status: status,
                              validUntil: expiryDate,
                              maxTechnicians: int.tryParse(maxTechsCtrl.text.trim()) ?? 25,
                              maxVans: int.tryParse(maxVansCtrl.text.trim()) ?? 10,
                              enableBiometrics: biometrics,
                              enableVanStores: vanStores,
                              enableTestingCommissioning: testing,
                              enableClientEndorsement: signOff,
                              enableCloudSync: cloudSync,
                            );
                            _store.updateTenantSubscription(existingTenant);
                          } else {
                            final newClient = TenantSubscription(
                              tenantId: tenantIdCtrl.text.trim(),
                              companyName: companyCtrl.text.trim(),
                              registrationNumber: regNoCtrl.text.trim(),
                              countryCode: country,
                              currency: currency,
                              regulatoryBody: regBody,
                              taxEngine: taxEngine,
                              taxRate: taxRate,
                              contactEmail: emailCtrl.text.trim().isEmpty ? 'admin@${tenantIdCtrl.text.trim().toLowerCase()}.com' : emailCtrl.text.trim(),
                              contactPhone: phoneCtrl.text.trim(),
                              tier: tier,
                              status: status,
                              validUntil: expiryDate,
                              maxTechnicians: int.tryParse(maxTechsCtrl.text.trim()) ?? 25,
                              maxVans: int.tryParse(maxVansCtrl.text.trim()) ?? 10,
                              enableBiometrics: biometrics,
                              enableVanStores: vanStores,
                              enableTestingCommissioning: testing,
                              enableClientEndorsement: signOff,
                              enableCloudSync: cloudSync,
                            );
                            _store.provisionTenant(newClient);
                          }

                          Navigator.pop(modalCtx);
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF10B981),
                              content: Text(isEditing ? "Updated: ${companyCtrl.text.trim()}" : "Provisioned: ${companyCtrl.text.trim()}"),
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
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7.5, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _dialogToggleChip(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF020617),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: value ? const Color(0xFF10B981) : const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: value ? const Color(0xFF10B981) : const Color(0xFF64748B),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: value ? Colors.white : const Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.white : const Color(0xFF64748B), fontSize: 8.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 8),
            isDense: true,
            filled: true,
            fillColor: enabled ? const Color(0xFF020617) : const Color(0xFF0B1120),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClients = _clients.where((c) {
      final q = _searchFilter.toLowerCase();
      return c.companyName.toLowerCase().contains(q) ||
          c.tenantId.toLowerCase().contains(q) ||
          c.countryCode.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: const Icon(Icons.hub_rounded, color: Color(0xFF818CF8), size: 16),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("GLOBAL SAAS MASTER", overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                  Text("Tenant Matrix & Modules", overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_business_rounded, size: 14),
            label: const Text("PROVISION CLIENT", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
            onPressed: () => _openTenantEditorModal(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 18),
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. KPI Telemetry Bar
          Row(
            children: [
              _kpiMetric("CLIENT TENANTS", "${_clients.length}", Icons.apartment_rounded, const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              _kpiMetric("ACTIVE MODULES", "14 Active", Icons.extension_rounded, const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _kpiMetric("SLA HEALTH", "99.98%", Icons.shield_rounded, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Search & Filter Bar
          SizedBox(
            height: 38,
            child: TextField(
              onChanged: (val) => setState(() => _searchFilter = val),
              style: const TextStyle(color: Colors.white, fontSize: 9.5),
              decoration: InputDecoration(
                hintText: "Search Client Name, Tenant ID, or Country...",
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text("CLIENT TENANTS & MODULE SUBSCRIPTION MATRIX", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),

          // 3. Client Subscription Cards
          ...filteredClients.map((client) => _buildClientSubscriptionCard(client)),
        ],
      ),
    );
  }

  Widget _buildClientSubscriptionCard(TenantSubscription client) {
    final flag = "[${client.countryCode}]";
    final tierColor = client.tier == SubscriptionTier.enterpriseCustom
        ? const Color(0xFF818CF8)
        : (client.tier == SubscriptionTier.professional ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.companyName, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                      Text("ID: ${client.tenantId} � ROC: ${client.registrationNumber} � Reg: ${client.regulatoryBody}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 7)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tierColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    client.tier.name.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(color: tierColor, fontSize: 6.5, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 6),
                // Edit Tenant Details Action
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 18),
                  tooltip: "Edit Company Details",
                  onPressed: () => _openTenantEditorModal(existingTenant: client),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 12),
                  label: const Text("IMPERSONATE", style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900)),
                  onPressed: () => _impersonate(client),
                ),
              ],
            ),
          ),

          // Operational Quotas & Module Controls Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("QUOTA: ${client.maxTechnicians} TECHS | ${client.maxVans} VANS", style: const TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                    Text("TAX: ${client.taxEngine}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _moduleToggleChip(
                      label: "Attendance & Biometrics",
                      code: "BIOMETRICS_TELEMETRY",
                      isActive: client.enableBiometrics,
                      icon: Icons.face_rounded,
                      onToggle: (val) {
                        setState(() => client.toggleModule("BIOMETRICS_TELEMETRY", val));
                        _applySubscriptionToStore(client);
                      },
                    ),
                    _moduleToggleChip(
                      label: "Van Stores & Hardware Barcode",
                      code: "VAN_INVENTORY_SYSTEM",
                      isActive: client.enableVanStores,
                      icon: Icons.airport_shuttle_rounded,
                      onToggle: (val) {
                        setState(() => client.toggleModule("VAN_INVENTORY_SYSTEM", val));
                        _applySubscriptionToStore(client);
                      },
                    ),
                    _moduleToggleChip(
                      label: "Testing, Checklist & PM",
                      code: "TESTING_COMMISSIONING",
                      isActive: client.enableTestingCommissioning,
                      icon: Icons.checklist_rtl_rounded,
                      onToggle: (val) {
                        setState(() => client.toggleModule("TESTING_COMMISSIONING", val));
                        _applySubscriptionToStore(client);
                      },
                    ),
                    _moduleToggleChip(
                      label: "Sign-Off & Photo Docket",
                      code: "CLIENT_ENDORSEMENT",
                      isActive: client.enableClientEndorsement,
                      icon: Icons.camera_alt_rounded,
                      onToggle: (val) {
                        setState(() => client.toggleModule("CLIENT_ENDORSEMENT", val));
                        _applySubscriptionToStore(client);
                      },
                    ),
                    _moduleToggleChip(
                      label: "Offline Cloud Sync Journal",
                      code: "CLOUD_SYNC",
                      isActive: client.enableCloudSync,
                      icon: Icons.sync_rounded,
                      onToggle: (val) => setState(() => client.toggleModule("CLOUD_SYNC", val)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleToggleChip({
    required String label,
    required String code,
    required bool isActive,
    required IconData icon,
    required ValueChanged<bool> onToggle,
  }) {
    return InkWell(
      onTap: () => onToggle(!isActive),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFF1E293B).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.7) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? const Color(0xFF10B981) : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontSize: 7.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 11,
              color: isActive ? const Color(0xFF10B981) : const Color(0xFF475569),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.bold)),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
