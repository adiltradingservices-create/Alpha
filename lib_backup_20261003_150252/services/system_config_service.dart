import 'package:flutter/material.dart';

class SystemConfigService extends ChangeNotifier {
  static final SystemConfigService _instance = SystemConfigService._internal();
  factory SystemConfigService() => _instance;
  SystemConfigService._internal();

  // White-label branding
  String companyName = 'AlphaTech Networks Sdn Bhd';
  String companyTagline = 'Field Engineering & Systems Integration';
  Color primaryAccentColor = const Color(0xFF10B981); // Emerald default

  // Module Whitelisting (Technician UI controls)
  bool enableBiometrics = true;
  bool enableVanStores = true;
  bool enableTestingCommissioning = true;
  bool enableClientSignOff = true;
  bool enableWhatsAppDispatch = true;

  // Engineering Discipline Whitelisting
  bool whitelistCctv = true;
  bool whitelistElectrical = true;
  bool whitelistStreetLighting = true;
  bool whitelistItSolutions = true;

  // Security & Hardware Enforcement
  bool enforceCameraCapture = true;
  bool enforceGpsGeofence = true;
  bool allowOfflineQueue = true;

  void updateBranding({
    required String name,
    required String tagline,
    required Color accent,
  }) {
    companyName = name;
    companyTagline = tagline;
    primaryAccentColor = accent;
    notifyListeners();
  }

  void toggleModule(String moduleKey, bool value) {
    switch (moduleKey) {
      case 'BIOMETRICS':
        enableBiometrics = value;
        break;
      case 'VAN_STORES':
        enableVanStores = value;
        break;
      case 'TESTING':
        enableTestingCommissioning = value;
        break;
      case 'SIGN_OFF':
        enableClientSignOff = value;
        break;
      case 'WHATSAPP':
        enableWhatsAppDispatch = value;
        break;
    }
    notifyListeners();
  }

  void toggleDiscipline(String disciplineKey, bool value) {
    switch (disciplineKey) {
      case 'CCTV':
        whitelistCctv = value;
        break;
      case 'ELECTRICAL':
        whitelistElectrical = value;
        break;
      case 'LIGHTING':
        whitelistStreetLighting = value;
        break;
      case 'IT_NETWORKS':
        whitelistItSolutions = value;
        break;
    }
    notifyListeners();
  }

  void toggleSecurityRule(String ruleKey, bool value) {
    switch (ruleKey) {
      case 'CAMERA':
        enforceCameraCapture = value;
        break;
      case 'GPS':
        enforceGpsGeofence = value;
        break;
      case 'OFFLINE':
        allowOfflineQueue = value;
        break;
    }
    notifyListeners();
  }
}
