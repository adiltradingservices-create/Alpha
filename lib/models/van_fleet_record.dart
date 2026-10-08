import 'package:flutter/foundation.dart';

enum VanOperationalStatus { active, inService, maintenance }

class VanDurableTool {
  final String id;
  final String name;
  final String serialNumber;
  final String category; // e.g., 'TESTER', 'SPLICER', 'LADDER', 'POWER_TOOL'
  String? checkedOutByTechId;
  DateTime? checkedOutAt;
  bool isCalibrated;

  VanDurableTool({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.category,
    this.checkedOutByTechId,
    this.checkedOutAt,
    this.isCalibrated = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'serialNumber': serialNumber,
        'category': category,
        'checkedOutByTechId': checkedOutByTechId,
        'checkedOutAt': checkedOutAt?.toIso8601String(),
        'isCalibrated': isCalibrated,
      };

  factory VanDurableTool.fromMap(Map<String, dynamic> map) => VanDurableTool(
        id: map['id'] as String,
        name: map['name'] as String,
        serialNumber: map['serialNumber'] as String,
        category: map['category'] as String? ?? 'TOOL',
        checkedOutByTechId: map['checkedOutByTechId'] as String?,
        checkedOutAt: map['checkedOutAt'] != null
            ? DateTime.tryParse(map['checkedOutAt'] as String)
            : null,
        isCalibrated: map['isCalibrated'] as bool? ?? true,
      );
}

class VanFleetRecord extends ChangeNotifier {
  final String id;
  final String tenantId;
  String plateNumber;
  String model;
  String depotLocation;
  VanOperationalStatus status;
  List<String> assignedTechnicianIds;
  DateTime lastInspectionDate;

  // Localized Compliance & Fleet Health
  DateTime roadTaxExpiry;
  DateTime commercialInspectionExpiry; // Puspakom (MY) / Fitness (PK) / Safety (Global)
  DateTime insuranceExpiry;
  int currentMileageKm;
  int nextServiceMileageKm;
  List<VanDurableTool> durableTools;

  VanFleetRecord({
    required this.id,
    required this.tenantId,
    required this.plateNumber,
    this.model = 'Toyota HiAce 2.5D / Nissan NV200',
    this.depotLocation = 'Central Depot HQ',
    this.status = VanOperationalStatus.active,
    List<String>? assignedTechnicianIds,
    DateTime? lastInspectionDate,
    DateTime? roadTaxExpiry,
    DateTime? commercialInspectionExpiry,
    DateTime? insuranceExpiry,
    this.currentMileageKm = 84500,
    this.nextServiceMileageKm = 90000,
    List<VanDurableTool>? durableTools,
  })  : assignedTechnicianIds = assignedTechnicianIds ?? [],
        lastInspectionDate = lastInspectionDate ?? DateTime.now(),
        roadTaxExpiry = roadTaxExpiry ?? DateTime.now().add(const Duration(days: 120)),
        commercialInspectionExpiry = commercialInspectionExpiry ?? DateTime.now().add(const Duration(days: 90)),
        insuranceExpiry = insuranceExpiry ?? DateTime.now().add(const Duration(days: 180)),
        durableTools = durableTools ?? [
          VanDurableTool(id: 'T-1', name: 'Fiber Fusion Splicer (Fujikura/Inno)', serialNumber: 'FS-8812-MY', category: 'SPLICER'),
          VanDurableTool(id: 'T-2', name: 'Cat6 Fluke Cable Certifier / OTDR', serialNumber: 'FK-500-PRO', category: 'TESTER'),
          VanDurableTool(id: 'T-3', name: 'Heavy Duty A-Frame Fiberglass Ladder 12ft', serialNumber: 'LDR-12-HV', category: 'LADDER'),
          VanDurableTool(id: 'T-4', name: 'Bosch SDS-Plus Rotary Hammer Drill 800W', serialNumber: 'B-GBH-2-28', category: 'POWER_TOOL'),
        ];

  Map<String, dynamic> toMap() => {
        'id': id,
        'tenantId': tenantId,
        'plateNumber': plateNumber,
        'model': model,
        'depotLocation': depotLocation,
        'status': status.name,
        'assignedTechnicianIds': assignedTechnicianIds,
        'lastInspectionDate': lastInspectionDate.toIso8601String(),
        'roadTaxExpiry': roadTaxExpiry.toIso8601String(),
        'commercialInspectionExpiry': commercialInspectionExpiry.toIso8601String(),
        'insuranceExpiry': insuranceExpiry.toIso8601String(),
        'currentMileageKm': currentMileageKm,
        'nextServiceMileageKm': nextServiceMileageKm,
        'durableTools': durableTools.map((t) => t.toMap()).toList(),
      };

  factory VanFleetRecord.fromMap(Map<String, dynamic> map) {
    return VanFleetRecord(
      id: map['id'] as String,
      tenantId: map['tenantId'] as String? ?? 'TENANT-DEFAULT',
      plateNumber: map['plateNumber'] as String,
      model: map['model'] as String? ?? 'Toyota HiAce',
      depotLocation: map['depotLocation'] as String? ?? 'Central Depot HQ',
      status: VanOperationalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VanOperationalStatus.active,
      ),
      assignedTechnicianIds: List<String>.from(map['assignedTechnicianIds'] ?? []),
      lastInspectionDate: map['lastInspectionDate'] != null
          ? DateTime.tryParse(map['lastInspectionDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      roadTaxExpiry: map['roadTaxExpiry'] != null
          ? DateTime.tryParse(map['roadTaxExpiry'] as String) ?? DateTime.now().add(const Duration(days: 120))
          : DateTime.now().add(const Duration(days: 120)),
      commercialInspectionExpiry: map['commercialInspectionExpiry'] != null
          ? DateTime.tryParse(map['commercialInspectionExpiry'] as String) ?? DateTime.now().add(const Duration(days: 90))
          : DateTime.now().add(const Duration(days: 90)),
      insuranceExpiry: map['insuranceExpiry'] != null
          ? DateTime.tryParse(map['insuranceExpiry'] as String) ?? DateTime.now().add(const Duration(days: 180))
          : DateTime.now().add(const Duration(days: 180)),
      currentMileageKm: map['currentMileageKm'] as int? ?? 84500,
      nextServiceMileageKm: map['nextServiceMileageKm'] as int? ?? 90000,
      durableTools: map['durableTools'] != null
          ? (map['durableTools'] as List).map((t) => VanDurableTool.fromMap(Map<String, dynamic>.from(t))).toList()
          : null,
    );
  }

  void updateDetails({
    String? plateNumber,
    String? model,
    String? depotLocation,
    VanOperationalStatus? status,
    List<String>? assignedTechnicianIds,
    DateTime? roadTaxExpiry,
    DateTime? commercialInspectionExpiry,
    DateTime? insuranceExpiry,
    int? currentMileageKm,
    int? nextServiceMileageKm,
  }) {
    if (plateNumber != null) this.plateNumber = plateNumber;
    if (model != null) this.model = model;
    if (depotLocation != null) this.depotLocation = depotLocation;
    if (status != null) this.status = status;
    if (assignedTechnicianIds != null) this.assignedTechnicianIds = assignedTechnicianIds;
    if (roadTaxExpiry != null) this.roadTaxExpiry = roadTaxExpiry;
    if (commercialInspectionExpiry != null) this.commercialInspectionExpiry = commercialInspectionExpiry;
    if (insuranceExpiry != null) this.insuranceExpiry = insuranceExpiry;
    if (currentMileageKm != null) this.currentMileageKm = currentMileageKm;
    if (nextServiceMileageKm != null) this.nextServiceMileageKm = nextServiceMileageKm;
    notifyListeners();
  }

  void toggleToolCheckout(String toolId, String techId) {
    final idx = durableTools.indexWhere((t) => t.id == toolId);
    if (idx != -1) {
      if (durableTools[idx].checkedOutByTechId == techId) {
        durableTools[idx].checkedOutByTechId = null;
        durableTools[idx].checkedOutAt = null;
      } else {
        durableTools[idx].checkedOutByTechId = techId;
        durableTools[idx].checkedOutAt = DateTime.now();
      }
      notifyListeners();
    }
  }
}