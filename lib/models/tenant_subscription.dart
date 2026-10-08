import 'package:flutter/foundation.dart';

enum SubscriptionTier { starter, professional, enterpriseCustom }
enum TenantStatus { active, gracePeriod, suspended }

class TenantSubscription extends ChangeNotifier {
  final String tenantId;
  String companyName;
  String registrationNumber;
  String contactEmail;
  String contactPhone;
  String countryCode;
  String currency;
  String regulatoryBody;
  String taxEngine;
  double taxRate;

  SubscriptionTier tier;
  TenantStatus status;
  DateTime validUntil;
  int maxTechnicians;
  int maxVans;

  // Granular Module Feature Flags
  bool enableBiometrics;
  bool enableVanStores;
  bool enableTestingCommissioning;
  bool enableClientEndorsement;
  bool enableCloudSync;

  TenantSubscription({
    required this.tenantId,
    required this.companyName,
    this.registrationNumber = 'ROC-REG-PENDING',
    required this.countryCode,
    required this.currency,
    this.regulatoryBody = 'CIDB & ST',
    this.taxEngine = 'LHDN MyInvois (SST 8%)',
    this.taxRate = 0.08,
    required this.contactEmail,
    this.contactPhone = '+60 12-345 6789',
    this.tier = SubscriptionTier.professional,
    this.status = TenantStatus.active,
    required this.validUntil,
    this.maxTechnicians = 25,
    this.maxVans = 10,
    this.enableBiometrics = true,
    this.enableVanStores = true,
    this.enableTestingCommissioning = true,
    this.enableClientEndorsement = true,
    this.enableCloudSync = true,
  });

  bool get isSuspended => status == TenantStatus.suspended;

  void updateDetails({
    String? companyName,
    String? registrationNumber,
    String? contactEmail,
    String? contactPhone,
    String? countryCode,
    String? currency,
    String? regulatoryBody,
    String? taxEngine,
    double? taxRate,
    SubscriptionTier? tier,
    TenantStatus? status,
    DateTime? validUntil,
    int? maxTechnicians,
    int? maxVans,
    bool? enableBiometrics,
    bool? enableVanStores,
    bool? enableTestingCommissioning,
    bool? enableClientEndorsement,
    bool? enableCloudSync,
  }) {
    if (companyName != null) this.companyName = companyName;
    if (registrationNumber != null) this.registrationNumber = registrationNumber;
    if (contactEmail != null) this.contactEmail = contactEmail;
    if (contactPhone != null) this.contactPhone = contactPhone;
    if (countryCode != null) this.countryCode = countryCode;
    if (currency != null) this.currency = currency;
    if (regulatoryBody != null) this.regulatoryBody = regulatoryBody;
    if (taxEngine != null) this.taxEngine = taxEngine;
    if (taxRate != null) this.taxRate = taxRate;
    if (tier != null) this.tier = tier;
    if (status != null) this.status = status;
    if (validUntil != null) this.validUntil = validUntil;
    if (maxTechnicians != null) this.maxTechnicians = maxTechnicians;
    if (maxVans != null) this.maxVans = maxVans;
    if (enableBiometrics != null) this.enableBiometrics = enableBiometrics;
    if (enableVanStores != null) this.enableVanStores = enableVanStores;
    if (enableTestingCommissioning != null) this.enableTestingCommissioning = enableTestingCommissioning;
    if (enableClientEndorsement != null) this.enableClientEndorsement = enableClientEndorsement;
    if (enableCloudSync != null) this.enableCloudSync = enableCloudSync;
    notifyListeners();
  }

  void toggleModule(String moduleId, bool value) {
    switch (moduleId) {
      case 'BIOMETRICS_TELEMETRY':
        enableBiometrics = value;
        break;
      case 'VAN_INVENTORY_SYSTEM':
        enableVanStores = value;
        break;
      case 'TESTING_COMMISSIONING':
        enableTestingCommissioning = value;
        break;
      case 'CLIENT_ENDORSEMENT':
        enableClientEndorsement = value;
        break;
      case 'CLOUD_SYNC':
        enableCloudSync = value;
        break;
    }
    notifyListeners();
  }

  bool isModuleActive(String moduleId) {
    if (isSuspended) return false;
    switch (moduleId) {
      case 'BIOMETRICS_TELEMETRY':
        return enableBiometrics;
      case 'VAN_INVENTORY_SYSTEM':
        return enableVanStores;
      case 'TESTING_COMMISSIONING':
        return enableTestingCommissioning;
      case 'CLIENT_ENDORSEMENT':
        return enableClientEndorsement;
      case 'CLOUD_SYNC':
        return enableCloudSync;
      default:
        return false;
    }
  }
}
