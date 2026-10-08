import '../screens/e_invoice_config_screen.dart';
import '../modules/biometrics/biometrics_module.dart';
import 'package:flutter/material.dart';
import '../models/business_activity.dart';
import '../models/user_session.dart';
import '../services/central_operations_store.dart';
import '../services/data_engine_hub.dart';
import '../services/locale_service.dart';
import '../services/pdf_docket_service.dart';
import '../services/whatsapp_dispatcher_service.dart';

class AdminShell extends StatefulWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const AdminShell({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final CentralOperationsStore _store = CentralOperationsStore();
  final DataEngineHub _hub = DataEngineHub();

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _vanSearchCtrl = TextEditingController();
  final TextEditingController _poSearchCtrl = TextEditingController();
  final TextEditingController _snSearchCtrl = TextEditingController();

  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _taglineCtrl;

  int _currentTab = 0; // 0 = Field Techs, 1 = Van Stock, 2 = Procurement & Warranty, 3 = Config
  int _procurementSubTab = 0; // 0 = Purchase Orders, 1 = Warranty Serial Register, 2 = Inter-Van Transfers, 3 = Vendors
  String _selectedCategoryFilter = 'ALL';

  final List<Color> _colorPalette = const [
    Color(0xFF10B981),
    Color(0xFF38BDF8),
    Color(0xFFA855F7),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController(text: _hub.companyName);
    _taglineCtrl = TextEditingController(text: _hub.companyTagline);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _vanSearchCtrl.dispose();
    _poSearchCtrl.dispose();
    _snSearchCtrl.dispose();
    _companyNameCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  String get _defaultPhonePrefix {
    if (widget.session.countryCode == 'PK') return '+92 300 ';
    if (widget.session.countryCode == 'GLOBAL') return '+1 ';
    return '+60 12-';
  }

  String get _idLabel {
    if (widget.session.countryCode == 'PK') return 'CNIC NUMBER';
    if (widget.session.countryCode == 'GLOBAL') return 'PASSPORT / ID #';
    return 'MYKAD NRIC';
  }

  String get _licenseHint {
    if (widget.session.countryCode == 'PK') return 'PEC / NEPRA Code';
    if (widget.session.countryCode == 'GLOBAL') return 'OSHA / IEC License';
    return 'ST PW4 / CIDB Green';
  }

  String _cleanPlate(String fullPlate) {
    final trimmed = fullPlate.trim();
    if (trimmed.isEmpty || trimmed == 'FLEET_ALL' || trimmed == 'STANDBY') {
      return '';
    }
    final idx = trimmed.indexOf('(');
    final base = (idx != -1 ? trimmed.substring(0, idx) : trimmed).trim().toUpperCase();
    return base;
  }

  List<String> _getUniqueVehiclePlates() {
    final Map<String, String> uniqueMap = {};
    for (final t in _hub.technicians) {
      final p = _cleanPlate(t.vehiclePlate);
      if (p.isNotEmpty) uniqueMap[p] = p;
    }
    for (final item in _hub.vanStockItems) {
      final p = _cleanPlate(item.assignedVanPlate);
      if (p.isNotEmpty) uniqueMap[p] = p;
    }

    if (!uniqueMap.containsKey('WVG 8812')) uniqueMap['WVG 8812'] = 'WVG 8812';
    if (!uniqueMap.containsKey('BNE 4401')) uniqueMap['BNE 4401'] = 'BNE 4401';

    return uniqueMap.values.toList();
  }

  // --- DISPATCH TECHNICIAN MODAL ---
  void _showDispatchDialog(TechnicianEntity tech) {
    final siteCtrl = TextEditingController(text: tech.assignedSite);
    String status = tech.currentStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A101D),
          title: Text("DISPATCH REASSIGN: ${tech.name.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TARGET SITE / PREMISES", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: siteCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 9),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF161F30),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(height: 10),
              const Text("STATUS UPDATE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                value: status,
                dropdownColor: const Color(0xFF161F30),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'ON_SITE', child: Text("ON ACTIVE SITE", style: TextStyle(color: Color(0xFF10B981)))),
                  DropdownMenuItem(value: 'STANDBY', child: Text("STANDBY / WORKSHOP", style: TextStyle(color: Color(0xFFF59E0B)))),
                  DropdownMenuItem(value: 'OFFLINE', child: Text("OFFLINE", style: TextStyle(color: Color(0xFF64748B)))),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => status = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL", style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _store.themeAccentColor),
              onPressed: () {
                _store.updateTechnicianSite(tech.id, siteCtrl.text.trim(), status);
                Navigator.pop(ctx);
              },
              child: const Text("PUSH DISPATCH", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // --- ONBOARD TECHNICIAN MODAL ---
  void _openOnboardTechModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: _defaultPhonePrefix);
    final idCtrl = TextEditingController();
    final licenseCtrl = TextEditingController(text: _licenseHint);
    final vehicleCtrl = TextEditingController(text: widget.session.countryCode == 'PK' ? 'ICT-LE-401' : 'WVG 8812');
    final siteCtrl = TextEditingController(text: 'Central HQ / Standby');
    final selectedDisciplines = <BusinessActivityType>{BusinessActivityType.cctv};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A101D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ONBOARD FIELD TECHNICIAN (${widget.session.countryCode})", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF10B981), size: 18),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    _modalField("FULL LEGAL NAME", nameCtrl, "e.g. Technician Name"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("MOBILE CONTACT", phoneCtrl, _defaultPhonePrefix)),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField(_idLabel, idCtrl, "Identity / ID #")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("LICENSE / PERMIT", licenseCtrl, _licenseHint)),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("ASSIGNED VAN PLATE", vehicleCtrl, "Plate / Vehicle Tag")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _modalField("INITIAL ASSIGNED SITE", siteCtrl, "Default Site / Depot"),
                    const SizedBox(height: 10),

                    const Text("AUTHORIZED DISCIPLINES", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: BusinessActivity.getCategories().map((cat) {
                        final isSel = selectedDisciplines.contains(cat.type);
                        return FilterChip(
                          label: Text(cat.title),
                          selected: isSel,
                          selectedColor: cat.accentColor,
                          backgroundColor: const Color(0xFF161F30),
                          labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: isSel ? cat.accentColor : const Color(0xFF26324D))),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedDisciplines.add(cat.type);
                              } else if (selectedDisciplines.length > 1) {
                                selectedDisciplines.remove(cat.type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _store.themeAccentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: const Text("REGISTER & ACTIVATE TECHNICIAN", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          _store.addTechnician(
                            TechnicianEntity(
                              id: 'TECH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              tenantId: widget.session.tenantId,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              nationalId: idCtrl.text.trim().isEmpty ? 'PENDING' : idCtrl.text.trim(),
                              licenseCode: licenseCtrl.text.trim().isEmpty ? 'GENERAL' : licenseCtrl.text.trim(),
                              vehiclePlate: vehicleCtrl.text.trim().isEmpty ? 'STANDBY' : vehicleCtrl.text.trim(),
                              assignedSite: siteCtrl.text.trim(),
                              currentStatus: 'STANDBY',
                              disciplines: selectedDisciplines.toList(),
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FULL PRODUCT MANAGE MODAL ---
  void _openFullProductManageModal({VanStockItem? editItem}) {
    final isEdit = editItem != null;

    final nameCtrl = TextEditingController(text: editItem?.name ?? '');
    final skuCtrl = TextEditingController(text: editItem?.sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final qtyCtrl = TextEditingController(text: editItem != null ? '${editItem.quantity}' : '10');
    final minCtrl = TextEditingController(text: editItem != null ? '${editItem.minThreshold}' : '4');
    final vanPlateCtrl = TextEditingController(text: editItem?.assignedVanPlate ?? 'FLEET_ALL');

    BusinessActivityType category = editItem?.category ?? BusinessActivityType.cctv;
    String productType = editItem?.productType ?? 'ACTIVE_DEVICE';
    String warrantyType = editItem?.warrantyType ?? '3_YEARS_MFR';
    String uom = editItem?.uom ?? 'Units';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A101D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? "MANAGE PRODUCT INVENTORY & WARRANTY" : "REGISTER NEW VAN ASSET / INVENTORY",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        Icon(isEdit ? Icons.inventory_2_rounded : Icons.add_box_rounded, color: const Color(0xFF38BDF8), size: 18),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    _modalField("PRODUCT / EQUIPMENT NAME", nameCtrl, "e.g. 4MP AcuSense Fixed IP Camera"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("PART SKU / MODEL #", skuCtrl, "e.g. HIK-4MP-TURRET")),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ENGINEERING CATEGORY", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BusinessActivityType>(
                                    value: category,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: BusinessActivityType.values.map((act) => DropdownMenuItem(value: act, child: Text(act.name.toUpperCase()))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => category = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PRODUCT TYPE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: productType,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'ACTIVE_DEVICE', child: Text("Active Device / Network")),
                                      DropdownMenuItem(value: 'SPARE_PART', child: Text("Mechanical / Spare Part")),
                                      DropdownMenuItem(value: 'CONSUMABLE', child: Text("Consumable (Connectors/Tapes)")),
                                      DropdownMenuItem(value: 'CABLE_RUN', child: Text("Cable Drum / Spool")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => productType = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("WARRANTY / SLA COVERAGE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: warrantyType,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: '3_YEARS_MFR', child: Text("3-Year MFR Warranty")),
                                      DropdownMenuItem(value: '2_YEARS_ONSITE', child: Text("2-Year On-Site SLA")),
                                      DropdownMenuItem(value: '1_YEAR_ONSITE', child: Text("1-Year On-Site Standard")),
                                      DropdownMenuItem(value: '5_YEARS_MFR', child: Text("5-Year Industrial")),
                                      DropdownMenuItem(value: 'CONSUMABLE_NONE', child: Text("Consumable (No Warranty)")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => warrantyType = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(child: _modalField("CURRENT STOCK", qtyCtrl, "15")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("MIN ALERT THRESHOLD", minCtrl, "4")),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("U.O.M.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: uom,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'Units', child: Text("Units")),
                                      DropdownMenuItem(value: 'Boxes (305m)', child: Text("Boxes (305m)")),
                                      DropdownMenuItem(value: 'Pcs', child: Text("Pcs")),
                                      DropdownMenuItem(value: 'Sets', child: Text("Sets")),
                                      DropdownMenuItem(value: 'Meters', child: Text("Meters")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => uom = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _modalField("ASSIGNED VAN PLATE ALLOCATION", vanPlateCtrl, "FLEET_ALL or Vehicle Plate"),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: Text(
                          isEdit ? "UPDATE INVENTORY PROFILE" : "ENROLL ITEM INTO VAN FLEET",
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final sku = skuCtrl.text.trim();
                          final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                          final min = int.tryParse(minCtrl.text.trim()) ?? 4;
                          final plate = vanPlateCtrl.text.trim().isEmpty ? 'FLEET_ALL' : vanPlateCtrl.text.trim();

                          if (name.isEmpty) return;

                          if (isEdit) {
                            _hub.updateVanStockItem(
                              editItem.id,
                              name: name,
                              sku: sku,
                              category: category,
                              productType: productType,
                              warrantyType: warrantyType,
                              uom: uom,
                              quantity: qty,
                              minThreshold: min,
                              assignedVanPlate: plate,
                            );
                          } else {
                            _hub.addVanStockItem(
                              VanStockItem(
                                id: 'ITEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                sku: sku,
                                name: name,
                                category: category,
                                productType: productType,
                                warrantyType: warrantyType,
                                uom: uom,
                                quantity: qty,
                                minThreshold: min,
                                assignedVanPlate: plate,
                              ),
                            );
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEdit ? "Stock profile updated: $name" : "New asset registered: $name"), backgroundColor: const Color(0xFF10B981)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- INTER-VAN STOCK & SERIAL TRANSFER MODAL ---
  void _openInterVanTransferModal({VanStockItem? initialItem}) {
    final availablePlates = _getUniqueVehiclePlates();

    String cleanFrom = availablePlates.first;
    if (initialItem != null) {
      final initialPlateClean = _cleanPlate(initialItem.assignedVanPlate);
      if (initialPlateClean.isNotEmpty && availablePlates.contains(initialPlateClean)) {
        cleanFrom = initialPlateClean;
      }
    }

    String cleanTo = availablePlates.length > 1
        ? availablePlates.firstWhere((p) => p != cleanFrom, orElse: () => availablePlates.last)
        : availablePlates.first;

    VanStockItem selectedItem = initialItem ?? _hub.vanStockItems.first;
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController(text: 'Inter-van operational replenishment');

    List<AssetWarrantyRecord> availableSerials = _hub.warrantyAssets
        .where((a) => a.sku == selectedItem.sku && (a.assignedVanPlate.contains(cleanFrom) || a.assignedVanPlate == 'FLEET_ALL') && a.installedSite == null)
        .toList();
    final Set<String> selectedSerialNumbers = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A101D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activePlates = _getUniqueVehiclePlates();
            if (!activePlates.contains(cleanFrom)) {
              cleanFrom = activePlates.first;
            }
            if (!activePlates.contains(cleanTo)) {
              cleanTo = activePlates.length > 1 ? activePlates[1] : activePlates.first;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("INTER-VAN MATERIAL TRANSFER ORDER (MTO)", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981), size: 20),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SOURCE VAN (DISPATCHING)", style: TextStyle(color: Color(0xFFFB7185), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: cleanFrom,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: activePlates.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          cleanFrom = val;
                                          if (cleanTo == cleanFrom && activePlates.length > 1) {
                                            cleanTo = activePlates.firstWhere((p) => p != cleanFrom, orElse: () => activePlates.last);
                                          }
                                          availableSerials = _hub.warrantyAssets
                                              .where((a) => a.sku == selectedItem.sku && (a.assignedVanPlate.contains(cleanFrom) || a.assignedVanPlate == 'FLEET_ALL') && a.installedSite == null)
                                              .toList();
                                          selectedSerialNumbers.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("DESTINATION VAN (RECEIVING)", style: TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: cleanTo,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: activePlates.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          cleanTo = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    const Text("SELECT ITEM TO HANDOVER", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<VanStockItem>(
                          value: selectedItem,
                          dropdownColor: const Color(0xFF161F30),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          items: _hub.vanStockItems.map((i) => DropdownMenuItem<VanStockItem>(value: i, child: Text("${i.name} (${i.quantity} ${i.uom})"))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedItem = val;
                                availableSerials = _hub.warrantyAssets
                                    .where((a) => a.sku == selectedItem.sku && (a.assignedVanPlate.contains(cleanFrom) || a.assignedVanPlate == 'FLEET_ALL') && a.installedSite == null)
                                    .toList();
                                selectedSerialNumbers.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(child: _modalField("TRANSFER QUANTITY", qtyCtrl, "1")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("REASON / TRANSFER NOTES", notesCtrl, "Handover remarks")),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (availableSerials.isNotEmpty) ...[
                      Text("SELECT SERIAL NUMBERS TO REASSIGN (${selectedSerialNumbers.length} Selected):", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 110),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                        child: Material(
                          color: Colors.transparent,
                          child: ListView(
                            shrinkWrap: true,
                            children: availableSerials.map((asset) {
                              final isSel = selectedSerialNumbers.contains(asset.serialNumber);
                              return CheckboxListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(asset.serialNumber, style: const TextStyle(color: Colors.white, fontSize: 8)),
                                subtitle: Text("Valid until: ${asset.warrantyEndDate.year}-${asset.warrantyEndDate.month}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
                                value: isSel,
                                activeColor: const Color(0xFF10B981),
                                checkColor: Colors.black,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedSerialNumbers.add(asset.serialNumber);
                                    } else {
                                      selectedSerialNumbers.remove(asset.serialNumber);
                                    }
                                    qtyCtrl.text = '${selectedSerialNumbers.isNotEmpty ? selectedSerialNumbers.length : 1}';
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: const Text("EXECUTE INTER-VAN HANDOVER", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                        onPressed: () {
                          if (cleanFrom == cleanTo) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Source and Destination vehicles must be different.")));
                            return;
                          }

                          final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                          final fromTech = _hub.technicians.firstWhere((t) => t.vehiclePlate.contains(cleanFrom), orElse: () => _hub.technicians.first).name;
                          final toTech = _hub.technicians.firstWhere((t) => t.vehiclePlate.contains(cleanTo), orElse: () => _hub.technicians.last).name;

                          _hub.executeVanStockTransfer(
                            fromVanPlate: cleanFrom,
                            toVanPlate: cleanTo,
                            fromTechName: fromTech,
                            toTechName: toTech,
                            transferItems: [
                              TransferLineItem(
                                sku: selectedItem.sku,
                                itemName: selectedItem.name,
                                quantity: qty,
                                uom: selectedItem.uom,
                                serialNumbers: selectedSerialNumbers.toList(),
                              ),
                            ],
                            notes: notesCtrl.text.trim(),
                          );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Transferred $qty ${selectedItem.uom} from $cleanFrom to $cleanTo!"), backgroundColor: const Color(0xFF10B981)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openVendorModal({VendorEntity? editVendor}) {
    final isEdit = editVendor != null;
    final nameCtrl = TextEditingController(text: editVendor?.companyName ?? '');
    final picCtrl = TextEditingController(text: editVendor?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: editVendor?.phone ?? _defaultPhonePrefix);
    final emailCtrl = TextEditingController(text: editVendor?.email ?? '');
    final taxCtrl = TextEditingController(text: editVendor?.taxRegNumber ?? '');
    final bankCtrl = TextEditingController(text: editVendor?.bankDetails ?? '');

    BusinessActivityType discipline = editVendor?.discipline ?? BusinessActivityType.cctv;
    String paymentTerms = editVendor?.paymentTerms ?? 'NET_30';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A101D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? "EDIT ACCREDITED SUPPLIER" : "ONBOARD HARDWARE VENDOR (${widget.session.countryCode})",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 18),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    _modalField("VENDOR COMPANY NAME", nameCtrl, "e.g. Authorized Distributor"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("SALES REP / PIC", picCtrl, "Contact Person")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("CONTACT NUMBER", phoneCtrl, _defaultPhonePrefix)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _modalField("ORDERS EMAIL", emailCtrl, "orders@supplier.com")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField(widget.session.countryCode == 'PK' ? "NTN / STRN #" : (widget.session.countryCode == 'MY' ? "SST REG NUMBER" : "TAX ID / VAT #"), taxCtrl, "Tax Registration #")),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PRIMARY DISCIPLINE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<BusinessActivityType>(
                                    value: discipline,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: BusinessActivityType.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase()))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => discipline = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PAYMENT TERMS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: paymentTerms,
                                    dropdownColor: const Color(0xFF161F30),
                                    isExpanded: true,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'NET_30', child: Text("Net 30 Days Credit")),
                                      DropdownMenuItem(value: 'NET_60', child: Text("Net 60 Days Credit")),
                                      DropdownMenuItem(value: 'COD', child: Text("Cash on Delivery")),
                                      DropdownMenuItem(value: '50_ADVANCE', child: Text("50% Adv / 50% Delivery")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => paymentTerms = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _modalField("SETTLEMENT BANK & ACCOUNT #", bankCtrl, "Bank Account Details"),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
                        label: Text(
                          isEdit ? "SAVE VENDOR PROFILE" : "ENROLL ACCREDITED VENDOR",
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          if (isEdit) {
                            _hub.updateVendor(
                              editVendor.id,
                              companyName: nameCtrl.text.trim(),
                              contactPerson: picCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              taxRegNumber: taxCtrl.text.trim(),
                              discipline: discipline,
                              paymentTerms: paymentTerms,
                              bankDetails: bankCtrl.text.trim(),
                            );
                          } else {
                            _hub.addVendor(
                              VendorEntity(
                                id: 'VEND-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                tenantId: widget.session.tenantId,
                                companyName: nameCtrl.text.trim(),
                                contactPerson: picCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                taxRegNumber: taxCtrl.text.trim(),
                                discipline: discipline,
                                paymentTerms: paymentTerms,
                                bankDetails: bankCtrl.text.trim(),
                              ),
                            );
                          }
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCreatePOModal({VanStockItem? prefillItem}) {
    if (_hub.vendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please onboard at least one vendor first!")));
      return;
    }

    VendorEntity selectedVendor = _hub.vendors.first;
        final availablePlates = _getUniqueVehiclePlates();
    String targetDestination = 'FLEET_ALL';
    if (prefillItem != null && prefillItem.assignedVanPlate.isNotEmpty && prefillItem.assignedVanPlate != 'FLEET_ALL') {
      final clean = _cleanPlate(prefillItem.assignedVanPlate);
      if (clean.isNotEmpty && availablePlates.contains(clean)) {
        targetDestination = clean;
      }
    }
    final descCtrl = TextEditingController(text: prefillItem?.name ?? '4MP AcuSense Fixed Turret IP Camera');
    final skuCtrl = TextEditingController(text: prefillItem?.sku ?? 'HIK-4MP-DS2CD');
    final qtyCtrl = TextEditingController(text: prefillItem != null ? '${prefillItem.minThreshold * 2}' : '10');
    final priceCtrl = TextEditingController(text: widget.session.countryCode == 'PK' ? '18500.00' : '280.00');
    int warrantyMonths = 36;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A101D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(prefillItem != null ? "AUTO-REORDER LOW STOCK PART" : "RAISE PURCHASE ORDER (${widget.session.countryCode})", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        const Icon(Icons.post_add_rounded, color: Color(0xFFF59E0B), size: 18),
                      ],
                    ),
                    const Divider(color: Color(0xFF1E293B), height: 16),

                    const Text("SELECT ACCREDITED VENDOR", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<VendorEntity>(
                          value: selectedVendor,
                          dropdownColor: const Color(0xFF161F30),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          items: _hub.vendors.map((v) => DropdownMenuItem(value: v, child: Text("${v.companyName} (${v.discipline.name.toUpperCase()})"))).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedVendor = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text("DELIVERY TARGET (VAN STOCK / SITE DROP)", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (availablePlates.contains(targetDestination) || targetDestination == 'FLEET_ALL' || targetDestination == 'DIRECT_SITE_DROP') ? targetDestination : 'FLEET_ALL',
                          dropdownColor: const Color(0xFF161F30),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          items: [
                            const DropdownMenuItem(value: 'FLEET_ALL', child: Text('General Fleet Stores - All Vans')),
                            ...availablePlates.map((p) => DropdownMenuItem<String>(value: p, child: Text('Van: $p'))),
                            const DropdownMenuItem(value: 'DIRECT_SITE_DROP', child: Text('Direct On-Site Project Drop')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => targetDestination = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text("PO LINE ITEM SPECIFICATION", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    _modalField("ITEM DESCRIPTION", descCtrl, "Part / Hardware description"),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _modalField("PART SKU", skuCtrl, "SKU #")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("ORDERED QTY", qtyCtrl, "10")),
                        const SizedBox(width: 8),
                        Expanded(child: _modalField("UNIT PRICE (${widget.session.currencySymbol})", priceCtrl, "Amount")),
                      ],
                    ),
                    const SizedBox(height: 8),

                    const Text("SUPPLIER WARRANTY COVERAGE TERM", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: warrantyMonths,
                          dropdownColor: const Color(0xFF161F30),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 12, child: Text("12 Months (1 Year Standard)")),
                            DropdownMenuItem(value: 24, child: Text("24 Months (2 Years On-Site SLA)")),
                            DropdownMenuItem(value: 36, child: Text("36 Months (3 Years Manufacturer)")),
                            DropdownMenuItem(value: 60, child: Text("60 Months (5 Years Industrial Grade)")),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => warrantyMonths = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.black, size: 16),
                        label: const Text("GENERATE & ISSUE PURCHASE ORDER", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                        onPressed: () {
                          final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                          final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                          _hub.createPurchaseOrder(
                            PurchaseOrderEntity(
                              id: 'PO-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              tenantId: widget.session.tenantId,
                              vendorId: selectedVendor.id,
                              vendorName: selectedVendor.companyName,
                              orderDate: DateTime.now(),
                              targetDestination: targetDestination,
                              taxRate: widget.session.taxRate,
                              items: [
                                POLineItem(
                                  sku: skuCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  category: selectedVendor.discipline,
                                  orderedQty: qty,
                                  unitPrice: price,
                                  uom: prefillItem?.uom ?? 'Units',
                                  warrantyMonths: warrantyMonths,
                                ),
                              ],
                            ),
                          );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Purchase Order issued! Ready for delivery & serial registration."), backgroundColor: Color(0xFF10B981)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAcceptDeliveryWithSerialsDialog(PurchaseOrderEntity po) {
    final Map<String, TextEditingController> qtyControllers = {
      for (var item in po.items) item.sku: TextEditingController(text: '${item.orderedQty - item.receivedQty}')
    };

    final Map<String, TextEditingController> serialControllers = {
      for (var item in po.items) item.sku: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A101D),
        title: Text("RECEIVE GOODS & REGISTER SERIALS: ${po.id}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Supplier: ${po.vendorName}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
                Text("Destination: ${po.targetDestination}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFF1E293B), height: 16),
                const Text("LOG QUANTITIES & SERIAL NUMBERS:", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                ...po.items.map((item) {
                  final remaining = item.orderedQty - item.receivedQty;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.description, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            Text("Warranty: ${item.warrantyMonths} Mos", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 7)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _modalField("RECEIVING QTY", qtyControllers[item.sku]!, "$remaining"),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _modalField("SCAN / COMMA-SEPARATED SERIALS", serialControllers[item.sku]!, "SN-1001, SN-1002..."),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text("*Leave empty to auto-generate unique hardware serial barcodes.", style: TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Color(0xFF64748B), fontSize: 8))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.verified_rounded, color: Colors.black, size: 14),
            label: const Text("REGISTER WARRANTY & RESTOCK", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
            onPressed: () {
              final Map<String, int> received = {};
              final Map<String, List<String>> serialMap = {};

              qtyControllers.forEach((sku, ctrl) {
                final count = int.tryParse(ctrl.text.trim()) ?? 0;
                if (count > 0) {
                  received[sku] = count;
                  final rawSNs = serialControllers[sku]?.text.trim() ?? '';
                  if (rawSNs.isNotEmpty) {
                    serialMap[sku] = rawSNs.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  }
                }
              });

              _hub.acceptPODeliveryAndRestock(
                poId: po.id,
                receivedQuantities: received,
                serialNumbersBySku: serialMap,
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hardware Serial Numbers & Warranties Registered Successfully!"), backgroundColor: Color(0xFF10B981)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openRecordPaymentDialog(PurchaseOrderEntity po) {
    final outstanding = po.totalAmount - po.amountPaid;
    final amountCtrl = TextEditingController(text: outstanding.toStringAsFixed(2));
    final refCtrl = TextEditingController(text: '${widget.session.countryCode == 'PK' ? 'HBL-IBFT' : 'MBB-IBFT'}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A101D),
        title: Text("RECORD AP PAYMENT: ${po.id}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Payee: ${po.vendorName}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
            Text("Outstanding: ${widget.session.currencySymbol} ${outstanding.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFB7185), fontSize: 8, fontWeight: FontWeight.bold)),
            const Divider(color: Color(0xFF1E293B), height: 16),
            _modalField("PAYMENT AMOUNT (${widget.session.currencySymbol})", amountCtrl, "Amount"),
            const SizedBox(height: 8),
            _modalField("PAYMENT REF (IBFT/CHEQUE/RECEIPT)", refCtrl, "Transaction Ref #"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Color(0xFF64748B), fontSize: 8))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt <= 0) return;

              _hub.recordPOPayment(poId: po.id, paymentAmount: amt, paymentReference: refCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment recorded: ${widget.session.currencySymbol} $amt"), backgroundColor: const Color(0xFF10B981)),
              );
            },
            child: const Text("CONFIRM SETTLEMENT", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _previewPurchaseOrderPdf(PurchaseOrderEntity po) async {
    final pdfBytes = await PdfDocketService().generatePurchaseOrderPdf(
      po: po,
      currencySymbol: widget.session.currencySymbol,
      taxLabel: widget.session.taxEngine,
      countryCode: widget.session.countryCode,
    );
    if (!mounted) return;
    await PdfDocketService().previewDocket(context, pdfBytes, "${po.id}-Official-Order");
  }

  Future<void> _previewTransferDocketPdf(VanTransferDocket docket) async {
    final pdfBytes = await PdfDocketService().generateInterVanTransferPdf(docket: docket);
    if (!mounted) return;
    await PdfDocketService().previewDocket(context, pdfBytes, "${docket.id}-Transfer-Order");
  }

  Widget _modalField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SizedBox(
          height: 34,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 8),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7),
              filled: true,
              fillColor: const Color(0xFF161F30),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hub,
      builder: (context, _) {
        if (_companyNameCtrl.text != _hub.companyName && !_companyNameCtrl.selection.isValid) {
          _companyNameCtrl.text = _hub.companyName;
        }
        if (_taglineCtrl.text != _hub.companyTagline && !_taglineCtrl.selection.isValid) {
          _taglineCtrl.text = _hub.companyTagline;
        }

        final regionFlag = widget.session.countryCode == 'PK' ? '🇵🇰' : (widget.session.countryCode == 'MY' ? '🇲🇾' : '🌐');

        return Scaffold(
          backgroundColor: const Color(0xFF030712),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A101D),
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Icon(Icons.hub_rounded, color: _hub.themeAccentColor, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_hub.companyName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        Text(regionFlag, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                    Text("${widget.session.regulatoryBody} • ${widget.session.taxEngine}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language_rounded, color: Color(0xFF38BDF8), size: 20),
                tooltip: "Toggle Language",
                onPressed: () {
                  LocaleService.toggleLanguage();
                  setState(() {});
                },
              ),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFFFB7185), size: 18), onPressed: widget.onLogout),
              const SizedBox(width: 4),
            ],
          ),
          body: _buildActiveTabContent(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (idx) => setState(() => _currentTab = idx),
            backgroundColor: const Color(0xFF0A101D),
            selectedItemColor: _hub.themeAccentColor,
            unselectedItemColor: const Color(0xFF64748B),
            selectedFontSize: 8,
            unselectedFontSize: 8,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.groups_rounded, size: 18), label: "Field Techs"),
                BottomNavigationBarItem(icon: Icon(Icons.fingerprint_rounded, size: 18), label: "Attendance"),
              BottomNavigationBarItem(icon: Icon(Icons.airport_shuttle_rounded, size: 18), label: "Van Stock"),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded, size: 18), label: "Procure & Logistics"),
              BottomNavigationBarItem(icon: Icon(Icons.tune_rounded, size: 18), label: "Config"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildFieldTechsTab();
      case 1:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: AdminAttendanceLedgerView(),
        );
      case 2:
        return _buildVanStockTab();
      case 3:
        return _buildProcurementAndWarrantyTab();
      case 4:
      default:
        return _buildConfigTab();
    }
  }

  Widget _buildFieldTechsTab() {
    final techs = _hub.technicians.where((t) {
      final q = _searchCtrl.text.toLowerCase();
      return t.name.toLowerCase().contains(q) || t.assignedSite.toLowerCase().contains(q) || t.phone.contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            _kpiCard("ACTIVE FORCE", "${_hub.technicians.length}", Icons.groups_rounded, const Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            _kpiCard("DISPATCHED", "${_hub.technicians.where((t) => t.currentStatus == 'ON_SITE').length}", Icons.location_on_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _kpiCard("STANDBY", "${_hub.technicians.where((t) => t.currentStatus == 'STANDBY').length}", Icons.pause_circle_rounded, const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  decoration: InputDecoration(
                    hintText: "Search active technician, site, vehicle plate...",
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hub.themeAccentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                label: const Text("ONBOARD", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                onPressed: _openOnboardTechModal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...techs.map((tech) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tech.currentStatus == 'ON_SITE' ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      border: Border.all(color: tech.currentStatus == 'ON_SITE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                    ),
                    child: Center(
                      child: Text(tech.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tech.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(tech.currentStatus.replaceAll('_', ' '), style: TextStyle(color: tech.currentStatus == 'ON_SITE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text("${tech.vehiclePlate} • ${tech.phone}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7)),
                        const SizedBox(height: 2),
                        Text("Site: ${tech.assignedSite}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_to_mobile_rounded, color: Color(0xFF38BDF8), size: 18),
                    onPressed: () => _showDispatchDialog(tech),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16),
                    onPressed: () => WhatsAppDispatcherService().sendSiteReport(
                      context: context,
                      recipientPhone: tech.phone,
                      message: "Dispatch Update from HQ: Proceed to ${tech.assignedSite}.",
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildVanStockTab() {
    final vanItems = _hub.vanStockItems.where((i) {
      final q = _vanSearchCtrl.text.toLowerCase();
      final matchesSearch = i.name.toLowerCase().contains(q) || i.sku.toLowerCase().contains(q) || i.assignedVanPlate.toLowerCase().contains(q);
      if (!matchesSearch) return false;
      if (_selectedCategoryFilter != 'ALL' && i.category.name != _selectedCategoryFilter) return false;
      return true;
    }).toList();

    final lowStockItems = _hub.vanStockItems.where((i) => i.isLowStock || i.isDepleted).toList();
    final totalUnits = _hub.vanStockItems.fold<int>(0, (sum, i) => sum + i.quantity);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (lowStockItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CRITICAL: ${lowStockItems.length} SKUs BELOW MINIMUM THRESHOLD", style: const TextStyle(color: Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.w900)),
                      Text("${lowStockItems.first.name} (${lowStockItems.first.quantity} ${lowStockItems.first.uom} left in ${lowStockItems.first.assignedVanPlate})", style: const TextStyle(color: Colors.white, fontSize: 7)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentTab = 2;
                      _procurementSubTab = 0;
                    });
                    _openCreatePOModal(prefillItem: lowStockItems.first);
                  },
                  child: const Text("AUTO-RESTOCK PO", style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),

        Row(
          children: [
            _kpiCard("FLEET SKUs", "${_hub.vanStockItems.length}", Icons.layers_rounded, const Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            _kpiCard("TOTAL UNITS", "$totalUnits", Icons.inventory_2_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _kpiCard("TRANSFERS", "${_hub.transferDockets.length}", Icons.swap_horiz_rounded, const Color(0xFFA855F7)),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _vanSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  decoration: InputDecoration(
                    hintText: "Search SKU, product name, warranty, van plate...",
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.black, size: 16),
                label: const Text("VAN TRANSFER", style: TextStyle(color: Colors.black, fontSize: 7.5, fontWeight: FontWeight.w900)),
                onPressed: () => _openInterVanTransferModal(),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.add_box_rounded, color: Colors.black, size: 16),
                label: const Text("ENROLL", style: TextStyle(color: Colors.black, fontSize: 7.5, fontWeight: FontWeight.w900)),
                onPressed: () => _openFullProductManageModal(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _categoryFilterChip('ALL', "ALL DISCIPLINES (${_hub.vanStockItems.length})"),
              _categoryFilterChip('cctv', "CCTV & SECURITY"),
              _categoryFilterChip('electrical', "ELECTRICAL / POWER"),
              _categoryFilterChip('streetLighting', "SMART LIGHTING"),
              _categoryFilterChip('itSolutions', "IT & NETWORKS"),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (vanItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12)),
            child: const Center(
              child: Text("No products match the selected criteria.", style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
            ),
          )
        else
          ...vanItems.map((item) {
            final isLow = item.isLowStock;
            final isOut = item.isDepleted;

            Color badgeColor = const Color(0xFF10B981);
            String badgeText = "OPTIMAL";
            if (isOut) {
              badgeColor = const Color(0xFFEF4444);
              badgeText = "DEPLETED";
            } else if (isLow) {
              badgeColor = const Color(0xFFF59E0B);
              badgeText = "LOW STOCK";
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOut ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(color: const Color(0xFF38BDF8).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(item.category.name.toUpperCase(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5, fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 6),
                                Text("SKU: ${item.sku}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 6.5, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981), size: 18),
                        tooltip: "Transfer to another van",
                        onPressed: () => _openInterVanTransferModal(initialItem: item),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 18),
                        tooltip: "Edit Product Metadata",
                        onPressed: () => _openFullProductManageModal(editItem: item),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF161F30), height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("TYPE: ${item.productType.replaceAll('_', ' ')}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                            const SizedBox(height: 1.5),
                            Text("WARRANTY: ${item.warrantyType.replaceAll('_', ' ')}", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 1.5),
                            Text("VAN FLEET: ${item.assignedVanPlate}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161F30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF26324D)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove, color: Color(0xFFFB7185), size: 14),
                              onPressed: item.quantity > 0 ? () => _hub.adjustStockCount(item.id, -1) : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  Text("${item.quantity}", style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.w900)),
                                  Text(item.uom, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6)),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add, color: Color(0xFF10B981), size: 14),
                              onPressed: () => _hub.adjustStockCount(item.id, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProcurementAndWarrantyTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            _procureSubTabButton(0, "POs (${_hub.purchaseOrders.length})", const Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            _procureSubTabButton(1, "SERIALS (${_hub.warrantyAssets.length})", const Color(0xFF38BDF8)),
            const SizedBox(width: 4),
            _procureSubTabButton(2, "TRANSFERS (${_hub.transferDockets.length})", const Color(0xFFA855F7)),
            const SizedBox(width: 4),
            _procureSubTabButton(3, "VENDORS (${_hub.vendors.length})", const Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 12),

        if (_procurementSubTab == 0) ...[
          // PURCHASE ORDERS
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _poSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    decoration: InputDecoration(
                      hintText: "Search PO number, supplier, van target...",
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.black, size: 16),
                  label: const Text("RAISE PO", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                  onPressed: () => _openCreatePOModal(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._hub.purchaseOrders.map((po) {
            final isFulfilled = po.status == 'FULFILLED';
            final isSettled = po.paymentStatus == 'SETTLED';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isFulfilled ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(po.id, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isFulfilled ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(po.status, style: TextStyle(color: isFulfilled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 6.5, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSettled ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(po.paymentStatus, style: TextStyle(color: isSettled ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 6.5, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8), size: 16),
                            tooltip: "Print Branded PO PDF",
                            onPressed: () => _previewPurchaseOrderPdf(po),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text("Vendor: ${po.vendorName}", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.bold)),
                  Text("Target: ${po.targetDestination} • Date: ${po.orderDate.day}/${po.orderDate.month}/${po.orderDate.year}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                  const Divider(color: Color(0xFF161F30), height: 12),

                  ...po.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("• ${item.description} (x${item.orderedQty}) [${item.warrantyMonths}m Warranty]", style: const TextStyle(color: Colors.white, fontSize: 8)),
                            Text("${widget.session.currencySymbol} ${item.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total (incl ${widget.session.taxEngine}): ${widget.session.currencySymbol} ${po.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.w900)),
                      Text("Paid: ${widget.session.currencySymbol} ${po.amountPaid.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      if (!isFulfilled)
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 12),
                              label: const Text("RECEIVE & LOG SERIALS", style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.w900)),
                              onPressed: () => _openAcceptDeliveryWithSerialsDialog(po),
                            ),
                          ),
                        ),
                      if (!isFulfilled) const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.payment_rounded, color: Color(0xFF38BDF8), size: 12),
                            label: Text(isSettled ? "SETTLED REF" : "RECORD PAYMENT", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.w900)),
                            onPressed: () => _openRecordPaymentDialog(po),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ] else if (_procurementSubTab == 1) ...[
          // SERIALIZED WARRANTY REGISTER
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _snSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    decoration: InputDecoration(
                      hintText: "Search Serial #, SKU, Site, or PO number...",
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._hub.warrantyAssets.where((a) {
            final q = _snSearchCtrl.text.toLowerCase();
            return a.serialNumber.toLowerCase().contains(q) ||
                a.sku.toLowerCase().contains(q) ||
                a.itemName.toLowerCase().contains(q) ||
                (a.installedSite?.toLowerCase().contains(q) ?? false);
          }).map((asset) {
            final isExp = asset.isExpired;
            final isInstalled = asset.installedSite != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isExp ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFF38BDF8).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isExp ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.qr_code_2_rounded, color: isExp ? const Color(0xFFEF4444) : const Color(0xFF38BDF8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(asset.serialNumber, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isExp ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isExp ? "EXPIRED" : "${asset.daysRemaining}d REMAINING",
                                style: TextStyle(color: isExp ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontSize: 6.5, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text("${asset.itemName} (SKU: ${asset.sku})", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7.5)),
                        const SizedBox(height: 2),
                        Text(
                          "PO: ${asset.poId} • Valid: ${asset.warrantyStartDate.day}/${asset.warrantyStartDate.month}/${asset.warrantyStartDate.year} ➔ ${asset.warrantyEndDate.day}/${asset.warrantyEndDate.month}/${asset.warrantyEndDate.year}",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(isInstalled ? Icons.business_rounded : Icons.airport_shuttle_rounded, color: isInstalled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 10),
                            const SizedBox(width: 4),
                            Text(
                              isInstalled ? "Installed at: ${asset.installedSite}" : "In Van Stock: ${asset.assignedVanPlate}",
                              style: TextStyle(color: isInstalled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else if (_procurementSubTab == 2) ...[
          // INTER-VAN TRANSFERS HISTORY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("INTER-VAN MATERIAL TRANSFERS (MTO)", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA855F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 14),
                label: const Text("NEW TRANSFER", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                onPressed: () => _openInterVanTransferModal(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_hub.transferDockets.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text("No vehicle-to-vehicle stock transfers recorded.", style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
              ),
            )
          else
            ..._hub.transferDockets.map((docket) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(docket.id, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF38BDF8), size: 16),
                              tooltip: "Print Transfer Docket PDF",
                              onPressed: () => _previewTransferDocketPdf(docket),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16),
                              tooltip: "Send Transfer Manifest WhatsApp",
                              onPressed: () {
                                final summary = docket.items.map((i) => "${i.itemName} (x${i.quantity})").join(", ");
                                final message = """
🚚 *INTER-VAN MATERIAL HANDOVER CONFIRMATION*
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 *Docket:* ${docket.id}
📤 *From Van:* ${docket.fromVanPlate} (${docket.fromTechName})
📥 *To Van:* ${docket.toVanPlate} (${docket.toTechName})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 *Items:* $summary
📝 *Notes:* ${docket.notes.isEmpty ? 'Handover completed' : docket.notes}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_Generated via FieldOps Operations_
""";
                                WhatsAppDispatcherService().sendSiteReport(
                                  context: context,
                                  recipientPhone: "+60123456789",
                                  message: message,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(docket.fromVanPlate, style: const TextStyle(color: Color(0xFFFB7185), fontSize: 8, fontWeight: FontWeight.bold)),
                        const Text(" ➔ ", style: TextStyle(color: Color(0xFF64748B), fontSize: 8)),
                        Text(docket.toVanPlate, style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text("• ${docket.transferDate.day}/${docket.transferDate.month}/${docket.transferDate.year}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                      ],
                    ),
                    const Divider(color: Color(0xFF161F30), height: 10),

                    ...docket.items.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            "• ${i.itemName} (x${i.quantity} ${i.uom}) ${i.serialNumbers.isNotEmpty ? '[SN: ${i.serialNumbers.join(", ")}]' : ''}",
                            style: const TextStyle(color: Colors.white, fontSize: 8),
                          ),
                        )),
                  ],
                ),
              );
            }),
        ] else ...[
          // VENDORS DIRECTORY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ACCREDITED SUPPLIERS (${widget.session.countryCode})", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w900)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add_business_rounded, color: Colors.black, size: 14),
                label: const Text("ONBOARD VENDOR", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                onPressed: () => _openVendorModal(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._hub.vendors.map((v) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(v.companyName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(v.discipline.name.toUpperCase(), style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text("${v.contactPerson} • ${v.phone} • Terms: ${v.paymentTerms.replaceAll('_', ' ')}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                        const SizedBox(height: 1.5),
                        Text("Tax: ${v.taxRegNumber} • ${v.bankDetails}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 16),
                    onPressed: () => WhatsAppDispatcherService().sendSiteReport(
                      context: context,
                      recipientPhone: v.phone,
                      message: "Procurement Inquiry from ${_hub.companyName}: Please share quote & stock availability.",
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _procureSubTabButton(int index, String title, Color activeColor) {
    final isSelected = _procurementSubTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _procurementSubTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.2) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? activeColor : const Color(0xFF1E293B)),
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: isSelected ? activeColor : const Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text("ENTERPRISE CONFIGURATION & WHITELISTING", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        const Divider(color: Color(0xFF1E293B), height: 16),

        _configSectionTitle("1. WHITE-LABEL BRANDING"),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _configTextField("COMPANY LEGAL NAME", _companyNameCtrl),
              const SizedBox(height: 8),
              _configTextField("COMPANY TAGLINE", _taglineCtrl),
              const SizedBox(height: 10),
              const Text("THEME ACCENT COLOR", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: _colorPalette.map((col) {
                  final isSel = _hub.themeAccentColor.toARGB32() == col.toARGB32();
                  return InkWell(
                    onTap: () {
                      _hub.updateTenantConfig(
                        name: _companyNameCtrl.text.trim(),
                        tagline: _taglineCtrl.text.trim(),
                        accent: col,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                      ),
                      child: isSel ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _hub.themeAccentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    _hub.updateTenantConfig(
                      name: _companyNameCtrl.text.trim(),
                      tagline: _taglineCtrl.text.trim(),
                      accent: _hub.themeAccentColor,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Branding saved!"), backgroundColor: Color(0xFF10B981)));
                  },
                  child: const Text("SAVE BRANDING", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _configSectionTitle("2. TECHNICIAN FEATURE WHITELISTING"),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E293B))),
          child: Column(
            children: [
              _whitelistSwitch("Biometrics Face & GPS Attendance", _hub.enableBiometrics, (v) => _hub.updateTenantConfig(biometrics: v)),
              const Divider(color: Color(0xFF1E293B), height: 10),
              _whitelistSwitch("Mobile Van Inventory Stores", _hub.enableVanStores, (v) => _hub.updateTenantConfig(vanStores: v)),
              const Divider(color: Color(0xFF1E293B), height: 10),
              _whitelistSwitch("Testing & Commissioning Engine", _hub.enableTesting, (v) => _hub.updateTenantConfig(testing: v)),
              const Divider(color: Color(0xFF1E293B), height: 10),
              _whitelistSwitch("Client Touch Digital Sign-Off", _hub.enableSignOff, (v) => _hub.updateTenantConfig(signOff: v)),
              const Divider(color: Color(0xFF1E293B), height: 10),
              _whitelistSwitch("One-Tap WhatsApp Site Dispatch", _hub.enableWhatsApp, (v) => _hub.updateTenantConfig(whatsApp: v)),
            ],
          ),
        ),
        const SizedBox(height: 20),
          const SizedBox(height: 16),
          _configSectionTitle("4. E-INVOICING & STATUTORY TAX COMPLIANCE"),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "LHDN MyInvois / Statutory Gateways",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "TIN, SST, Client ID credentials & ERP integration",
                            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 15),
                    label: const Text("CONFIGURE E-INVOICE GATEWAY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EInvoiceConfigScreen(session: widget.session),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  Widget _categoryFilterChip(String key, String title) {
    final isSelected = _selectedCategoryFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryFilter = key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B)),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _configSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6));
  }

  Widget _configTextField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        SizedBox(
          height: 34,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161F30),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 6, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _whitelistSwitch(String title, bool val, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        Switch(
          value: val,
          onChanged: onChanged,
          activeThumbColor: _hub.themeAccentColor,
        ),
      ],
    );
  }
}

