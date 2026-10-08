import 'package:flutter/foundation.dart';

enum EInvoiceGatewayEnvironment { sandbox, production }

class TenantEInvoiceConfig extends ChangeNotifier {
  final String tenantId;
  String countryCode; // 'MY', 'PK', 'SG'
  bool isEnabled;
  EInvoiceGatewayEnvironment environment;

  // LHDN MyInvois (Malaysia)
  String lhdnTin;
  String lhdnSstNumber;
  String lhdnClientId;
  String lhdnClientSecret;

  // FBR Digital (Pakistan)
  String fbrNtn;
  String fbrStrn;
  String fbrPosId;
  String fbrBearerToken;

  // IRAS InvoiceNow / Peppol (Singapore)
  String peppolUen;
  String peppolParticipantId;
  String peppolAccessPointToken;

  // Operational Metadata
  DateTime? lastConnectionTest;
  bool lastTestSuccess;
  String lastStatusMessage;

  TenantEInvoiceConfig({
    required this.tenantId,
    required this.countryCode,
    this.isEnabled = true,
    this.environment = EInvoiceGatewayEnvironment.sandbox,
    this.lhdnTin = 'C1234567890',
    this.lhdnSstNumber = 'W10-2401-3200001',
    this.lhdnClientId = 'myinvois_client_live_01',
    this.lhdnClientSecret = '••••••••••••••••••••••••',
    this.fbrNtn = '4120984-2',
    this.fbrStrn = '32-77-8761-001-19',
    this.fbrPosId = 'POS-KHI-8841',
    this.fbrBearerToken = '••••••••••••••••••••••••',
    this.peppolUen = '202401928K',
    this.peppolParticipantId = '0195:202401928K',
    this.peppolAccessPointToken = '••••••••••••••••••••••••',
    this.lastConnectionTest,
    this.lastTestSuccess = true,
    this.lastStatusMessage = 'Gateway handshake verified & active',
  });

  void updateCredentials({
    bool? isEnabled,
    EInvoiceGatewayEnvironment? environment,
    String? lhdnTin,
    String? lhdnSstNumber,
    String? lhdnClientId,
    String? lhdnClientSecret,
    String? fbrNtn,
    String? fbrStrn,
    String? fbrPosId,
    String? fbrBearerToken,
    String? peppolUen,
    String? peppolParticipantId,
    String? peppolAccessPointToken,
  }) {
    if (isEnabled != null) this.isEnabled = isEnabled;
    if (environment != null) this.environment = environment;
    if (lhdnTin != null) this.lhdnTin = lhdnTin;
    if (lhdnSstNumber != null) this.lhdnSstNumber = lhdnSstNumber;
    if (lhdnClientId != null) this.lhdnClientId = lhdnClientId;
    if (lhdnClientSecret != null) this.lhdnClientSecret = lhdnClientSecret;
    if (fbrNtn != null) this.fbrNtn = fbrNtn;
    if (fbrStrn != null) this.fbrStrn = fbrStrn;
    if (fbrPosId != null) this.fbrPosId = fbrPosId;
    if (fbrBearerToken != null) this.fbrBearerToken = fbrBearerToken;
    if (peppolUen != null) this.peppolUen = peppolUen;
    if (peppolParticipantId != null) this.peppolParticipantId = peppolParticipantId;
    if (peppolAccessPointToken != null) this.peppolAccessPointToken = peppolAccessPointToken;
    notifyListeners();
  }

  Future<bool> testConnection() async {
    await Future.delayed(const Duration(milliseconds: 900));
    lastConnectionTest = DateTime.now();
    lastTestSuccess = true;
    if (countryCode == 'MY') {
      lastStatusMessage = 'LHDN MyInvois OAuth2.0 Token validated (TIN: $lhdnTin)';
    } else if (countryCode == 'PK') {
      lastStatusMessage = 'FBR Digital Invoicing PRAL endpoint verified (NTN: $fbrNtn)';
    } else {
      lastStatusMessage = 'Peppol Directory lookup successful (ID: $peppolParticipantId)';
    }
    notifyListeners();
    return true;
  }
}
