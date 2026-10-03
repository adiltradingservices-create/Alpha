import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/business_activity.dart';
import '../services/data_engine_hub.dart';
import '../services/pdf_docket_service.dart';
import '../services/whatsapp_dispatcher_service.dart';
import '../widgets/signature_pad_widget.dart';

class MultiActivityWorkspaceScreen extends StatefulWidget {
  final String projectName;
  final String siteLocation;
  final String technicianName;
  final String companyName;
  final String initialClientName;

  const MultiActivityWorkspaceScreen({
    super.key,
    required this.projectName,
    required this.siteLocation,
    required this.technicianName,
    required this.companyName,
    this.initialClientName = 'Direct Client / Site Owner',
  });

  @override
  State<MultiActivityWorkspaceScreen> createState() => _MultiActivityWorkspaceScreenState();
}

class _MultiActivityWorkspaceScreenState extends State<MultiActivityWorkspaceScreen> {
  late TextEditingController _clientCtrl;
  late TextEditingController _projectCtrl;
  late TextEditingController _siteCtrl;
  late TextEditingController _picCtrl;

  late List<BusinessActivity> _allActivities;
  final Set<BusinessActivityType> _selectedActivities = {
    BusinessActivityType.cctv,
    BusinessActivityType.electrical,
  };

  Uint8List? _capturedSignature;

  @override
  void initState() {
    super.initState();
    _clientCtrl = TextEditingController(text: widget.initialClientName);
    _projectCtrl = TextEditingController(text: widget.projectName);
    _siteCtrl = TextEditingController(text: widget.siteLocation);
    _picCtrl = TextEditingController(text: "Site Engineer / In-Charge");
    _allActivities = BusinessActivity.getCategories();
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _projectCtrl.dispose();
    _siteCtrl.dispose();
    _picCtrl.dispose();
    super.dispose();
  }

  void _toggleActivity(BusinessActivityType type) {
    setState(() {
      if (_selectedActivities.contains(type)) {
        if (_selectedActivities.length > 1) {
          _selectedActivities.remove(type);
        }
      } else {
        _selectedActivities.add(type);
      }
    });
  }

  Future<void> _generateAndPreviewPdf() async {
    final activeItems = _allActivities
        .where((a) => _selectedActivities.contains(a.type))
        .expand((a) => a.inspectionItems)
        .where((item) => item.isChecked)
        .map((item) => item.title)
        .toList();

    final parts = _allActivities
        .where((a) => _selectedActivities.contains(a.type))
        .expand((a) => a.defaultMaterials.take(2))
        .toSet()
        .toList();

    if (parts.isNotEmpty) {
      DataEngineHub().consumeVanMaterials(parts);
    }

    final pdfBytes = await PdfDocketService().generateServiceDocket(
      clientName: _clientCtrl.text.trim(),
      projectName: _projectCtrl.text.trim(),
      siteAddress: _siteCtrl.text.trim(),
      clientPicName: _picCtrl.text.trim(),
      clientPicPhone: "+60 1x-xxx xxxx",
      technicianName: widget.technicianName,
      technicianPhone: "+60 12-345 6789",
      activeDisciplines: _selectedActivities.toList(),
      completedTasks: activeItems,
      materialsUsed: parts,
      shiftDuration: "03 hrs 30 mins",
      checkInTime: "09:00 AM",
      checkOutTime: "12:30 PM",
      clientSignatureBytes: _capturedSignature,
    );

    if (!mounted) return;
    await PdfDocketService().previewDocket(
      context,
      pdfBytes,
      "${_projectCtrl.text.trim().replaceAll(' ', '_')}-Service-Docket",
    );
  }

  void _dispatchWhatsAppReport() {
    final activeTitles = _allActivities
        .where((a) => _selectedActivities.contains(a.type))
        .map((a) => a.title)
        .join(' + ');

    final activeItems = _allActivities
        .where((a) => _selectedActivities.contains(a.type))
        .expand((a) => a.inspectionItems)
        .where((item) => item.isChecked)
        .map((item) => "✓ ${item.title}")
        .toList();

    final parts = _allActivities
        .where((a) => _selectedActivities.contains(a.type))
        .expand((a) => a.defaultMaterials.take(2))
        .toSet()
        .toList();

    if (parts.isNotEmpty) {
      DataEngineHub().consumeVanMaterials(parts);
    }

    final partsSummary = parts.isEmpty ? "None" : parts.join(', ');
    final taskSummary = activeItems.isEmpty ? "All Standard Diagnostic Tests Verified" : activeItems.join('\n');

    final message = """
🚨 *OFFICIAL FIELD SERVICE DISPATCH REPORT* 🚨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 *Company:* ${widget.companyName}
👷‍♂️ *Lead Tech:* ${widget.technicianName}
👤 *Client:* ${_clientCtrl.text.trim()}
📍 *Project:* ${_projectCtrl.text.trim()}
📌 *Site Location:* ${_siteCtrl.text.trim()}
🛠️ *Disciplines:* $activeTitles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 *Executed Checklist Items:*
$taskSummary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 *Materials Allocated:* $partsSummary
🔒 *Sign-on-Glass:* Verified
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_Generated via FieldOps Enterprise_
""";

    WhatsAppDispatcherService().sendSiteReport(
      context: context,
      recipientPhone: "+60123456789",
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeActivitiesList = _allActivities
        .where((a) => _selectedActivities.contains(a.type))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SERVICE & COMMISSIONING WORKSPACE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            Text("Multi-Discipline Site Execution & Docket", style: TextStyle(color: Color(0xFF64748B), fontSize: 7)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8), size: 20),
            onPressed: _generateAndPreviewPdf,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("SITE JOB & CLIENT IDENTIFIERS", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.w900)),
                    Text("EDITABLE FOR PDF", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _editableField("CUSTOMER / CLIENT", _clientCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _editableField("PROJECT / TICKET", _projectCtrl)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _editableField("SITE ADDRESS / ROOM", _siteCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _editableField("CLIENT SIGNER (PIC)", _picCtrl)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text("SELECT WORK DISCIPLINES INVOLVED", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allActivities.map((act) {
              final isSelected = _selectedActivities.contains(act.type);
              return FilterChip(
                label: Text(act.title),
                avatar: Icon(act.icon, size: 14, color: isSelected ? Colors.black : act.accentColor),
                selected: isSelected,
                selectedColor: act.accentColor,
                backgroundColor: const Color(0xFF0F172A),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isSelected ? act.accentColor : const Color(0xFF1E293B)),
                ),
                onSelected: (_) => _toggleActivity(act.type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          ...activeActivitiesList.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: const Color(0xFF080F1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: activity.accentColor.withValues(alpha: 0.4)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: activity.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(activity.icon, color: activity.accentColor, size: 16),
                    ),
                    title: Text(activity.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                    subtitle: Text("${activity.code} • ${activity.inspectionItems.length} Checklist Items", style: const TextStyle(color: Color(0xFF64748B), fontSize: 8)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Color(0xFF1E293B)),
                            Text("INSPECTION & TESTING CHECKLIST", style: TextStyle(color: activity.accentColor, fontSize: 7, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ...activity.inspectionItems.map((item) {
                              return CheckboxListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: EdgeInsets.zero,
                                activeColor: activity.accentColor,
                                checkColor: Colors.black,
                                title: Text(item.title, style: TextStyle(color: item.isChecked ? Colors.white : const Color(0xFF94A3B8), fontSize: 9)),
                                value: item.isChecked,
                                onChanged: (val) {
                                  setState(() => item.isChecked = val ?? false);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),

          // SIGN-ON-GLASS CANVAS
          SignaturePadWidget(
            onSignatureCaptured: (bytes) {
              _capturedSignature = bytes;
            },
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.black, size: 16),
                    label: const Text(
                      "WHATSAPP DOCKET",
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    onPressed: _dispatchWhatsAppReport,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.black, size: 16),
                    label: const Text(
                      "GENERATE A4 PDF",
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    onPressed: _generateAndPreviewPdf,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _editableField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161F30),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            ),
          ),
        ),
      ],
    );
  }
}
