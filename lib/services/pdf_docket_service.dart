import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/business_activity.dart';
import 'data_engine_hub.dart';

class PdfDocketService {
  static final PdfDocketService _instance = PdfDocketService._internal();
  factory PdfDocketService() => _instance;
  PdfDocketService._internal();

  /// 1. SERVICE & COMMISSIONING AUDIT DOCKET
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
    String regulatoryBody = 'CIDB & ST / PEC / IEC',
    Uint8List? clientSignatureBytes,
  }) async {
    final pdf = pw.Document();
    final hub = DataEngineHub();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pw.MemoryImage? signatureImage;
    if (clientSignatureBytes != null && clientSignatureBytes.isNotEmpty) {
      signatureImage = pw.MemoryImage(clientSignatureBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hub.companyName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        hub.companyTagline,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey900,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      "COMPLIANCE: $regulatoryBody",
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400, height: 16),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfFieldRow("CLIENT:", clientName),
                          _pdfFieldRow("PROJECT:", projectName),
                          _pdfFieldRow("LOCATION:", siteAddress),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfFieldRow("LEAD TECH:", "$technicianName ($technicianPhone)"),
                          _pdfFieldRow("CLIENT PIC:", "$clientPicName ($clientPicPhone)"),
                          _pdfFieldRow("TIME LOG:", "$checkInTime - $checkOutTime ($shiftDuration)"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Text("EXECUTED COMMISSIONING & TESTING TASKS", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 4),
              ...completedTasks.take(12).map((t) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("✓ ", style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.Expanded(child: pw.Text(t, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black))),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 10),

              pw.Text("VAN FLEET MATERIALS CONSUMED", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                child: materialsUsed.isEmpty
                    ? pw.Text("Diagnostic and preventive servicing only - no van spares consumed.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
                    : pw.Text(materialsUsed.join(" • "), style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              ),
              pw.Spacer(),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("TECHNICIAN VERIFICATION", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                        pw.SizedBox(height: 18),
                        pw.Text("Signature: ______________________", style: const pw.TextStyle(fontSize: 7)),
                        pw.Text("Name: $technicianName", style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("CLIENT SIGN-ON-GLASS ENDORSEMENT", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                        pw.SizedBox(height: 4),
                        signatureImage != null
                            ? pw.Container(
                                width: 110,
                                height: 35,
                                child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                              )
                            : pw.Text("\n[Touch Glass Signed on Device]", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                        pw.Text("PIC: $clientPicName", style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// 2. MULTI-REGION BRANDED PURCHASE ORDER (PO)
  Future<Uint8List> generatePurchaseOrderPdf({
    required PurchaseOrderEntity po,
    required String currencySymbol,
    required String taxLabel,
    required String countryCode,
  }) async {
    final pdf = pw.Document();
    final hub = DataEngineHub();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final countryFlag = countryCode == 'PK' ? "🇵🇰 PAKISTAN" : (countryCode == 'MY' ? "🇲🇾 MALAYSIA" : "🌐 GLOBAL");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hub.companyName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        hub.companyTagline,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        "Operations Hub • Jurisdiction: $countryFlag",
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.amber800,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          "OFFICIAL PURCHASE ORDER",
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("PO REF: ${po.id}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text("DATE: ${po.orderDate.day}/${po.orderDate.month}/${po.orderDate.year}", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400, height: 20),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("VENDOR / SUPPLIER:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.SizedBox(height: 2),
                          pw.Text(po.vendorName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text("Ref Code: ${po.vendorId}", style: const pw.TextStyle(fontSize: 7.5)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("DELIVERY TARGET (VAN / SITE DROP):", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.SizedBox(height: 2),
                          pw.Text(po.targetDestination, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                          pw.Text("Fleet Direct Distribution Model", style: const pw.TextStyle(fontSize: 7.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text("SKU CODE", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 4, child: pw.Text("ITEM DESCRIPTION & WARRANTY", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text("QTY", textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text("UNIT PRICE", textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 2, child: pw.Text("TOTAL", textAlign: pw.TextAlign.right, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
              ),

              ...po.items.map((item) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 2, child: pw.Text(item.sku, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 4, child: pw.Text("${item.description} (${item.warrantyMonths}m MFR Warranty)", style: const pw.TextStyle(fontSize: 8))),
                        pw.Expanded(flex: 1, child: pw.Text("${item.orderedQty} ${item.uom}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Expanded(flex: 2, child: pw.Text("$currencySymbol ${item.unitPrice.toStringAsFixed(2)}", textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                        pw.Expanded(flex: 2, child: pw.Text("$currencySymbol ${item.totalAmount.toStringAsFixed(2)}", textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 12),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    child: pw.Column(
                      children: [
                        _pdfFinancialRow("SUBTOTAL:", "$currencySymbol ${po.subtotal.toStringAsFixed(2)}"),
                        _pdfFinancialRow("TAX ($taxLabel):", "$currencySymbol ${po.taxAmount.toStringAsFixed(2)}"),
                        pw.Divider(color: PdfColors.grey400, height: 8),
                        _pdfFinancialRow("TOTAL PAYABLE:", "$currencySymbol ${po.totalAmount.toStringAsFixed(2)}", isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("FULFILLMENT INSTRUCTIONS:", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        pw.Text("1. Attach DO copy with serial barcodes for warranty registration.", style: const pw.TextStyle(fontSize: 7)),
                        pw.Text("2. Van-side delivery must be acknowledged by authorized technician.", style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("AUTHORIZED PROCUREMENT APPROVAL", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 16),
                        pw.Text("____________________________", style: const pw.TextStyle(fontSize: 7)),
                        pw.Text("Operations Director / Authorized Signatory", style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// 3. OFFICIAL INTER-VAN MATERIAL TRANSFER DOCKET (MTO)
  Future<Uint8List> generateInterVanTransferPdf({
    required VanTransferDocket docket,
  }) async {
    final pdf = pw.Document();
    final hub = DataEngineHub();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hub.companyName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                      ),
                      pw.Text(
                        hub.companyTagline,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        "Internal Fleet Logistics & Direct Vehicle Handover",
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal800,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          "INTER-VAN TRANSFER DOCKET",
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text("DOCKET REF: ${docket.id}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text("DATE: ${docket.transferDate.day}/${docket.transferDate.month}/${docket.transferDate.year} ${docket.transferDate.hour}:${docket.transferDate.minute.toString().padLeft(2, '0')}", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400, height: 18),

              // Source & Destination Boxes
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("SOURCE DISPATCHING VEHICLE:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.SizedBox(height: 3),
                          pw.Text(docket.fromVanPlate, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                          pw.Text("Lead Driver / Tech: ${docket.fromTechName}", style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("RECIPIENT RECEIVING VEHICLE:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                          pw.SizedBox(height: 3),
                          pw.Text(docket.toVanPlate, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          pw.Text("Receiving Tech: ${docket.toTechName}", style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Transferred Items Table Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text("SKU CODE", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 4, child: pw.Text("ITEM DESCRIPTION", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text("QTY", textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 4, child: pw.Text("SERIAL NUMBERS TRANSFERRED", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
              ),

              ...docket.items.map((item) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(flex: 2, child: pw.Text(item.sku, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Expanded(flex: 4, child: pw.Text(item.itemName, style: const pw.TextStyle(fontSize: 8))),
                        pw.Expanded(flex: 1, child: pw.Text("${item.quantity} ${item.uom}", textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            item.serialNumbers.isEmpty ? "[Bulk Consumable / No Serials]" : item.serialNumbers.join("\n"),
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey900),
                          ),
                        ),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 10),

              if (docket.notes.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text("REASON / TRANSFER REMARKS: ${docket.notes}", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                ),
              pw.Spacer(),

              // Dual Handover Verification Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("DISPATCHED BY (SOURCE DRIVER):", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 18),
                        pw.Text("Signature: __________________________", style: const pw.TextStyle(fontSize: 7)),
                        pw.Text("Tech: ${docket.fromTechName} (${docket.fromVanPlate})", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("RECEIVED BY (DESTINATION DRIVER):", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 18),
                        pw.Text("Signature: __________________________", style: const pw.TextStyle(fontSize: 7)),
                        pw.Text("Tech: ${docket.toTechName} (${docket.toVanPlate})", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfFieldRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.Text("$label ", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black))),
        ],
      ),
    );
  }

  pw.Widget _pdfFinancialRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: isBold ? PdfColors.amber900 : PdfColors.black)),
        ],
      ),
    );
  }

  Future<void> previewDocket(BuildContext context, Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: "$title.pdf",
    );
  }
}
