import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/business_activity.dart';

class TechnicianEntity {
  final String id;
  String name;
  String phone;
  String nationalId;
  String licenseCode;
  String vehiclePlate;
  String assignedSite;
  String currentStatus; // 'ON_SITE', 'STANDBY', 'OFFLINE'
  List<BusinessActivityType> disciplines;

  TechnicianEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.licenseCode,
    required this.vehiclePlate,
    required this.assignedSite,
    required this.currentStatus,
    required this.disciplines,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'nationalId': nationalId,
    'licenseCode': licenseCode,
    'vehiclePlate': vehiclePlate,
    'assignedSite': assignedSite,
    'currentStatus': currentStatus,
    'disciplines': disciplines.map((d) => d.name).toList(),
  };

  factory TechnicianEntity.fromMap(Map<String, dynamic> map) => TechnicianEntity(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    nationalId: map['nationalId'] ?? '',
    licenseCode: map['licenseCode'] ?? '',
    vehiclePlate: map['vehiclePlate'] ?? '',
    assignedSite: map['assignedSite'] ?? '',
    currentStatus: map['currentStatus'] ?? 'STANDBY',
    disciplines: (map['disciplines'] as List<dynamic>?)
            ?.map((d) => BusinessActivityType.values.firstWhere(
                  (v) => v.name == d,
                  orElse: () => BusinessActivityType.cctv,
                ))
            .toList() ??
        [BusinessActivityType.cctv],
  );
}

class CentralOperationsStore extends ChangeNotifier {
  static final CentralOperationsStore _instance = CentralOperationsStore._internal();
  factory CentralOperationsStore() => _instance;
  CentralOperationsStore._internal();

  Box? _box;
  bool isInitialized = false;

  // 1. Company Profile & Whitelisting Defaults
  String companyName = 'AlphaTech Networks Sdn Bhd';
  String companyTagline = 'Field Systems & Security Integration';
  Color themeAccentColor = const Color(0xFF10B981);

  bool enableBiometrics = true;
  bool enableVanStores = true;
  bool enableTesting = true;
  bool enableSignOff = true;
  bool enableWhatsApp = true;

  bool whitelistCctv = true;
  bool whitelistElectrical = true;
  bool whitelistLighting = true;
  bool whitelistItSolutions = true;

  // 2. Centralized Technicians List
  final List<TechnicianEntity> _technicians = [];
  List<TechnicianEntity> get technicians => List.unmodifiable(_technicians);

  // 3. Central Van Inventory Pool
  final Map<String, int> vanInventoryStock = {
    '4MP IP Camera (Hikvision)': 14,
    'Cat6 STP Cable Box (305m)': 4,
    'Toolless RJ45 Connectors': 85,
    'PoE Switch 16-Port Gigabit': 3,
    '3-Phase MCB 16A/32A Type C': 22,
    'Earthing Pit Copper Rod 5/8"': 6,
    '150W LED Streetlight Luminaire': 8,
    '7-Pin NEMA Photocell Sensor': 12,
  };

  Future<void> initPersistence() async {
    if (isInitialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox('central_ops_box');

    // Restore Config & Branding
    companyName = _box?.get('companyName', defaultValue: companyName) ?? companyName;
    companyTagline = _box?.get('companyTagline', defaultValue: companyTagline) ?? companyTagline;
    final accentValue = _box?.get('themeAccentColor');
    if (accentValue != null) {
      themeAccentColor = Color(accentValue as int);
    }

    enableBiometrics = _box?.get('enableBiometrics', defaultValue: enableBiometrics) ?? enableBiometrics;
    enableVanStores = _box?.get('enableVanStores', defaultValue: enableVanStores) ?? enableVanStores;
    enableTesting = _box?.get('enableTesting', defaultValue: enableTesting) ?? enableTesting;
    enableSignOff = _box?.get('enableSignOff', defaultValue: enableSignOff) ?? enableSignOff;
    enableWhatsApp = _box?.get('enableWhatsApp', defaultValue: enableWhatsApp) ?? enableWhatsApp;

    // Restore Van Inventory
    final savedInventory = _box?.get('vanInventoryStock');
    if (savedInventory != null) {
      vanInventoryStock.clear();
      final decoded = Map<String, dynamic>.from(jsonDecode(savedInventory));
      decoded.forEach((key, val) => vanInventoryStock[key] = val as int);
    }

    // Restore Technicians
    final savedTechs = _box?.get('technicians');
    if (savedTechs != null) {
      _technicians.clear();
      final list = jsonDecode(savedTechs) as List<dynamic>;
      for (final item in list) {
        _technicians.add(TechnicianEntity.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultData();
      _saveTechnicians();
    }

    isInitialized = true;
    notifyListeners();
  }

  void _seedDefaultData() {
    _technicians.addAll([
      TechnicianEntity(
        id: 'TECH-101',
        name: 'Ahmad Faizal Bin Razali',
        phone: '+60 12-345 6789',
        nationalId: '880412-10-5421',
        licenseCode: 'ST(PR)SEL-PW4-8891',
        vehiclePlate: 'WVG 8812 (Toyota HiAce)',
        assignedSite: 'Menara AlphaTech • Server Room B2',
        currentStatus: 'ON_SITE',
        disciplines: [BusinessActivityType.cctv, BusinessActivityType.electrical],
      ),
      TechnicianEntity(
        id: 'TECH-102',
        name: 'Karthik A/L Subramaniam',
        phone: '+60 17-654 3210',
        nationalId: '920815-14-6633',
        licenseCode: 'CIDB-GREEN-99212',
        vehiclePlate: 'BNE 4401 (Nissan NV200)',
        assignedSite: 'Persiaran Kayangan Pillar 12',
        currentStatus: 'ON_SITE',
        disciplines: [BusinessActivityType.streetLighting, BusinessActivityType.electrical],
      ),
      TechnicianEntity(
        id: 'TECH-103',
        name: 'Mohd Hafiz Bin Danial',
        phone: '+60 19-887 7665',
        nationalId: '951102-10-5119',
        licenseCode: 'FOA-CFOT-FIBER-81',
        vehiclePlate: 'VDC 1190 (Toyota HiAce)',
        assignedSite: 'Subang Central Depot',
        currentStatus: 'STANDBY',
        disciplines: [BusinessActivityType.itSolutions, BusinessActivityType.cctv],
      ),
    ]);
  }

  void _saveTechnicians() {
    final raw = jsonEncode(_technicians.map((t) => t.toMap()).toList());
    _box?.put('technicians', raw);
  }

  void _saveInventory() {
    _box?.put('vanInventoryStock', jsonEncode(vanInventoryStock));
  }

  // Operations Mutations
  void addTechnician(TechnicianEntity tech) {
    _technicians.insert(0, tech);
    _saveTechnicians();
    notifyListeners();
  }

  void updateTechnicianSite(String techId, String newSite, String newStatus) {
    final idx = _technicians.indexWhere((t) => t.id == techId);
    if (idx != -1) {
      _technicians[idx].assignedSite = newSite;
      _technicians[idx].currentStatus = newStatus;
      _saveTechnicians();
      notifyListeners();
    }
  }

  void deductVanStock(String item, int quantity) {
    if (vanInventoryStock.containsKey(item) && (vanInventoryStock[item] ?? 0) >= quantity) {
      vanInventoryStock[item] = (vanInventoryStock[item] ?? 0) - quantity;
      _saveInventory();
      notifyListeners();
    }
  }

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
    if (name != null) {
      companyName = name;
      _box?.put('companyName', name);
    }
    if (tagline != null) {
      companyTagline = tagline;
      _box?.put('companyTagline', tagline);
    }
    if (accent != null) {
      themeAccentColor = accent;
      _box?.put('themeAccentColor', accent.toARGB32());
    }
    if (biometrics != null) {
      enableBiometrics = biometrics;
      _box?.put('enableBiometrics', biometrics);
    }
    if (vanStores != null) {
      enableVanStores = vanStores;
      _box?.put('enableVanStores', vanStores);
    }
    if (testing != null) {
      enableTesting = testing;
      _box?.put('enableTesting', testing);
    }
    if (signOff != null) {
      enableSignOff = signOff;
      _box?.put('enableSignOff', signOff);
    }
    if (whatsApp != null) {
      enableWhatsApp = whatsApp;
      _box?.put('enableWhatsApp', whatsApp);
    }
    notifyListeners();
  }
}
