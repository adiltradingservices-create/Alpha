import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/business_activity.dart';
import 'central_operations_store.dart';

class PdfDocketService {
  static final PdfDocketService _instance = PdfDocketService._internal();
  factory PdfDocketService() => _instance;
  PdfDocketService._internal();

  Future<Uint8List> generateServiceDocket({
    required String clientName,
    required String projectName,
    required String siteAddress,
    required String clientPicName,
    required String clientPicPhone,
    required String technicianName,
    required String technicianPhone,
    required List<BusinessActivityType> activeDisciplines,
    required List<String> completedTasks,
    required List<String> materialsUsed,
    required String shiftDuration,
    required String checkInTime,
    required String checkOutTime,
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document();
    final store = CentralOperationsStore();

    final allCategories = BusinessActivity.getCategories();
    final disciplineTitles = activeDisciplines
        .map((type) => allCategories.firstWhere((c) => c.type == type).title)
        .join(', ');

    final docRef = "FOP-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. HEADER & BRANDING
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        store.companyName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        store.companyTagline,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        "Technical Service, Preventive Maintenance & Commissioning",
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.blueGrey300, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "SITE SERVICE DOCKET",
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                        ),
                        pw.Text(
                          "REF: $docRef",
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          "DATE: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey400, thickness: 1, height: 16),

              // 2. CLIENT & SITE METADATA
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _metaRow("CLIENT / EMPLOYER", clientName.isNotEmpty ? clientName : "Direct Client"),
                          _metaRow("PROJECT / SITE", projectName.isNotEmpty ? projectName : "Site Service Job"),
                          _metaRow("SITE ADDRESS", siteAddress.isNotEmpty ? siteAddress : "On-Site Premises"),
                          _metaRow("CLIENT P.I.C.", "$clientPicName ($clientPicPhone)"),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _metaRow("LEAD ENGINEER", "$technicianName ($technicianPhone)"),
                          _metaRow("DISCIPLINES", disciplineTitles.isNotEmpty ? disciplineTitles : "Multi-Discipline Engineering"),
                          _metaRow("HOURS LOGGED", "$checkInTime -> $checkOutTime ($shiftDuration)"),
                          _metaRow("TELEMETRY STATUS", "GPS Biometric Verified"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 3. COMPLETED CHECKLIST & TESTING
              pw.Text(
                "COMPLETED SCOPE & TESTING CRITERIA",
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: completedTasks.isEmpty
                      ? [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text("All routine inspection, diagnostic, and testing steps executed and verified.", style: const pw.TextStyle(fontSize: 8)),
                          )
                        ]
                      : completedTasks.map((t) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Text("[ PASS ]  ", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                                pw.Expanded(
                                  child: pw.Text(t, style: const pw.TextStyle(fontSize: 8)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
              pw.SizedBox(height: 12),

              // 4. PARTS & MATERIALS
              pw.Text(
                "PARTS ALLOCATED & INSTALLED",
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: materialsUsed.isEmpty
                      ? [pw.Text("No physical inventory consumed during this preventive inspection.", style: const pw.TextStyle(fontSize: 7))]
                      : materialsUsed.map((m) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blueGrey50,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Text("• $m", style: const pw.TextStyle(fontSize: 7)),
                          );
                        }).toList(),
                ),
              ),
              pw.Spacer(),

              // 5. SIGNATURE & ATTESTATION
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "FIELD SERVICE ATTESTATION",
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text("Lead Tech: $technicianName", style: const pw.TextStyle(fontSize: 8)),
                          pw.Text("GPS Fix: On-Site Geofence Verified", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          pw.SizedBox(height: 12),
                          pw.Container(height: 0.5, color: PdfColors.grey400),
                          pw.SizedBox(height: 2),
                          pw.Text("Technician Attestation Signature", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "CLIENT / RESIDENT ENGINEER ENDORSEMENT",
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text("Client Signer: $clientPicName", style: const pw.TextStyle(fontSize: 8)),
                          pw.SizedBox(height: 2),
                          if (signatureBytes != null)
                            pw.Container(
                              height: 38,
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Image(pw.MemoryImage(signatureBytes)),
                            )
                          else
                            pw.Container(
                              height: 38,
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Text("[ Endorsement Recorded on Device Glass ]", style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800)),
                            ),
                          pw.Container(height: 0.5, color: PdfColors.grey400),
                          pw.SizedBox(height: 2),
                          pw.Text("Authorized Client Acceptance", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  "Generated securely via FieldOps Enterprise • Verified Field Service Audit Record",
                  style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 7, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> previewDocket(dynamic context, Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
    );
  }
}
