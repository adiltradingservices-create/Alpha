import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../models/e_invoice_config.dart';
import '../services/central_operations_store.dart';

class EInvoiceConfigScreen extends StatefulWidget {
  final UserSession session;

  const EInvoiceConfigScreen({super.key, required this.session});

  @override
  State<EInvoiceConfigScreen> createState() => _EInvoiceConfigScreenState();
}

class _EInvoiceConfigScreenState extends State<EInvoiceConfigScreen> {
  final CentralOperationsStore _store = CentralOperationsStore();
  bool _isTesting = false;

  late TextEditingController _tinCtrl;
  late TextEditingController _sstCtrl;
  late TextEditingController _clientIdCtrl;
  late TextEditingController _clientSecretCtrl;

  late TextEditingController _ntnCtrl;
  late TextEditingController _strnCtrl;
  late TextEditingController _posIdCtrl;
  late TextEditingController _bearerTokenCtrl;

  late TextEditingController _peppolUenCtrl;
  late TextEditingController _peppolIdCtrl;
  late TextEditingController _apTokenCtrl;

  @override
  void initState() {
    super.initState();
    final cfg = _store.eInvoiceConfig;
    if (cfg.countryCode != widget.session.countryCode) {
      cfg.countryCode = widget.session.countryCode;
    }

    _tinCtrl = TextEditingController(text: cfg.lhdnTin);
    _sstCtrl = TextEditingController(text: cfg.lhdnSstNumber);
    _clientIdCtrl = TextEditingController(text: cfg.lhdnClientId);
    _clientSecretCtrl = TextEditingController(text: cfg.lhdnClientSecret);

    _ntnCtrl = TextEditingController(text: cfg.fbrNtn);
    _strnCtrl = TextEditingController(text: cfg.fbrStrn);
    _posIdCtrl = TextEditingController(text: cfg.fbrPosId);
    _bearerTokenCtrl = TextEditingController(text: cfg.fbrBearerToken);

    _peppolUenCtrl = TextEditingController(text: cfg.peppolUen);
    _peppolIdCtrl = TextEditingController(text: cfg.peppolParticipantId);
    _apTokenCtrl = TextEditingController(text: cfg.peppolAccessPointToken);
  }

  @override
  void dispose() {
    _tinCtrl.dispose();
    _sstCtrl.dispose();
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _ntnCtrl.dispose();
    _strnCtrl.dispose();
    _posIdCtrl.dispose();
    _bearerTokenCtrl.dispose();
    _peppolUenCtrl.dispose();
    _peppolIdCtrl.dispose();
    _apTokenCtrl.dispose();
    super.dispose();
  }

  void _saveConfiguration() {
    final cfg = _store.eInvoiceConfig;
    cfg.updateCredentials(
      lhdnTin: _tinCtrl.text.trim(),
      lhdnSstNumber: _sstCtrl.text.trim(),
      lhdnClientId: _clientIdCtrl.text.trim(),
      lhdnClientSecret: _clientSecretCtrl.text.trim(),
      fbrNtn: _ntnCtrl.text.trim(),
      fbrStrn: _strnCtrl.text.trim(),
      fbrPosId: _posIdCtrl.text.trim(),
      fbrBearerToken: _bearerTokenCtrl.text.trim(),
      peppolUen: _peppolUenCtrl.text.trim(),
      peppolParticipantId: _peppolIdCtrl.text.trim(),
      peppolAccessPointToken: _apTokenCtrl.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text("e-Invoicing credentials saved securely for this tenant."),
      ),
    );
  }

  Future<void> _runConnectionTest() async {
    setState(() => _isTesting = true);
    await _store.eInvoiceConfig.testConnection();
    if (mounted) setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _store.eInvoiceConfig;
    final isMy = widget.session.countryCode == 'MY';
    final isPk = widget.session.countryCode == 'PK';
    

    final regAuthority = isMy
        ? 'LHDN MyInvois (Inland Revenue Board)'
        : (isPk ? 'FBR Digital Invoicing (PRAL / IRIS)' : 'IRAS InvoiceNow (Peppol Network)');

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TENANT E-INVOICE CONFIGURATION",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
            ),
            Text(
              "${widget.session.companyName} • Reg: ${widget.session.regulatoryBody}",
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.save_rounded, size: 14),
            label: const Text("SAVE CONFIG", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
            onPressed: _saveConfiguration,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Gateway Status & Health Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          regAuthority,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cfg.isEnabled ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cfg.isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      ),
                      child: Text(
                        cfg.isEnabled ? "TRANSMISSION LIVE" : "DISABLED",
                        style: TextStyle(
                          color: cfg.isEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Tax Engine: ${widget.session.taxEngine} (Rate: ${(widget.session.taxRate * 100).toStringAsFixed(0)}%)",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cfg.lastStatusMessage,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: _isTesting
                          ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                          : const Icon(Icons.electrical_services_rounded, size: 12),
                      label: Text(_isTesting ? "CONNECTING..." : "TEST HANDSHAKE", style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900)),
                      onPressed: _isTesting ? null : _runConnectionTest,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Environment Selection & Global Toggles
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("E-INVOICE GENERATION", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      const Text("Auto-transmit signed field dockets to tax authority", style: TextStyle(color: Color(0xFF64748B), fontSize: 7)),
                    ],
                  ),
                ),
                Switch(
                  value: cfg.isEnabled,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => cfg.isEnabled = val),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EInvoiceGatewayEnvironment>(
                      value: cfg.environment,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      items: const [
                        DropdownMenuItem(value: EInvoiceGatewayEnvironment.sandbox, child: Text("Sandbox / Staging")),
                        DropdownMenuItem(value: EInvoiceGatewayEnvironment.production, child: Text("Production (Live)")),
                      ],
                      onChanged: (env) {
                        if (env != null) setState(() => cfg.environment = env);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Country-Specific Credential Form
          if (isMy) ...[
            _sectionLabel("LHDN MYINVOIS CREDENTIALS & APIS (MALAYSIA)"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _inputBox("TAXPAYER IDENTIFICATION NUMBER (TIN)", _tinCtrl, "C1234567890")),
                const SizedBox(width: 8),
                Expanded(child: _inputBox("SST REGISTRATION NUMBER", _sstCtrl, "W10-2401-3200001")),
              ],
            ),
            const SizedBox(height: 8),
            _inputBox("OAUTH 2.0 CLIENT ID", _clientIdCtrl, "e.g., d3b07384d113edec49eaa6238ad5ff00"),
            const SizedBox(height: 8),
            _inputBox("OAUTH 2.0 CLIENT SECRET", _clientSecretCtrl, "••••••••••••••••••••••••••••••••", obscure: true),
          ] else if (isPk) ...[
            _sectionLabel("FBR DIGITAL INVOICING CREDENTIALS (PAKISTAN)"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _inputBox("NATIONAL TAX NUMBER (NTN)", _ntnCtrl, "4120984-2")),
                const SizedBox(width: 8),
                Expanded(child: _inputBox("SALES TAX REGISTRATION (STRN)", _strnCtrl, "32-77-8761-001-19")),
              ],
            ),
            const SizedBox(height: 8),
            _inputBox("FBR ASSIGNED POS / BRANCH ID", _posIdCtrl, "POS-KHI-8841"),
            const SizedBox(height: 8),
            _inputBox("FBR API BEARER TOKEN / DIGITAL KEY", _bearerTokenCtrl, "••••••••••••••••••••••••••••••••", obscure: true),
          ] else ...[
            _sectionLabel("IRAS INVOICENOW / PEPPOL SPECIFICATIONS (SINGAPORE)"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _inputBox("BUSINESS UNIQUE ENTITY NUMBER (UEN)", _peppolUenCtrl, "202401928K")),
                const SizedBox(width: 8),
                Expanded(child: _inputBox("PEPPOL PARTICIPANT IDENTIFIER", _peppolIdCtrl, "0195:202401928K")),
              ],
            ),
            const SizedBox(height: 8),
            _inputBox("ACCESS POINT (AP) AUTHENTICATION TOKEN", _apTokenCtrl, "••••••••••••••••••••••••••••••••", obscure: true),
          ],
          const SizedBox(height: 20),

          // 4. Transmission & Audit Guidelines
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Each electronic invoice transmission is automatically stamped with an official IRN / UUID, embedded with a validation QR code, and archived in compliance with regional statutory retention laws (LHDN 7-Year, FBR 6-Year, IRAS 5-Year).",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.w900),
    );
  }

  Widget _inputBox(String label, TextEditingController ctrl, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 8.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 8),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
          ),
        ),
      ],
    );
  }
}
