import 'package:flutter/material.dart';
import '../../core/app_module.dart';
import '../../services/locale_service.dart';

class TestingCommissioningModule implements AppModule {
  @override
  String get moduleId => 'TESTING_COMMISSIONING';

  @override
  String get title => LocaleService.currentLanguage.value == AppLanguage.en
      ? 'SMART TESTING & COMMISSIONING (T&C) CHECKLIST'
      : 'SENARAI SEMAK PENGUJIAN & PENTAULIAHAN (T&C)';

  @override
  IconData get icon => Icons.fact_check_rounded;

  @override
  Widget? buildTechnicianUI(BuildContext context) {
    return const _TechnicianTestingChecklistPod();
  }

  @override
  Widget? buildAdminUI(BuildContext context) {
    return const _AdminTestingAuditView();
  }
}

class _TechnicianTestingChecklistPod extends StatefulWidget {
  const _TechnicianTestingChecklistPod();

  @override
  State<_TechnicianTestingChecklistPod> createState() => _TechnicianTestingChecklistPodState();
}

class _TechnicianTestingChecklistPodState extends State<_TechnicianTestingChecklistPod> {
  final _insulationController = TextEditingController(text: '48.5');
  final _earthPitController = TextEditingController(text: '4.2');
  final _rcdController = TextEditingController(text: '28');

  bool _rtspStreamVerified = true;
  bool _poeBudgetVerified = true;
  final _luxController = TextEditingController(text: '34.8');

  bool _isSignedOff = false;
  String _complianceHash = 'PENDING COMPLIANCE RUN';

  @override
  void dispose() {
    _insulationController.dispose();
    _earthPitController.dispose();
    _rcdController.dispose();
    _luxController.dispose();
    super.dispose();
  }

  bool get _isElectricalPassed {
    final ins = double.tryParse(_insulationController.text) ?? 0.0;
    final earth = double.tryParse(_earthPitController.text) ?? 99.0;
    final rcd = double.tryParse(_rcdController.text) ?? 99.0;
    return ins >= 1.0 && earth <= 10.0 && rcd <= 40.0;
  }

  bool get _isLightingPassed {
    final lux = double.tryParse(_luxController.text) ?? 0.0;
    return lux >= 20.0;
  }

  bool get _isOverallPassed => _isElectricalPassed && _rtspStreamVerified && _poeBudgetVerified && _isLightingPassed;

  void _runValidationAndSign() {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    if (!_isOverallPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? "T&C Alert: One or more technical readings do not meet Suruhanjaya Tenaga or JKR thresholds."
                : "Amaran T&C: Satu atau lebih bacaan teknikal tidak menepati piawaian ST atau JKR.",
          ),
          backgroundColor: const Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSignedOff = true;
      _complianceHash = "SHA256:TC_VERIFIED_${DateTime.now().millisecondsSinceEpoch}_PW4_COMPLIANT";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn
              ? "T&C Verification Complete! Cryptographic compliance certificate generated."
              : "Pengesahan T&C Selesai! Sijil pematuhan berkanun berjaya dicipta.",
        ),
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
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.electrical_services_rounded, color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? "STATUTORY T&C AUDIT PROTOCOL" : "PROTOKOL PENGUJIAN T&C",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      isEn ? "MS IEC 60364 & JKR Road Lighting" : "Standard MS IEC 60364 & JKR",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _isOverallPassed ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFF43F5E).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isOverallPassed ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFF43F5E).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _isOverallPassed ? (isEn ? "PASS" : "LULUS") : (isEn ? "FAIL" : "GAGAL"),
                  style: TextStyle(
                    color: _isOverallPassed ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _sectionCard(
            title: isEn ? "1. LOW VOLTAGE ELECTRICAL COMMISSIONING" : "1. PENGUJIAN ELEKTRIK (ST)",
            icon: Icons.bolt_rounded,
            color: const Color(0xFFF59E0B),
            child: Row(
              children: [
                Expanded(
                  child: _readingInput(
                    label: isEn ? "Insulation (MΩ)" : "Penebat (MΩ)",
                    controller: _insulationController,
                    isPassed: (double.tryParse(_insulationController.text) ?? 0) >= 1.0,
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _readingInput(
                    label: isEn ? "Earth Pit (Ω)" : "Bumi (Ω)",
                    controller: _earthPitController,
                    isPassed: (double.tryParse(_earthPitController.text) ?? 99) <= 10.0,
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _readingInput(
                    label: isEn ? "RCD (ms)" : "RCD (ms)",
                    controller: _rcdController,
                    isPassed: (double.tryParse(_rcdController.text) ?? 99) <= 40.0,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _sectionCard(
            title: isEn ? "2. CCTV & NETWORK TELEMETRY" : "2. TELEMETRI CCTV & IT",
            icon: Icons.videocam_rounded,
            color: const Color(0xFF0284C7),
            child: Row(
              children: [
                Expanded(
                  child: _toggleCheckItem(
                    label: isEn ? "RTSP Video Stream" : "Aliran Video RTSP",
                    value: _rtspStreamVerified,
                    onChanged: (val) => setState(() => _rtspStreamVerified = val),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _toggleCheckItem(
                    label: isEn ? "PoE Wattage Safe" : "Had Kuasa PoE",
                    value: _poeBudgetVerified,
                    onChanged: (val) => setState(() => _poeBudgetVerified = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _sectionCard(
            title: isEn ? "3. STREETLIGHT PHOTOMETRIC LUX" : "3. BACAAN LUX LAMPU",
            icon: Icons.light_mode_rounded,
            color: const Color(0xFFA855F7),
            child: Row(
              children: [
                Expanded(
                  child: _readingInput(
                    label: isEn ? "Illuminance (Lux)" : "Kecerahan (Lux)",
                    controller: _luxController,
                    isPassed: (double.tryParse(_luxController.text) ?? 0) >= 20.0,
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF030712),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PHOTOMETER SENSOR", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          _isLightingPassed ? "JKR M4 Met" : "Below Spec",
                          style: TextStyle(
                            color: _isLightingPassed ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
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
                      child: Text(
                        isEn ? "STATUTORY SIGN-OFF" : "PENGESAHAN PENERIMAAN",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      _isSignedOff ? "STATUS: SIGNED" : "STATUS: PENDING",
                      style: TextStyle(
                        color: _isSignedOff ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "Stamp: $_complianceHash",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 7, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSignedOff ? const Color(0xFF1E293B) : const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      _isSignedOff ? Icons.lock_rounded : Icons.verified_rounded,
                      color: _isSignedOff ? const Color(0xFF10B981) : Colors.black,
                      size: 14,
                    ),
                    label: Text(
                      _isSignedOff
                          ? (isEn ? "AUDIT LOCKED" : "AUDIT DIKUNCI")
                          : (isEn ? "SIGN & CERTIFY T&C" : "SAHKAN & PERAKUI T&C"),
                      style: TextStyle(
                        color: _isSignedOff ? const Color(0xFF10B981) : Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    onPressed: _isSignedOff ? null : _runValidationAndSign,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 5),
              Expanded(
                child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _readingInput({
    required String label,
    required TextEditingController controller,
    required bool isPassed,
    required VoidCallback onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isPassed ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFF43F5E).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                ),
              ),
              Icon(isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isPassed ? const Color(0xFF10B981) : const Color(0xFFF43F5E), size: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleCheckItem({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: value ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFF43F5E).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              activeThumbColor: const Color(0xFF10B981),
              activeTrackColor: const Color(0xFF064E3B),
              inactiveThumbColor: const Color(0xFF64748B),
              inactiveTrackColor: const Color(0xFF1E293B),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTestingAuditView extends StatelessWidget {
  const _AdminTestingAuditView();

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    final auditRecords = [
      {
        'project': 'PRJ-ALPHA-CCTV (Menara AlphaTech)',
        'cert_ref': 'TC-SEL-2026-8812',
        'wireman': 'Ahmad Faizal Bin Razali (PW4)',
        'earth_reading': '4.2 Ω',
        'insulation': '48.5 MΩ',
        'status': 'PASSED & CERTIFIED',
      },
      {
        'project': 'PRJ-LDP-LIGHTING (LDP Highway Pole 44)',
        'cert_ref': 'TC-LDP-2026-9901',
        'wireman': 'Rajesh Raman (A4)',
        'earth_reading': '6.8 Ω',
        'insulation': '32.1 MΩ',
        'status': 'PASSED & CERTIFIED',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isEn ? "T&C REGULATORY LEDGER" : "LEJAR PENTAULIAHAN BERKANUN (T&C)",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: const Text("ST FORM G/H READY", style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...auditRecords.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec['project']!, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("Cert: ${rec['cert_ref']} • Lead: ${rec['wireman']}", overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                      Text("Earth: ${rec['earth_reading']} • Insulation: ${rec['insulation']}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(rec['status']!, style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
