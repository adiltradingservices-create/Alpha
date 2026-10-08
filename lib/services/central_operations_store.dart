import '../models/e_invoice_config.dart';
import '../models/tenant_subscription.dart';
import 'package:flutter/material.dart';
import 'data_engine_hub.dart';

typedef TechnicianEntity = TechnicianRecord;

class CentralOperationsStore extends ChangeNotifier {
  late TenantEInvoiceConfig _eInvoiceConfig = TenantEInvoiceConfig(
    tenantId: 'TENANT-DEFAULT',
    countryCode: 'MY',
  );

  TenantEInvoiceConfig get eInvoiceConfig => _eInvoiceConfig;

  void bindTenantEInvoice(String tenantId, String countryCode) {
    _eInvoiceConfig = TenantEInvoiceConfig(
      tenantId: tenantId,
      countryCode: countryCode,
    );
    notifyListeners();
  }

  // Centralized Global SaaS Client Subscriptions
  final List<TenantSubscription> _clients = [
    TenantSubscription(
      tenantId: 'TENANT-MY-01',
      companyName: 'IDSB Infrastructure Sdn Bhd',
      countryCode: 'MY',
      currency: 'MYR',
      contactEmail: 'ops@idsb.com.my',
      tier: SubscriptionTier.enterpriseCustom,
      validUntil: DateTime(2027, 12, 31),
      enableBiometrics: true,
      enableVanStores: true,
      enableTestingCommissioning: true,
      enableClientEndorsement: true,
      enableCloudSync: true,
    ),
    TenantSubscription(
      tenantId: 'TENANT-PK-02',
      companyName: 'InfraTech Surveillance Ltd',
      countryCode: 'PK',
      currency: 'PKR',
      contactEmail: 'admin@infratech.pk',
      tier: SubscriptionTier.professional,
      validUntil: DateTime(2027, 6, 30),
      enableBiometrics: true,
      enableVanStores: true,
      enableTestingCommissioning: true,
      enableClientEndorsement: true,
      enableCloudSync: false,
    ),
    TenantSubscription(
      tenantId: 'TENANT-SG-03',
      companyName: 'Apex Smart Grid Pte Ltd',
      countryCode: 'SG',
      currency: 'SGD',
      contactEmail: 'corp@apexgrid.sg',
      tier: SubscriptionTier.starter,
      validUntil: DateTime(2026, 11, 15),
      enableBiometrics: false,
      enableVanStores: true,
      enableTestingCommissioning: true,
      enableClientEndorsement: false,
      enableCloudSync: false,
    ),
  ];

  List<TenantSubscription> get clients => List.unmodifiable(_clients);

  void updateTenantSubscription(TenantSubscription updated) {
    final idx = _clients.indexWhere((c) => c.tenantId == updated.tenantId);
    if (idx != -1) {
      _clients[idx] = updated;
      if (companyName == updated.companyName || companyName.isEmpty) {
        updateConfig(
          name: updated.companyName,
          biometrics: updated.enableBiometrics,
          vanStores: updated.enableVanStores,
          testing: updated.enableTestingCommissioning,
          signOff: updated.enableClientEndorsement,
        );
      }
      notifyListeners();
    }
  }

  void provisionTenant(TenantSubscription newTenant) {
    _clients.insert(0, newTenant);
    notifyListeners();
  }

  void updateTenantModules(String tenantId, String moduleId, bool value) {
    final tenant = _clients.firstWhere((c) => c.tenantId == tenantId, orElse: () => _clients.first);
    tenant.toggleModule(moduleId, value);
    if (tenant.companyName == companyName) {
      updateConfig(
        biometrics: tenant.enableBiometrics,
        vanStores: tenant.enableVanStores,
        testing: tenant.enableTestingCommissioning,
        signOff: tenant.enableClientEndorsement,
      );
    }
    notifyListeners();
  }

  static final CentralOperationsStore _instance = CentralOperationsStore._internal();
  factory CentralOperationsStore() => _instance;
  CentralOperationsStore._internal() {
    _hub.addListener(notifyListeners);
  }

  final DataEngineHub _hub = DataEngineHub();

  Future<void> initPersistence() async {
    await _hub.initialize();
  }

  String get companyName => _hub.companyName;
  String get companyTagline => _hub.companyTagline;
  Color get themeAccentColor => _hub.themeAccentColor;

  bool get enableBiometrics => _hub.enableBiometrics;
  bool get enableVanStores => _hub.enableVanStores;
  bool get enableTesting => _hub.enableTesting;
  bool get enableSignOff => _hub.enableSignOff;
  bool get enableWhatsApp => _hub.enableWhatsApp;

  List<TechnicianEntity> get technicians => _hub.technicians;
  Map<String, int> get vanInventoryStock => _hub.vanInventoryStock;

  void addTechnician(TechnicianEntity tech) => _hub.addTechnician(tech);
  void updateTechnicianSite(String techId, String newSite, String newStatus) =>
      _hub.dispatchTechnicianSite(techId, newSite, newStatus);
  void deductVanStock(String item, int quantity) =>
      _hub.consumeVanMaterials([item]);

  void updateConfig({
    String? name,
    String? tagline,
    Color? accent,
    bool? biometrics,
    bool? vanStores,
    bool? testing,
    bool? signOff,
    bool? whatsApp,
  }) {
    _hub.updateTenantConfig(
      name: name,
      tagline: tagline,
      accent: accent,
      biometrics: biometrics,
      vanStores: vanStores,
      testing: testing,
      signOff: signOff,
      whatsApp: whatsApp,
    );
  }
}
