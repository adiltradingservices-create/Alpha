import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/business_activity.dart';

enum SyncEventType {
  technicianUpdated,
  technicianDispatched,
  inventoryAdjusted,
  configUpdated,
  docketSubmitted,
  vendorUpdated,
  poUpdated,
  warrantyRegistered,
  vanTransferLogged,
}

class SyncEvent {
  final SyncEventType type;
  final String tenantId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.tenantId,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TransferLineItem {
  final String sku;
  final String itemName;
  final int quantity;
  final String uom;
  final List<String> serialNumbers;

  TransferLineItem({
    required this.sku,
    required this.itemName,
    required this.quantity,
    required this.uom,
    this.serialNumbers = const [],
  });

  Map<String, dynamic> toMap() => {
    'sku': sku,
    'itemName': itemName,
    'quantity': quantity,
    'uom': uom,
    'serialNumbers': serialNumbers,
  };

  factory TransferLineItem.fromMap(Map<String, dynamic> map) => TransferLineItem(
    sku: map['sku'] ?? '',
    itemName: map['itemName'] ?? '',
    quantity: map['quantity'] ?? 1,
    uom: map['uom'] ?? 'Units',
    serialNumbers: (map['serialNumbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}

class VanTransferDocket {
  final String id;
  final String tenantId;
  final String fromVanPlate;
  final String fromTechName;
  final String toVanPlate;
  final String toTechName;
  final DateTime transferDate;
  final List<TransferLineItem> items;
  final String notes;

  VanTransferDocket({
    required this.id,
    required this.tenantId,
    required this.fromVanPlate,
    required this.fromTechName,
    required this.toVanPlate,
    required this.toTechName,
    required this.transferDate,
    required this.items,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tenantId': tenantId,
    'fromVanPlate': fromVanPlate,
    'fromTechName': fromTechName,
    'toVanPlate': toVanPlate,
    'toTechName': toTechName,
    'transferDate': transferDate.toIso8601String(),
    'items': items.map((i) => i.toMap()).toList(),
    'notes': notes,
  };

  factory VanTransferDocket.fromMap(Map<String, dynamic> map) => VanTransferDocket(
    id: map['id'] ?? '',
    tenantId: map['tenantId'] ?? 'DEFAULT',
    fromVanPlate: map['fromVanPlate'] ?? '',
    fromTechName: map['fromTechName'] ?? '',
    toVanPlate: map['toVanPlate'] ?? '',
    toTechName: map['toTechName'] ?? '',
    transferDate: DateTime.tryParse(map['transferDate'] ?? '') ?? DateTime.now(),
    items: (map['items'] as List<dynamic>?)
            ?.map((i) => TransferLineItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [],
    notes: map['notes'] ?? '',
  );
}

class AssetWarrantyRecord {
  final String id;
  final String tenantId;
  final String serialNumber;
  final String sku;
  final String itemName;
  final String poId;
  final String vendorName;
  String assignedVanPlate;
  final DateTime warrantyStartDate;
  final DateTime warrantyEndDate;
  String warrantyStatus; // 'ACTIVE', 'EXPIRED', 'CLAIMED_RMA'
  String? installedSite;
  String? installedClient;

  AssetWarrantyRecord({
    required this.id,
    required this.tenantId,
    required this.serialNumber,
    required this.sku,
    required this.itemName,
    required this.poId,
    required this.vendorName,
    required this.assignedVanPlate,
    required this.warrantyStartDate,
    required this.warrantyEndDate,
    this.warrantyStatus = 'ACTIVE',
    this.installedSite,
    this.installedClient,
  });

  bool get isExpired => DateTime.now().isAfter(warrantyEndDate);
  int get daysRemaining => warrantyEndDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() => {
    'id': id,
    'tenantId': tenantId,
    'serialNumber': serialNumber,
    'sku': sku,
    'itemName': itemName,
    'poId': poId,
    'vendorName': vendorName,
    'assignedVanPlate': assignedVanPlate,
    'warrantyStartDate': warrantyStartDate.toIso8601String(),
    'warrantyEndDate': warrantyEndDate.toIso8601String(),
    'warrantyStatus': isExpired ? 'EXPIRED' : warrantyStatus,
    'installedSite': installedSite,
    'installedClient': installedClient,
  };

  factory AssetWarrantyRecord.fromMap(Map<String, dynamic> map) {
    final end = DateTime.tryParse(map['warrantyEndDate'] ?? '') ?? DateTime.now().add(const Duration(days: 365));
    final isExp = DateTime.now().isAfter(end);
    return AssetWarrantyRecord(
      id: map['id'] ?? '',
      tenantId: map['tenantId'] ?? 'DEFAULT',
      serialNumber: map['serialNumber'] ?? '',
      sku: map['sku'] ?? '',
      itemName: map['itemName'] ?? '',
      poId: map['poId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      assignedVanPlate: map['assignedVanPlate'] ?? 'FLEET_ALL',
      warrantyStartDate: DateTime.tryParse(map['warrantyStartDate'] ?? '') ?? DateTime.now(),
      warrantyEndDate: end,
      warrantyStatus: isExp ? 'EXPIRED' : (map['warrantyStatus'] ?? 'ACTIVE'),
      installedSite: map['installedSite'],
      installedClient: map['installedClient'],
    );
  }
}

class VendorEntity {
  final String id;
  final String tenantId;
  String companyName;
  String contactPerson;
  String phone;
  String email;
  String taxRegNumber;
  BusinessActivityType discipline;
  String paymentTerms;
  String bankDetails;
  bool isActive;

  VendorEntity({
    required this.id,
    required this.tenantId,
    required this.companyName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.taxRegNumber,
    required this.discipline,
    required this.paymentTerms,
    required this.bankDetails,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'tenantId': tenantId,
    'companyName': companyName,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'taxRegNumber': taxRegNumber,
    'discipline': discipline.name,
    'paymentTerms': paymentTerms,
    'bankDetails': bankDetails,
    'isActive': isActive,
  };

  factory VendorEntity.fromMap(Map<String, dynamic> map) => VendorEntity(
    id: map['id'] ?? '',
    tenantId: map['tenantId'] ?? 'DEFAULT',
    companyName: map['companyName'] ?? '',
    contactPerson: map['contactPerson'] ?? '',
    phone: map['phone'] ?? '',
    email: map['email'] ?? '',
    taxRegNumber: map['taxRegNumber'] ?? '',
    discipline: BusinessActivityType.values.firstWhere(
      (v) => v.name == map['discipline'],
      orElse: () => BusinessActivityType.cctv,
    ),
    paymentTerms: map['paymentTerms'] ?? 'NET_30',
    bankDetails: map['bankDetails'] ?? '',
    isActive: map['isActive'] ?? true,
  );
}

class POLineItem {
  final String sku;
  final String description;
  final BusinessActivityType category;
  final int orderedQty;
  int receivedQty;
  final double unitPrice;
  final String uom;
  final int warrantyMonths;

  POLineItem({
    required this.sku,
    required this.description,
    required this.category,
    required this.orderedQty,
    this.receivedQty = 0,
    required this.unitPrice,
    required this.uom,
    this.warrantyMonths = 36,
  });

  bool get isFulfilled => receivedQty >= orderedQty;
  double get totalAmount => orderedQty * unitPrice;

  Map<String, dynamic> toMap() => {
    'sku': sku,
    'description': description,
    'category': category.name,
    'orderedQty': orderedQty,
    'receivedQty': receivedQty,
    'unitPrice': unitPrice,
    'uom': uom,
    'warrantyMonths': warrantyMonths,
  };

  factory POLineItem.fromMap(Map<String, dynamic> map) => POLineItem(
    sku: map['sku'] ?? '',
    description: map['description'] ?? '',
    category: BusinessActivityType.values.firstWhere(
      (v) => v.name == map['category'],
      orElse: () => BusinessActivityType.cctv,
    ),
    orderedQty: map['orderedQty'] ?? 1,
    receivedQty: map['receivedQty'] ?? 0,
    unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    uom: map['uom'] ?? 'Units',
    warrantyMonths: map['warrantyMonths'] ?? 36,
  );
}

class PurchaseOrderEntity {
  final String id;
  final String tenantId;
  final String vendorId;
  final String vendorName;
  final DateTime orderDate;
  String targetDestination;
  List<POLineItem> items;
  String status;
  String paymentStatus;
  double amountPaid;
  String paymentReference;
  double taxRate;

  PurchaseOrderEntity({
    required this.id,
    required this.tenantId,
    required this.vendorId,
    required this.vendorName,
    required this.orderDate,
    required this.targetDestination,
    required this.items,
    this.status = 'ISSUED',
    this.paymentStatus = 'UNPAID',
    this.amountPaid = 0.0,
    this.paymentReference = '',
    this.taxRate = 0.08,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalAmount);
  double get taxAmount => subtotal * taxRate;
  double get totalAmount => subtotal + taxAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'tenantId': tenantId,
    'vendorId': vendorId,
    'vendorName': vendorName,
    'orderDate': orderDate.toIso8601String(),
    'targetDestination': targetDestination,
    'items': items.map((i) => i.toMap()).toList(),
    'status': status,
    'paymentStatus': paymentStatus,
    'amountPaid': amountPaid,
    'paymentReference': paymentReference,
    'taxRate': taxRate,
  };

  factory PurchaseOrderEntity.fromMap(Map<String, dynamic> map) => PurchaseOrderEntity(
    id: map['id'] ?? '',
    tenantId: map['tenantId'] ?? 'DEFAULT',
    vendorId: map['vendorId'] ?? '',
    vendorName: map['vendorName'] ?? '',
    orderDate: DateTime.tryParse(map['orderDate'] ?? '') ?? DateTime.now(),
    targetDestination: map['targetDestination'] ?? 'FLEET_ALL',
    items: (map['items'] as List<dynamic>?)
            ?.map((i) => POLineItem.fromMap(Map<String, dynamic>.from(i)))
            .toList() ??
        [],
    status: map['status'] ?? 'ISSUED',
    paymentStatus: map['paymentStatus'] ?? 'UNPAID',
    amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
    paymentReference: map['paymentReference'] ?? '',
    taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.08,
  );
}

class VanStockItem {
  final String id;
  String sku;
  String name;
  BusinessActivityType category;
  String productType;
  String warrantyType;
  String uom;
  int quantity;
  int minThreshold;
  String assignedVanPlate;

  VanStockItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.productType,
    required this.warrantyType,
    required this.uom,
    required this.quantity,
    this.minThreshold = 5,
    this.assignedVanPlate = 'FLEET_ALL',
  });

  bool get isLowStock => quantity <= minThreshold && quantity > 0;
  bool get isDepleted => quantity <= 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'name': name,
    'category': category.name,
    'productType': productType,
    'warrantyType': warrantyType,
    'uom': uom,
    'quantity': quantity,
    'minThreshold': minThreshold,
    'assignedVanPlate': assignedVanPlate,
  };

  factory VanStockItem.fromMap(Map<String, dynamic> map) => VanStockItem(
    id: map['id'] ?? '',
    sku: map['sku'] ?? 'SKU-GEN',
    name: map['name'] ?? '',
    category: BusinessActivityType.values.firstWhere(
      (v) => v.name == map['category'],
      orElse: () => BusinessActivityType.cctv,
    ),
    productType: map['productType'] ?? 'SPARE_PART',
    warrantyType: map['warrantyType'] ?? '1_YEAR_ONSITE',
    uom: map['uom'] ?? 'Units',
    quantity: map['quantity'] ?? 0,
    minThreshold: map['minThreshold'] ?? 5,
    assignedVanPlate: map['assignedVanPlate'] ?? 'FLEET_ALL',
  );
}

class TechnicianRecord {
  final String id;
  final String tenantId;
  String name;
  String phone;
  String nationalId;
  String licenseCode;
  String vehiclePlate;
  String assignedSite;
  String currentStatus;
  List<BusinessActivityType> disciplines;

  TechnicianRecord({
    required this.id,
    required this.tenantId,
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
    'tenantId': tenantId,
    'name': name,
    'phone': phone,
    'nationalId': nationalId,
    'licenseCode': licenseCode,
    'vehiclePlate': vehiclePlate,
    'assignedSite': assignedSite,
    'currentStatus': currentStatus,
    'disciplines': disciplines.map((d) => d.name).toList(),
  };

  factory TechnicianRecord.fromMap(Map<String, dynamic> map) => TechnicianRecord(
    id: map['id'] ?? '',
    tenantId: map['tenantId'] ?? 'DEFAULT',
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

class DataEngineHub extends ChangeNotifier {
  static final DataEngineHub _instance = DataEngineHub._internal();
  factory DataEngineHub() => _instance;
  DataEngineHub._internal();

  Box? _box;
  bool isInitialized = false;

  final StreamController<SyncEvent> _eventStream = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get eventStream => _eventStream.stream;

  String _activeTenantId = 'TENANT-MY-001';
  String get activeTenantId => _activeTenantId;

  void setActiveTenant(String tenantId) {
    if (_activeTenantId != tenantId) {
      _activeTenantId = tenantId;
      _loadTenantScopedData(tenantId);
      notifyListeners();
    }
  }

  String companyName = 'AlphaTech Networks Sdn Bhd';
  String companyTagline = 'Field Systems & Security Integration';
  Color themeAccentColor = const Color(0xFF10B981);

  bool enableBiometrics = true;
  bool enableVanStores = true;
  bool enableTesting = true;
  bool enableSignOff = true;
  bool enableWhatsApp = true;

  final List<TechnicianRecord> _technicians = [];
  List<TechnicianRecord> get technicians => List.unmodifiable(_technicians);

  final List<VanStockItem> _vanStockItems = [];
  List<VanStockItem> get vanStockItems => List.unmodifiable(_vanStockItems);

  final List<VendorEntity> _vendors = [];
  List<VendorEntity> get vendors => List.unmodifiable(_vendors);

  final List<PurchaseOrderEntity> _purchaseOrders = [];
  List<PurchaseOrderEntity> get purchaseOrders => List.unmodifiable(_purchaseOrders);

  final List<AssetWarrantyRecord> _warrantyAssets = [];
  List<AssetWarrantyRecord> get warrantyAssets => List.unmodifiable(_warrantyAssets);

  final List<VanTransferDocket> _transferDockets = [];
  List<VanTransferDocket> get transferDockets => List.unmodifiable(_transferDockets);

  Map<String, int> get vanInventoryStock {
    final map = <String, int>{};
    for (final item in _vanStockItems) {
      map[item.name] = item.quantity;
    }
    return map;
  }

  Future<void> initialize() async {
    if (isInitialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox('data_engine_hub_box');

    _loadTenantScopedData(_activeTenantId);
    isInitialized = true;
    notifyListeners();
  }

  void _loadTenantScopedData(String tenantId) {
    companyName = _box?.get('${tenantId}_companyName', defaultValue: 'AlphaTech Networks Sdn Bhd') ?? 'AlphaTech Networks Sdn Bhd';
    companyTagline = _box?.get('${tenantId}_companyTagline', defaultValue: 'Field Systems & Security Integration') ?? 'Field Systems & Security Integration';
    final accentVal = _box?.get('${tenantId}_themeAccentColor');
    themeAccentColor = accentVal != null ? Color(accentVal as int) : const Color(0xFF10B981);

    enableBiometrics = _box?.get('${tenantId}_enableBiometrics', defaultValue: true) ?? true;
    enableVanStores = _box?.get('${tenantId}_enableVanStores', defaultValue: true) ?? true;
    enableTesting = _box?.get('${tenantId}_enableTesting', defaultValue: true) ?? true;
    enableSignOff = _box?.get('${tenantId}_enableSignOff', defaultValue: true) ?? true;
    enableWhatsApp = _box?.get('${tenantId}_enableWhatsApp', defaultValue: true) ?? true;

    bool needsPersistTech = false;
    bool needsPersistStock = false;
    bool needsPersistVendors = false;
    bool needsPersistPOs = false;
    bool needsPersistAssets = false;
    bool needsPersistTransfers = false;

    // 1. Technicians
    _technicians.clear();
    final savedTechs = _box?.get('${tenantId}_technicians');
    if (savedTechs != null) {
      final list = jsonDecode(savedTechs) as List<dynamic>;
      for (final item in list) {
        _technicians.add(TechnicianRecord.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultTenantTechs(tenantId);
      needsPersistTech = true;
    }

    // 2. Van Items
    _vanStockItems.clear();
    final savedItems = _box?.get('${tenantId}_vanStockItems');
    if (savedItems != null) {
      final list = jsonDecode(savedItems) as List<dynamic>;
      for (final item in list) {
        _vanStockItems.add(VanStockItem.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultVanItems();
      needsPersistStock = true;
    }

    // 3. Vendors
    _vendors.clear();
    final savedVendors = _box?.get('${tenantId}_vendors');
    if (savedVendors != null) {
      final list = jsonDecode(savedVendors) as List<dynamic>;
      for (final item in list) {
        _vendors.add(VendorEntity.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultVendors(tenantId);
      needsPersistVendors = true;
    }

    // 4. Purchase Orders
    _purchaseOrders.clear();
    final savedPOs = _box?.get('${tenantId}_purchaseOrders');
    if (savedPOs != null) {
      final list = jsonDecode(savedPOs) as List<dynamic>;
      for (final item in list) {
        _purchaseOrders.add(PurchaseOrderEntity.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultPurchaseOrders(tenantId);
      needsPersistPOs = true;
    }

    // 5. Warranty Serialized Assets
    _warrantyAssets.clear();
    final savedAssets = _box?.get('${tenantId}_warrantyAssets');
    if (savedAssets != null) {
      final list = jsonDecode(savedAssets) as List<dynamic>;
      for (final item in list) {
        _warrantyAssets.add(AssetWarrantyRecord.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultWarrantyAssets(tenantId);
      needsPersistAssets = true;
    }

    // 6. Van Transfer Dockets
    _transferDockets.clear();
    final savedTransfers = _box?.get('${tenantId}_transferDockets');
    if (savedTransfers != null) {
      final list = jsonDecode(savedTransfers) as List<dynamic>;
      for (final item in list) {
        _transferDockets.add(VanTransferDocket.fromMap(Map<String, dynamic>.from(item)));
      }
    } else {
      _seedDefaultTransferDockets(tenantId);
      needsPersistTransfers = true;
    }

    Future.microtask(() {
      if (needsPersistTech) _persistTechnicians();
      if (needsPersistStock) _persistVanStock();
      if (needsPersistVendors) _persistVendors();
      if (needsPersistPOs) _persistPurchaseOrders();
      if (needsPersistAssets) _persistWarrantyAssets();
      if (needsPersistTransfers) _persistTransferDockets();
    });
  }

  void _seedDefaultTenantTechs(String tenantId) {
    final isPk = tenantId.contains('PK');
    _technicians.addAll([
      TechnicianRecord(
        id: 'TECH-101',
        tenantId: tenantId,
        name: isPk ? 'Muhammad Tariq Khan' : 'Ahmad Faizal Bin Razali',
        phone: isPk ? '+92 300 5541299' : '+60 12-345 6789',
        nationalId: isPk ? '35201-1492019-1' : '880412-10-5421',
        licenseCode: isPk ? 'PEC-ELECT-44910' : 'ST(PR)SEL-PW4-8891',
        vehiclePlate: isPk ? 'ICT-LE-401 (Toyota Hilux)' : 'WVG 8812 (Toyota HiAce)',
        assignedSite: isPk ? 'Blue Area Tech Tower • Server Hub' : 'Menara AlphaTech • Server Room B2',
        currentStatus: 'ON_SITE',
        disciplines: [BusinessActivityType.cctv, BusinessActivityType.electrical],
      ),
      TechnicianRecord(
        id: 'TECH-102',
        tenantId: tenantId,
        name: isPk ? 'Zeeshan Ali' : 'Karthik A/L Subramaniam',
        phone: isPk ? '+92 333 4192088' : '+60 17-654 3210',
        nationalId: isPk ? '37405-8819201-3' : '920815-14-6633',
        licenseCode: isPk ? 'PEC-CIVIL-8819' : 'CIDB-GREEN-99212',
        vehiclePlate: isPk ? 'RWP-9921 (Suzuki Carry)' : 'BNE 4401 (Nissan NV200)',
        assignedSite: isPk ? 'Expressway Smart Light Pole #42' : 'Persiaran Kayangan Pillar 12',
        currentStatus: 'ON_SITE',
        disciplines: [BusinessActivityType.streetLighting, BusinessActivityType.electrical],
      ),
    ]);
  }

  void _seedDefaultVanItems() {
    _vanStockItems.addAll([
      VanStockItem(
        id: 'ITEM-001',
        sku: 'HIK-4MP-DS2CD',
        name: '4MP AcuSense Fixed Turret IP Camera',
        category: BusinessActivityType.cctv,
        productType: 'ACTIVE_DEVICE',
        warrantyType: '3_YEARS_MFR',
        uom: 'Units',
        quantity: 14,
        minThreshold: 4,
        assignedVanPlate: 'WVG 8812',
      ),
      VanStockItem(
        id: 'ITEM-002',
        sku: 'CAB-CAT6-STP305',
        name: 'Cat6 STP Outdoor Heavy Duty Shielded Cable',
        category: BusinessActivityType.itSolutions,
        productType: 'CABLE_RUN',
        warrantyType: 'CONSUMABLE_NONE',
        uom: 'Boxes (305m)',
        quantity: 4,
        minThreshold: 2,
        assignedVanPlate: 'WVG 8812',
      ),
      VanStockItem(
        id: 'ITEM-003',
        sku: 'ELE-MCB-3P32',
        name: '3-Phase 32A Type C MCB 10kA (Hager)',
        category: BusinessActivityType.electrical,
        productType: 'SPARE_PART',
        warrantyType: '1_YEAR_ONSITE',
        uom: 'Units',
        quantity: 18,
        minThreshold: 6,
        assignedVanPlate: 'BNE 4401',
      ),
      VanStockItem(
        id: 'ITEM-004',
        sku: 'LGT-LED-150W',
        name: '150W IP66 LED Streetlight Luminaire',
        category: BusinessActivityType.streetLighting,
        productType: 'ACTIVE_DEVICE',
        warrantyType: '5_YEARS_MFR',
        uom: 'Sets',
        quantity: 8,
        minThreshold: 3,
        assignedVanPlate: 'BNE 4401',
      ),
    ]);
  }

  void _seedDefaultVendors(String tenantId) {
    final isPk = tenantId.contains('PK');
    _vendors.addAll([
      VendorEntity(
        id: 'VEND-001',
        tenantId: tenantId,
        companyName: isPk ? 'Hikvision Pakistan Authorized Distro' : 'Hikvision Regional Master Distro',
        contactPerson: isPk ? 'Asif Mehmood' : 'Kenji Tan',
        phone: isPk ? '+92 300 8441122' : '+60 12-882 1199',
        email: 'sales@hikvision-distro.com',
        taxRegNumber: isPk ? 'STRN-3277876129481' : 'SST-W10-2309-8812',
        discipline: BusinessActivityType.cctv,
        paymentTerms: 'NET_30',
        bankDetails: isPk ? 'HBL: 0042-7901-2291' : 'Maybank: 5140-1288-9921',
      ),
      VendorEntity(
        id: 'VEND-002',
        tenantId: tenantId,
        companyName: isPk ? 'Pak Elektron Ltd (PEL) Industrial' : 'Hager & Clipsal Industrial Supplies',
        contactPerson: isPk ? 'Khurram Shah' : 'Suresh Rao',
        phone: isPk ? '+92 321 9904411' : '+60 17-331 4455',
        email: 'industrial@switchgear.com',
        taxRegNumber: isPk ? 'NTN-0819201-9' : 'SST-B16-1901-4412',
        discipline: BusinessActivityType.electrical,
        paymentTerms: 'NET_60',
        bankDetails: isPk ? 'Meezan Bank: 0102-881920' : 'Public Bank: 3192-8844-01',
      ),
    ]);
  }

  void _seedDefaultPurchaseOrders(String tenantId) {
    final isPk = tenantId.contains('PK');
    _purchaseOrders.addAll([
      PurchaseOrderEntity(
        id: 'PO-2026-0081',
        tenantId: tenantId,
        vendorId: 'VEND-001',
        vendorName: isPk ? 'Hikvision Pakistan Authorized Distro' : 'Hikvision Regional Master Distro',
        orderDate: DateTime.now().subtract(const Duration(days: 3)),
        targetDestination: isPk ? 'ICT-LE-401' : 'WVG 8812',
        status: 'ISSUED',
        paymentStatus: 'UNPAID',
        taxRate: isPk ? 0.18 : 0.08,
        items: [
          POLineItem(
            sku: 'HIK-4MP-DS2CD',
            description: '4MP AcuSense Fixed Turret IP Camera',
            category: BusinessActivityType.cctv,
            orderedQty: 10,
            receivedQty: 0,
            unitPrice: isPk ? 19500.00 : 285.00,
            uom: 'Units',
            warrantyMonths: 36,
          ),
        ],
      ),
    ]);
  }

  void _seedDefaultWarrantyAssets(String tenantId) {
    _warrantyAssets.addAll([
      AssetWarrantyRecord(
        id: 'ASSET-001',
        tenantId: tenantId,
        serialNumber: 'SN-HIK-882190-C1',
        sku: 'HIK-4MP-DS2CD',
        itemName: '4MP AcuSense Fixed Turret IP Camera',
        poId: 'PO-2026-0081',
        vendorName: 'Hikvision Master Distro',
        assignedVanPlate: 'WVG 8812',
        warrantyStartDate: DateTime.now().subtract(const Duration(days: 60)),
        warrantyEndDate: DateTime.now().add(const Duration(days: 1035)),
        warrantyStatus: 'ACTIVE',
      ),
      AssetWarrantyRecord(
        id: 'ASSET-002',
        tenantId: tenantId,
        serialNumber: 'SN-HIK-882191-C2',
        sku: 'HIK-4MP-DS2CD',
        itemName: '4MP AcuSense Fixed Turret IP Camera',
        poId: 'PO-2026-0081',
        vendorName: 'Hikvision Master Distro',
        assignedVanPlate: 'WVG 8812',
        warrantyStartDate: DateTime.now().subtract(const Duration(days: 60)),
        warrantyEndDate: DateTime.now().add(const Duration(days: 1035)),
        warrantyStatus: 'ACTIVE',
      ),
    ]);
  }

  void _seedDefaultTransferDockets(String tenantId) {
    _transferDockets.addAll([
      VanTransferDocket(
        id: 'MTO-2026-001',
        tenantId: tenantId,
        fromVanPlate: 'WVG 8812',
        fromTechName: 'Ahmad Faizal',
        toVanPlate: 'BNE 4401',
        toTechName: 'Karthik Subramaniam',
        transferDate: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          TransferLineItem(
            sku: 'HIK-4MP-DS2CD',
            itemName: '4MP AcuSense Fixed Turret IP Camera',
            quantity: 2,
            uom: 'Units',
            serialNumbers: ['SN-HIK-882190-C1'],
          ),
        ],
        notes: 'Emergency site replenishment for Persiaran Kayangan project.',
      ),
    ]);
  }

  void _persistTechnicians() {
    final raw = jsonEncode(_technicians.map((t) => t.toMap()).toList());
    _box?.put('${_activeTenantId}_technicians', raw);
  }

  void _persistVanStock() {
    final raw = jsonEncode(_vanStockItems.map((t) => t.toMap()).toList());
    _box?.put('${_activeTenantId}_vanStockItems', raw);
  }

  void _persistVendors() {
    final raw = jsonEncode(_vendors.map((v) => v.toMap()).toList());
    _box?.put('${_activeTenantId}_vendors', raw);
  }

  void _persistPurchaseOrders() {
    final raw = jsonEncode(_purchaseOrders.map((p) => p.toMap()).toList());
    _box?.put('${_activeTenantId}_purchaseOrders', raw);
  }

  void _persistWarrantyAssets() {
    final raw = jsonEncode(_warrantyAssets.map((a) => a.toMap()).toList());
    _box?.put('${_activeTenantId}_warrantyAssets', raw);
  }

  void _persistTransferDockets() {
    final raw = jsonEncode(_transferDockets.map((d) => d.toMap()).toList());
    _box?.put('${_activeTenantId}_transferDockets', raw);
  }

  // --- ATOMIC INTER-VAN STOCK & SERIAL TRANSFER ---
  void executeVanStockTransfer({
    required String fromVanPlate,
    required String toVanPlate,
    required String fromTechName,
    required String toTechName,
    required List<TransferLineItem> transferItems,
    String notes = '',
  }) {
    if (fromVanPlate == toVanPlate || transferItems.isEmpty) return;

    for (final item in transferItems) {
      if (item.quantity <= 0) continue;

      // 1. Decrement source van stock item
      final srcIndex = _vanStockItems.indexWhere((i) =>
          i.sku.toLowerCase() == item.sku.toLowerCase() &&
          (i.assignedVanPlate.toLowerCase().contains(fromVanPlate.toLowerCase()) || i.assignedVanPlate == 'FLEET_ALL'));

      if (srcIndex != -1) {
        final currentQty = _vanStockItems[srcIndex].quantity;
        _vanStockItems[srcIndex].quantity = (currentQty - item.quantity).clamp(0, 99999);
      }

      // 2. Increment or provision destination van stock item
      final destIndex = _vanStockItems.indexWhere((i) =>
          i.sku.toLowerCase() == item.sku.toLowerCase() &&
          i.assignedVanPlate.toLowerCase().contains(toVanPlate.toLowerCase()));

      if (destIndex != -1) {
        _vanStockItems[destIndex].quantity += item.quantity;
      } else {
        final prototype = srcIndex != -1 ? _vanStockItems[srcIndex] : null;
        _vanStockItems.add(
          VanStockItem(
            id: 'ITEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            sku: item.sku,
            name: item.itemName,
            category: prototype?.category ?? BusinessActivityType.cctv,
            productType: prototype?.productType ?? 'ACTIVE_DEVICE',
            warrantyType: prototype?.warrantyType ?? '3_YEARS_MFR',
            uom: item.uom,
            quantity: item.quantity,
            minThreshold: prototype?.minThreshold ?? 4,
            assignedVanPlate: toVanPlate,
          ),
        );
      }

      // 3. Reassign Serialized Warranty Assets to the new vehicle
      for (final sn in item.serialNumbers) {
        final assetIndex = _warrantyAssets.indexWhere((a) => a.serialNumber.toLowerCase() == sn.toLowerCase());
        if (assetIndex != -1) {
          _warrantyAssets[assetIndex].assignedVanPlate = toVanPlate;
        }
      }
    }

    // 4. Log immutable Transfer Docket
    final docketId = 'MTO-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final docket = VanTransferDocket(
      id: docketId,
      tenantId: _activeTenantId,
      fromVanPlate: fromVanPlate,
      fromTechName: fromTechName,
      toVanPlate: toVanPlate,
      toTechName: toTechName,
      transferDate: DateTime.now(),
      items: transferItems,
      notes: notes,
    );
    _transferDockets.insert(0, docket);

    _persistVanStock();
    _persistWarrantyAssets();
    _persistTransferDockets();

    _broadcastEvent(SyncEventType.vanTransferLogged, {'docketId': docketId});
    notifyListeners();
  }

  void registerWarrantyAsset(AssetWarrantyRecord asset) {
    _warrantyAssets.insert(0, asset);
    _persistWarrantyAssets();
    _broadcastEvent(SyncEventType.warrantyRegistered, {'sn': asset.serialNumber, 'poId': asset.poId});
    notifyListeners();
  }

  void acceptPODeliveryAndRestock({
    required String poId,
    required Map<String, int> receivedQuantities,
    Map<String, List<String>>? serialNumbersBySku,
  }) {
    final poIdx = _purchaseOrders.indexWhere((p) => p.id == poId);
    if (poIdx == -1) return;

    final po = _purchaseOrders[poIdx];
    bool anyFulfilled = false;

    for (final entry in receivedQuantities.entries) {
      final sku = entry.key;
      final addedQty = entry.value;
      if (addedQty <= 0) continue;

      final lineItem = po.items.firstWhere(
        (i) => i.sku == sku,
        orElse: () => POLineItem(sku: sku, description: 'Direct Supply', category: BusinessActivityType.cctv, orderedQty: addedQty, unitPrice: 0.0, uom: 'Units'),
      );
      lineItem.receivedQty += addedQty;
      anyFulfilled = true;

      final existingVanItem = _vanStockItems.cast<VanStockItem?>().firstWhere(
        (i) => i!.sku.toLowerCase() == sku.toLowerCase() || i.name.toLowerCase() == lineItem.description.toLowerCase(),
        orElse: () => null,
      );

      if (existingVanItem != null) {
        existingVanItem.quantity += addedQty;
      } else {
        _vanStockItems.add(
          VanStockItem(
            id: 'ITEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            sku: sku,
            name: lineItem.description,
            category: lineItem.category,
            productType: 'ACTIVE_DEVICE',
            warrantyType: '${lineItem.warrantyMonths ~/ 12}_YEARS_MFR',
            uom: lineItem.uom,
            quantity: addedQty,
            minThreshold: 4,
            assignedVanPlate: po.targetDestination,
          ),
        );
      }

      final serialList = serialNumbersBySku?[sku] ?? [];
      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: lineItem.warrantyMonths * 30));

      for (int i = 0; i < addedQty; i++) {
        final sn = i < serialList.length ? serialList[i] : '$sku-SN-${now.millisecondsSinceEpoch.toString().substring(7)}-${i + 1}';
        _warrantyAssets.insert(
          0,
          AssetWarrantyRecord(
            id: 'ASSET-${now.millisecondsSinceEpoch.toString().substring(7)}-${i + 1}',
            tenantId: _activeTenantId,
            serialNumber: sn.trim(),
            sku: sku,
            itemName: lineItem.description,
            poId: po.id,
            vendorName: po.vendorName,
            assignedVanPlate: po.targetDestination,
            warrantyStartDate: now,
            warrantyEndDate: expiryDate,
            warrantyStatus: 'ACTIVE',
          ),
        );
      }
    }

    if (anyFulfilled) {
      final allDone = po.items.every((i) => i.receivedQty >= i.orderedQty);
      po.status = allDone ? 'FULFILLED' : 'PARTIALLY_DELIVERED';

      _persistPurchaseOrders();
      _persistVanStock();
      _persistWarrantyAssets();
      _broadcastEvent(SyncEventType.inventoryAdjusted, {'action': 'po_restock', 'poId': poId});
      notifyListeners();
    }
  }

  void addVendor(VendorEntity vendor) {
    _vendors.insert(0, vendor);
    _persistVendors();
    _broadcastEvent(SyncEventType.vendorUpdated, {'action': 'created', 'vendorId': vendor.id});
    notifyListeners();
  }

  void updateVendor(String id, {
    String? companyName,
    String? contactPerson,
    String? phone,
    String? email,
    String? taxRegNumber,
    BusinessActivityType? discipline,
    String? paymentTerms,
    String? bankDetails,
    bool? isActive,
  }) {
    final idx = _vendors.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final v = _vendors[idx];
      if (companyName != null) v.companyName = companyName;
      if (contactPerson != null) v.contactPerson = contactPerson;
      if (phone != null) v.phone = phone;
      if (email != null) v.email = email;
      if (taxRegNumber != null) v.taxRegNumber = taxRegNumber;
      if (discipline != null) v.discipline = discipline;
      if (paymentTerms != null) v.paymentTerms = paymentTerms;
      if (bankDetails != null) v.bankDetails = bankDetails;
      if (isActive != null) v.isActive = isActive;

      _persistVendors();
      _broadcastEvent(SyncEventType.vendorUpdated, {'action': 'updated', 'vendorId': id});
      notifyListeners();
    }
  }

  void createPurchaseOrder(PurchaseOrderEntity po) {
    _purchaseOrders.insert(0, po);
    _persistPurchaseOrders();
    _broadcastEvent(SyncEventType.poUpdated, {'action': 'created', 'poId': po.id});
    notifyListeners();
  }

  void recordPOPayment({
    required String poId,
    required double paymentAmount,
    required String paymentReference,
  }) {
    final idx = _purchaseOrders.indexWhere((p) => p.id == poId);
    if (idx != -1) {
      final po = _purchaseOrders[idx];
      po.amountPaid += paymentAmount;
      po.paymentReference = paymentReference;

      if (po.amountPaid >= po.totalAmount) {
        po.paymentStatus = 'SETTLED';
      } else if (po.amountPaid > 0) {
        po.paymentStatus = 'PARTIAL';
      }

      _persistPurchaseOrders();
      _broadcastEvent(SyncEventType.poUpdated, {'action': 'payment_recorded', 'poId': poId});
      notifyListeners();
    }
  }

  void addVanStockItem(VanStockItem item) {
    _vanStockItems.insert(0, item);
    _persistVanStock();
    _broadcastEvent(SyncEventType.inventoryAdjusted, {'action': 'created', 'itemId': item.id});
    notifyListeners();
  }

  void updateVanStockItem(String id, {
    String? name,
    String? sku,
    BusinessActivityType? category,
    String? productType,
    String? warrantyType,
    String? uom,
    int? quantity,
    int? minThreshold,
    String? assignedVanPlate,
  }) {
    final idx = _vanStockItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final i = _vanStockItems[idx];
      if (name != null) i.name = name;
      if (sku != null) i.sku = sku;
      if (category != null) i.category = category;
      if (productType != null) i.productType = productType;
      if (warrantyType != null) i.warrantyType = warrantyType;
      if (uom != null) i.uom = uom;
      if (quantity != null) i.quantity = quantity;
      if (minThreshold != null) i.minThreshold = minThreshold;
      if (assignedVanPlate != null) i.assignedVanPlate = assignedVanPlate;

      _persistVanStock();
      _broadcastEvent(SyncEventType.inventoryAdjusted, {'action': 'updated', 'itemId': id});
      notifyListeners();
    }
  }

  void adjustStockCount(String id, int delta) {
    final idx = _vanStockItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final newQty = _vanStockItems[idx].quantity + delta;
      if (newQty >= 0) {
        _vanStockItems[idx].quantity = newQty;
        _persistVanStock();
        _broadcastEvent(SyncEventType.inventoryAdjusted, {'itemId': id, 'delta': delta});
        notifyListeners();
      }
    }
  }

  void replenishStock(String itemKeyOrName, int addedCount) {
    final idx = _vanStockItems.indexWhere((i) =>
        i.id == itemKeyOrName ||
        i.name.toLowerCase() == itemKeyOrName.toLowerCase() ||
        i.sku.toLowerCase() == itemKeyOrName.toLowerCase());

    if (idx != -1) {
      _vanStockItems[idx].quantity += addedCount;
      _persistVanStock();
      _broadcastEvent(SyncEventType.inventoryAdjusted, {'itemId': _vanStockItems[idx].id, 'added': addedCount});
      notifyListeners();
    }
  }

  void consumeVanMaterials(List<String> materials) {
    bool changed = false;
    for (final rawName in materials) {
      final item = _vanStockItems.cast<VanStockItem?>().firstWhere(
        (i) => i!.name.toLowerCase().contains(rawName.toLowerCase()) || rawName.toLowerCase().contains(i.name.toLowerCase()),
        orElse: () => null,
      );

      if (item != null && item.quantity > 0) {
        item.quantity -= 1;
        changed = true;
      }
    }

    if (changed) {
      _persistVanStock();
      _broadcastEvent(SyncEventType.inventoryAdjusted, {'consumed': materials});
      notifyListeners();
    }
  }

  void addTechnician(TechnicianRecord tech) {
    _technicians.insert(0, tech);
    _persistTechnicians();
    _broadcastEvent(SyncEventType.technicianUpdated, {'action': 'created', 'techId': tech.id});
    notifyListeners();
  }

  void dispatchTechnicianSite(String techId, String newSite, String newStatus) {
    final idx = _technicians.indexWhere((t) => t.id == techId);
    if (idx != -1) {
      _technicians[idx].assignedSite = newSite;
      _technicians[idx].currentStatus = newStatus;
      _persistTechnicians();
      _broadcastEvent(SyncEventType.technicianDispatched, {
        'techId': techId,
        'newSite': newSite,
        'newStatus': newStatus,
      });
      notifyListeners();
    }
  }

  void updateTenantConfig({
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
      _box?.put('${_activeTenantId}_companyName', name);
    }
    if (tagline != null) {
      companyTagline = tagline;
      _box?.put('${_activeTenantId}_companyTagline', tagline);
    }
    if (accent != null) {
      themeAccentColor = accent;
      _box?.put('${_activeTenantId}_themeAccentColor', accent.toARGB32());
    }
    if (biometrics != null) {
      enableBiometrics = biometrics;
      _box?.put('${_activeTenantId}_enableBiometrics', biometrics);
    }
    if (vanStores != null) {
      enableVanStores = vanStores;
      _box?.put('${_activeTenantId}_enableVanStores', vanStores);
    }
    if (testing != null) {
      enableTesting = testing;
      _box?.put('${_activeTenantId}_enableTesting', testing);
    }
    if (signOff != null) {
      enableSignOff = signOff;
      _box?.put('${_activeTenantId}_enableSignOff', signOff);
    }
    if (whatsApp != null) {
      enableWhatsApp = whatsApp;
      _box?.put('${_activeTenantId}_enableWhatsApp', whatsApp);
    }

    _broadcastEvent(SyncEventType.configUpdated, {'tenantId': _activeTenantId});
    notifyListeners();
  }

  void _broadcastEvent(SyncEventType type, Map<String, dynamic> payload) {
    if (!_eventStream.isClosed) {
      _eventStream.add(SyncEvent(
        type: type,
        tenantId: _activeTenantId,
        payload: payload,
      ));
    }
  }

  @override
  void dispose() {
    _eventStream.close();
    super.dispose();
  }
}
