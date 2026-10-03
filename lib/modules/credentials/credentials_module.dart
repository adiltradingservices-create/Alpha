import 'package:flutter/material.dart';
import '../../core/app_module.dart';
import '../../services/locale_service.dart';

class CredentialsModule implements AppModule {
  @override
  String get moduleId => 'CREDENTIALS_GATEKEEPER';

  @override
  String get title => LocaleService.currentLanguage.value == AppLanguage.en
      ? 'CREDENTIALS GATEKEEPER & WORKFORCE DOSSIER'
      : 'DOSIER KAKITANGAN & LESEN BERKANUN (CIDB / ST / PEC)';

  @override
  IconData get icon => Icons.verified_user_rounded;

  static Map<String, dynamic> getCategoryBadge(String category, bool isEn) {
    switch (category) {
      case 'OFFICE_STAFF':
        return {
          'label': isEn ? 'OFFICE & BILLING' : 'PEJABAT & HR',
          'color': const Color(0xFFA855F7),
          'desc': isEn ? 'Tax Invoicing & HR Administration' : 'Pengebilan & Pentadbiran'
        };
      case 'WAREHOUSE_STORE':
        return {
          'label': isEn ? 'STORE & LOGISTICS' : 'STOR & LOGISTIK',
          'color': const Color(0xFF0EA5E9),
          'desc': isEn ? 'Inventory Ledger & Buffer Control' : 'Kawalan Stok & Barangan'
        };
      case 'GENERAL_LABOUR':
        return {
          'label': isEn ? 'GENERAL LABOUR' : 'PEKERJA AM',
          'color': const Color(0xFF94A3B8),
          'desc': isEn ? 'Cable Pulling & Physical Support' : 'Tarik Kabel & Bantuan Fizikal'
        };
      case 'GENERAL_IT_ELV':
        return {
          'label': isEn ? 'ELV / CCTV (EE02)' : 'IT / CCTV (EE02)',
          'color': const Color(0xFF10B981),
          'desc': isEn ? 'CCTV Megapixel & Optical Network' : 'Pemasangan CCTV & Rangkaian'
        };
      case 'CERTIFIED_WIREMAN':
        return {
          'label': isEn ? 'WIREMAN (PW4/EE11)' : 'WIREMAN (PW4/EE11)',
          'color': const Color(0xFFF59E0B),
          'desc': isEn ? '3-Phase Low Voltage Commissioning' : 'Pepasangan Elektrik 3-Fasa'
        };
      case 'HIGH_RISK_SPECIALIST':
        return {
          'label': isEn ? 'STREETLIGHT (EE06)' : 'LAMPU JALAN (EE06)',
          'color': const Color(0xFFF43F5E),
          'desc': isEn ? 'Working At Height & Highway Skylift' : 'Kerja Di Tempat Tinggi & Skylift'
        };
      default:
        return {
          'label': isEn ? 'FIELD TECHNICIAN' : 'JURUTEKNIK',
          'color': const Color(0xFF10B981),
          'desc': isEn ? 'Site Operations' : 'Operasi Tapak'
        };
    }
  }

  @override
  Widget? buildTechnicianUI(BuildContext context) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;
    const String category = 'CERTIFIED_WIREMAN';
    final badge = getCategoryBadge(category, isEn);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badge['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (badge['color'] as Color).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: badge['color'] as Color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badge['label'] as String,
                      style: TextStyle(color: badge['color'] as Color, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isEn ? "ACCREDITED" : "DIPERAKUI",
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(badge['desc'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          const Divider(color: Color(0xFF1E293B), height: 16),
          Column(
            children: [
              _EnterpriseCertCard(
                agency: "CIDB / PEC COUNCIL",
                title: "Statutory License (Green Card / PEC)",
                id: "CIDB-980412-SEL / PEC-EE02",
                expiry: isEn ? "Valid: Dec 2027" : "Sah: Dis 2027",
                accentColor: const Color(0xFF10B981),
                icon: Icons.shield_rounded,
              ),
              const SizedBox(height: 6),
              _EnterpriseCertCard(
                agency: "ENERGY REGULATOR (ST / NEPRA)",
                title: "Competent Wireman / Engr Permit",
                id: "ST(PR)SEL-PW4 / NEPRA-4481",
                expiry: isEn ? "Valid: Jun 2028" : "Sah: Jun 2028",
                accentColor: const Color(0xFFF59E0B),
                icon: Icons.bolt_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildAdminUI(BuildContext context) {
    return const AdminCredentialsView();
  }
}

class AdminCredentialsView extends StatefulWidget {
  const AdminCredentialsView({super.key});

  @override
  State<AdminCredentialsView> createState() => _AdminCredentialsViewState();
}

class _AdminCredentialsViewState extends State<AdminCredentialsView> {
  final List<Map<String, dynamic>> _staffList = [
    {
      'id': 'EMP-01',
      'full_name': 'Ahmad Faizal Bin Razali',
      'nric': '880412-10-5421',
      'phone': '+60 12-345 6789',
      'country': 'MY',
      'category': 'CERTIFIED_WIREMAN',
      'designation': 'Senior Wireman Lead',
      'van_plate': 'WVG 8812 (HiAce)',
      'driving_license': 'D, GDL (Active)',
      'cert1_name': 'CIDB GREEN CARD',
      'cert1_no': 'CIDB-880412-SEL (Exp: Dec 2027)',
      'cert2_name': 'ST WIREMAN (PW4)',
      'cert2_no': 'ST(PR)SEL-2023-8891 (Exp: Jun 2028)',
      'skills': ['PW4 3-Phase', 'CCTV IP Megapixel', 'WAH Level 2'],
    },
    {
      'id': 'EMP-02',
      'full_name': 'Engr. M. Bilal Qureshi',
      'nric': '35201-8841920-3',
      'phone': '+92 300-445 6789',
      'country': 'PK',
      'category': 'GENERAL_IT_ELV',
      'designation': 'PEC Surveillance Lead (EE02)',
      'van_plate': 'LEA 8840 (Suzuki APV)',
      'driving_license': 'LTV / HTV Commercial',
      'cert1_name': 'PEC LICENSE (EE02)',
      'cert1_no': 'PEC-RE-COMP-44912 (Exp: 2028)',
      'cert2_name': 'NEPRA ELECTRICAL LIC',
      'cert2_no': 'NEPRA-DISCO-0992 (Exp: 2027)',
      'skills': ['SafeCity CCTV', 'Fiber OTDR', 'High-Mast Lux'],
    },
    {
      'id': 'EMP-03',
      'full_name': 'Lee Wei Kang',
      'nric': '961104-10-5573',
      'phone': '+60 16-332 1144',
      'country': 'MY',
      'category': 'GENERAL_IT_ELV',
      'designation': 'CCTV & Network Specialist',
      'van_plate': 'BQK 4410 (Nissan NV200)',
      'driving_license': 'D, GDL',
      'cert1_name': 'CIDB GREEN CARD',
      'cert1_no': 'CIDB-961104-SEL (Exp: Oct 2027)',
      'cert2_name': 'ELV COMPETENCY',
      'cert2_no': 'ELV-CISCO-CCNA-2026',
      'skills': ['IP CCTV', 'PoE Budgeting', 'Access Control'],
    },
  ];

  void _openEnterpriseStaffOnboardModal() {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    String selectedCountry = 'MY';
    String selectedCategory = 'CERTIFIED_WIREMAN';
    String selectedCompetency = 'PW4 Three-Phase Wireman';
    String drivingLicense = 'D + GDL (Goods Vehicle)';

    final nameController = TextEditingController();
    final idController = TextEditingController();
    final phoneController = TextEditingController();
    final designationController = TextEditingController();
    final baseSalaryController = TextEditingController(text: '3,800.00');
    final vanPlateController = TextEditingController(text: 'WVG 8812');
    final cert1Controller = TextEditingController();
    final cert2Controller = TextEditingController();
    final emergencyController = TextEditingController();

    final Set<String> activeSkills = {'CCTV IP Configuration', '3-Phase Power Commissioning'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070D18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 14,
                left: 16,
                right: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF10B981), size: 18),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? "ONBOARD FIELD TECHNICIAN DOSSIER" : "PENDAFTARAN DOSIER KAKITANGAN TAPAK",
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    isEn ? "Statutory Personnel Accreditations & Fleet Assignment" : "Pematuhan Lesen Berkanun & Agihan Kenderaan",
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 16),

                      // 1. Jurisdiction
                      const Text("1. REGIONAL JURISDICTION & NATIONAL IDENTITY", style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _subRadio('MY', 'Malaysia 🇲🇾 (MyKad / CIDB / ST)', selectedCountry, (c) {
                            setModalState(() {
                              selectedCountry = c;
                              selectedCompetency = 'PW4 Three-Phase Wireman';
                              drivingLicense = 'D + GDL (Goods Vehicle)';
                              baseSalaryController.text = '3,800.00';
                            });
                          }),
                          const SizedBox(width: 6),
                          _subRadio('PK', 'Pakistan 🇵🇰 (CNIC / PEC / NEPRA)', selectedCountry, (c) {
                            setModalState(() {
                              selectedCountry = c;
                              selectedCompetency = 'PEC Engineer (EE02/EE06)';
                              drivingLicense = 'LTV / Commercial';
                              baseSalaryController.text = '75,000.00';
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _field(
                        isEn ? "Full Legal Name (as per ID)" : "Nama Penuh (seperti Kad Pengenalan)",
                        selectedCountry == 'PK' ? "e.g. Engr. Hamza Farooq" : "e.g. Muhammad Daniel Bin Azhar",
                        nameController,
                        Icons.person_rounded,
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              selectedCountry == 'PK' ? "CNIC Number (13 Digits)" : "MyKad NRIC (12 Digits)",
                              selectedCountry == 'PK' ? "35201-8841920-1" : "940812-10-5811",
                              idController,
                              Icons.badge_rounded,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _field(
                              "Mobile Contact Tel",
                              selectedCountry == 'PK' ? "+92 300 445 6789" : "+60 12-345 6789",
                              phoneController,
                              Icons.phone_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 2. Regulatory Competency
                      Text(
                        "2. STATUTORY ACCREDITATION (${selectedCountry == 'PK' ? 'PEC & NEPRA' : 'CIDB MALAYSIA & SURUHANJAYA TENAGA'})",
                        style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Trade Discipline", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                  child: DropdownButton<String>(
                                    value: selectedCategory,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: const Color(0xFF161F30),
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                    items: const [
                                      DropdownMenuItem(value: 'CERTIFIED_WIREMAN', child: Text("Electrical Wireman (PW4/EE11)")),
                                      DropdownMenuItem(value: 'GENERAL_IT_ELV', child: Text("CCTV & ELV Specialist (EE02)")),
                                      DropdownMenuItem(value: 'HIGH_RISK_SPECIALIST', child: Text("Smart Streetlight (EE06)")),
                                      DropdownMenuItem(value: 'WAREHOUSE_STORE', child: Text("Van Store Logistics")),
                                      DropdownMenuItem(value: 'GENERAL_LABOUR', child: Text("General Site Labour")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedCategory = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedCountry == 'PK' ? "PEC / NEPRA Class" : "ST Competency Certificate", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF161F30), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF26324D))),
                                  child: DropdownButton<String>(
                                    value: selectedCompetency,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: const Color(0xFF161F30),
                                    style: const TextStyle(color: Colors.white, fontSize: 9),
                                    items: (selectedCountry == 'PK'
                                        ? ['PEC Engineer (EE02/EE06)', 'NEPRA Electrical Wireman', 'PEC Associate Engineer', 'Site Safety Inspector']
                                        : ['PW4 Three-Phase Wireman', 'PW2 Single-Phase Wireman', 'A4 Chargeman Low Voltage', 'B04 Chargeman High Voltage', 'CIDB General Personnel'])
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedCompetency = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              selectedCountry == 'PK' ? "PEC License / RE Number" : "CIDB Green Card Serial",
                              selectedCountry == 'PK' ? "PEC-RE-55412-B" : "CIDB-940812-SEL",
                              cert1Controller,
                              Icons.shield_rounded,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _field(
                              selectedCountry == 'PK' ? "NEPRA Competency Ref" : "ST Permit Serial Number",
                              selectedCountry == 'PK' ? "NEPRA-DISCO-4410" : "ST(PR)SEL-2023-8891",
                              cert2Controller,
                              Icons.bolt_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      const Text("Technical Authorizations & Site Badges:", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          'CCTV IP Configuration',
                          '3-Phase Power Commissioning',
                          'Fiber Splicing & OTDR',
                          'Working at Height (WAH)',
                          'Skylift / MEWP Certified',
                          'Substation Lockout-Tagout',
                        ].map((skill) {
                          final isSelected = activeSkills.contains(skill);
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                isSelected ? activeSkills.remove(skill) : activeSkills.add(skill);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFF030712),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF1E293B)),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // 3. Deployment & Fleet Logistics
                      const Text("3. FLEET LOGISTICS & EMERGENCY TELEMETRY", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(child: _field("Job Title", "e.g. Senior Wireman Lead", designationController, Icons.work_rounded)),
                          const SizedBox(width: 6),
                          Expanded(child: _field("Assigned Fleet Van", selectedCountry == 'PK' ? "LEA 8840 (Suzuki APV)" : "WVG 8812 (Toyota HiAce)", vanPlateController, Icons.airport_shuttle_rounded)),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              "Monthly Base (${selectedCountry == 'PK' ? 'PKR ₨' : 'RM'})",
                              "Salary",
                              baseSalaryController,
                              Icons.payments_rounded,
                              isNum: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: _field("Emergency Contact & Tel", "Siti Hajar (Isteri) 019-8765432", emergencyController, Icons.contact_emergency_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Final Submit Action
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.verified_user_rounded, color: Colors.black, size: 16),
                          label: Text(
                            "REGISTER ${selectedCountry == 'PK' ? 'PAKISTAN 🇵🇰' : 'MALAYSIA 🇲🇾'} EMPLOYEE DOSSIER",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10),
                          ),
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) return;

                            setState(() {
                              final newId = 'EMP-0${_staffList.length + 1}';
                              _staffList.insert(0, {
                                'id': newId,
                                'full_name': nameController.text.trim(),
                                'nric': idController.text.trim().isEmpty ? (selectedCountry == 'PK' ? '35201-9988112-1' : '950812-10-5811') : idController.text.trim(),
                                'phone': phoneController.text.trim().isEmpty ? '+60 12-000 0000' : phoneController.text.trim(),
                                'country': selectedCountry,
                                'category': selectedCategory,
                                'designation': designationController.text.trim().isEmpty ? 'Field Specialist' : designationController.text.trim(),
                                'van_plate': vanPlateController.text.trim().isEmpty ? 'Van Unit 01' : vanPlateController.text.trim(),
                                'driving_license': drivingLicense,
                                'cert1_name': selectedCountry == 'PK' ? 'PEC LICENSE (EE02)' : 'CIDB GREEN CARD',
                                'cert1_no': cert1Controller.text.trim().isEmpty ? 'CIDB-VALID-2027' : cert1Controller.text.trim(),
                                'cert2_name': selectedCountry == 'PK' ? 'NEPRA WIREMAN LIC' : 'ST WIREMAN (PW4)',
                                'cert2_no': cert2Controller.text.trim().isEmpty ? 'ST-PW4-ACTIVE' : cert2Controller.text.trim(),
                                'skills': activeSkills.toList(),
                              });
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Employee '${nameController.text}' dossier registered with $selectedCompetency!"),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _subRadio(String code, String label, String selected, Function(String) onSelect) {
    final bool isSelected = code == selected;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(code),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF161F30),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF26324D)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller, IconData icon, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 9),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 8),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 12),
            filled: true,
            fillColor: const Color(0xFF161F30),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF26324D))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF10B981))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = LocaleService.currentLanguage.value == AppLanguage.en;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _highlightCard(title: "100%", label: "CIDB / PEC", tag: "PASS", color: const Color(0xFF10B981), icon: Icons.verified_user_rounded),
            const SizedBox(width: 6),
            _highlightCard(title: "${_staffList.length} Techs", label: "Workforce", tag: "LIVE", color: const Color(0xFFF59E0B), icon: Icons.bolt_rounded),
            const SizedBox(width: 6),
            _highlightCard(title: "Grade A", label: "Audit", tag: "OK", color: const Color(0xFF0284C7), icon: Icons.analytics_rounded),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "WORKFORCE DOSSIER & ACCREDITATIONS",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(60, 26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 12, color: Color(0xFF030712)),
              label: Text(
                isEn ? "+ ONBOARD" : "+ DAFTAR",
                style: const TextStyle(color: Color(0xFF030712), fontSize: 8, fontWeight: FontWeight.w900),
              ),
              onPressed: _openEnterpriseStaffOnboardModal,
            ),
          ],
        ),
        const SizedBox(height: 8),

        ..._staffList.map((staff) {
          final badge = CredentialsModule.getCategoryBadge(staff['category'] ?? '', isEn);
          final String flag = staff['country'] == 'PK' ? '🇵🇰' : '🇲🇾';
          final List skills = (staff['skills'] as List?) ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (badge['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(flag, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  staff['full_name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (badge['color'] as Color).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  badge['label'] as String,
                                  style: TextStyle(color: badge['color'] as Color, fontSize: 6, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${staff['id']} • ID: ${staff['nric']} • ${staff['designation']}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                          ),
                          Text(
                            "Fleet: ${staff['van_plate']} • Tel: ${staff['phone']}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E293B), height: 10),

                if (skills.isNotEmpty) ...[
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: skills.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(s.toString(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 6, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff['cert1_name'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.w900)),
                            Text(staff['cert1_no'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 7, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: const Color(0xFF030712), borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff['cert2_name'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 7, fontWeight: FontWeight.w900)),
                            Text(staff['cert2_no'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 7, fontFamily: 'monospace')),
                          ],
                        ),
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

  Widget _highlightCard({
    required String title,
    required String label,
    required String tag,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                  child: Text(tag, style: TextStyle(color: color, fontSize: 5, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 6)),
          ],
        ),
      ),
    );
  }
}

class _EnterpriseCertCard extends StatelessWidget {
  final String agency;
  final String title;
  final String id;
  final String expiry;
  final Color accentColor;
  final IconData icon;

  const _EnterpriseCertCard({
    required this.agency,
    required this.title,
    required this.id,
    required this.expiry,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 10),
              const SizedBox(width: 4),
              Expanded(
                child: Text(agency, overflow: TextOverflow.ellipsis, style: TextStyle(color: accentColor, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          Text(id, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 8, fontFamily: 'monospace')),
          Text(expiry, style: const TextStyle(color: Color(0xFF10B981), fontSize: 7, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
