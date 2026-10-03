import 'package:flutter/material.dart';
import '../../core/app_module.dart';
import '../../services/locale_service.dart';
import '../../services/offline_sync_service.dart';

class EndorsementModule implements AppModule {
  @override
  String get moduleId => 'CLIENT_ENDORSEMENT';

  @override
  String get title => LocaleService.currentLanguage.value == AppLanguage.en
      ? 'CONSULTANT & CLIENT DIGITAL SIGN-OFF'
      : 'PENGESAHAN DIGITAL JURUTERA & KONSULTAN';

  @override
  IconData get icon => Icons.draw_rounded;

  @override
  Widget? buildTechnicianUI(BuildContext context) {
    return const _TechnicianSignaturePadView();
  }

  @override
  Widget? buildAdminUI(BuildContext context) {
    return const _AdminEndorsementAuditView();
  }
}

class _TechnicianSignaturePadView extends StatefulWidget {
  const _TechnicianSignaturePadView();

  @override
  State<_TechnicianSignaturePadView> createState() => _TechnicianSignaturePadViewState();
}

class _TechnicianSignaturePadViewState extends State<_TechnicianSignaturePadView> {
  final List<Offset?> _points = [];
  bool _isEndorsed = false;

  final TextEditingController _consultantName = TextEditingController(text: 'Ir. Farhan Malik');
  final TextEditingController _consultantId = TextEditingController(text: '850312-10-5541');
  final TextEditingController _firmName = TextEditingController(text: 'Apex Infra Consultants Sdn Bhd');
  String _designation = 'Resident Engineer (R.E.)';

  void _clearSignature() {
    setState(() {
      _points.clear();
      _isEndorsed = false;
    });
  }

  void _lockAndEndorse() {
    if (_points.where((p) => p != null).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write a signature on the pad before locking milestone."),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isEndorsed = true;
    });

    OfflineSyncService().queueAction(
      moduleType: 'CLIENT_ENDORSEMENT',
      payload: {
        'consultant': _consultantName.text,
        'consultantId': _consultantId.text,
        'firm': _firmName.text,
        'designation': _designation,
        'pointsCount': _points.length,
        'status': 'VERIFIED_MILESTONE',
        'gps': '3.0489° N, 101.6212° E (Puchong HQ)',
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Milestone signed and audit-locked successfully!"),
        backgroundColor: Color(0xFF10B981),
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
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.draw_rounded, color: Color(0xFF38BDF8), size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? "MILESTONE CLIENT SIGN-OFF" : "PENGESAHAN TAPAK PROJEK",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      isEn ? "Touch Signature on Glass" : "Tandatangan Jurutera Perunding di Skrin",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _isEndorsed ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _isEndorsed ? (isEn ? "CERTIFIED" : "DISAHKAN") : (isEn ? "AWAITING SIGN" : "MENUNGGU"),
                  style: TextStyle(
                    color: _isEndorsed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _miniField("Consultant / R.E. Name", _consultantName)),
              const SizedBox(width: 6),
              Expanded(child: _miniField("ID (MyKad / CNIC)", _consultantId)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _miniField("Supervising Firm", _firmName)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Role", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF26324D)),
                      ),
                      child: DropdownButton<String>(
                        value: _designation,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF161F30),
                        style: const TextStyle(color: Colors.white, fontSize: 8),
                        items: const [
                          DropdownMenuItem(value: 'Resident Engineer (R.E.)', child: Text("Resident Engr (R.E.)")),
                          DropdownMenuItem(value: 'Clerk of Works (C.O.W.)', child: Text("Clerk of Works")),
                          DropdownMenuItem(value: 'Client Project Director', child: Text("Project Director")),
                        ],
                        onChanged: _isEndorsed ? null : (val) {
                          if (val != null) setState(() => _designation = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // SIGNATURE PAD TOUCH SURFACE
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isEndorsed ? const Color(0xFF10B981) : const Color(0xFF38BDF8).withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: _isEndorsed
                        ? null
                        : (details) {
                            setState(() {
                              _points.add(details.localPosition);
                            });
                          },
                    onPanUpdate: _isEndorsed
                        ? null
                        : (details) {
                            setState(() {
                              _points.add(details.localPosition);
                            });
                          },
                    onPanEnd: _isEndorsed
                        ? null
                        : (details) {
                            setState(() {
                              _points.add(null);
                            });
                          },
                    child: CustomPaint(
                      painter: _DirectSignaturePainter(
                        points: _points,
                        strokeColor: _isEndorsed ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  if (_points.where((p) => p != null).isEmpty)
                    const Center(
                      child: IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, color: Color(0xFF334155), size: 28),
                            SizedBox(height: 4),
                            Text(
                              "Sign with Finger or Stylus Pen Here",
                              style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: [
                        if (!_isEndorsed)
                          InkWell(
                            onTap: _clearSignature,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text("CLEAR", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isEndorsed)
                    Positioned(
                      bottom: 6,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 10),
                            const SizedBox(width: 4),
                            Text(
                              "AUDIT LOCKED: ${_consultantName.text} • ${_firmName.text}",
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEndorsed ? const Color(0xFF1E293B) : const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(
                _isEndorsed ? Icons.lock_rounded : Icons.check_circle_rounded,
                color: _isEndorsed ? const Color(0xFF10B981) : Colors.black,
                size: 14,
              ),
              label: Text(
                _isEndorsed ? "MILESTONE AUDIT LOCKED & QUEUED" : "LOCK & SUBMIT DIGITAL ENDORSEMENT",
                style: TextStyle(
                  color: _isEndorsed ? const Color(0xFF10B981) : Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: _isEndorsed ? null : _lockAndEndorse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 8),
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
}

class _DirectSignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;

  _DirectSignaturePainter({required this.points, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DirectSignaturePainter oldDelegate) => true;
}

class _AdminEndorsementAuditView extends StatelessWidget {
  const _AdminEndorsementAuditView();

  @override
  Widget build(BuildContext context) {
    final audits = [
      {
        'project': 'Menara AlphaTech CCTV Overhaul',
        'milestone': 'Phase 1: 64x 4K Camera Installation & PoE Commissioning',
        'consultant': 'Ir. Farhan Malik (BEM PE-9912)',
        'firm': 'Apex Infra Consultants Sdn Bhd',
        'val': 'RM 28,400.00',
        'date': 'Today, 10:45 AM',
        'flag': '🇲🇾',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 6),
                  Text(
                    "DIGITAL ENDORSEMENT AUDIT TRAIL",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text("LEGAL EVIDENCE", style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.w900)),
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 14),

          ...audits.map((item) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['project'] as String, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      Text(item['val'] as String, style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text("Signatory: ${item['consultant']} • Firm: ${item['firm']}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 7)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
