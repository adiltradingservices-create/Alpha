import 'package:flutter/material.dart';
import 'data_engine_hub.dart';

typedef TechnicianEntity = TechnicianRecord;

class CentralOperationsStore extends ChangeNotifier {
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
