import 'package:flutter/material.dart';

enum BusinessActivityType {
  cctv,
  electrical,
  streetLighting,
  itSolutions,
}

class ActivityCheckItem {
  final String id;
  final String title;
  final String category;
  bool isChecked;
  String? valueOrNotes;

  ActivityCheckItem({
    required this.id,
    required this.title,
    required this.category,
    this.isChecked = false,
    this.valueOrNotes,
  });
}

class BusinessActivity {
  final BusinessActivityType type;
  final String title;
  final String code;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> technicalStandards;
  final List<ActivityCheckItem> inspectionItems;
  final List<String> defaultMaterials;

  const BusinessActivity({
    required this.type,
    required this.title,
    required this.code,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.technicalStandards,
    required this.inspectionItems,
    required this.defaultMaterials,
  });

  static List<BusinessActivity> getCategories() => [
    BusinessActivity(
      type: BusinessActivityType.cctv,
      title: 'Surveillance & CCTV',
      code: 'ACT-CCTV',
      description: 'IP Cameras, NVR/PoE Switches, DarkFighter, PTZ Alignment',
      icon: Icons.videocam_rounded,
      accentColor: const Color(0xFF38BDF8),
      technicalStandards: ['ONVIF Profile S/G/T', 'PoE 802.3at/bt (30W/60W)', 'RTSP H.265+ Stream'],
      inspectionItems: [
        ActivityCheckItem(id: 'c1', title: 'Mounting & Alignment', category: 'CCTV'),
        ActivityCheckItem(id: 'c2', title: 'IP Scheme & Subnet Mask Assigned', category: 'CCTV'),
        ActivityCheckItem(id: 'c3', title: 'Optical IR & Focus Calibration', category: 'CCTV'),
        ActivityCheckItem(id: 'c4', title: 'Motion Detection & NVR Storage Lock', category: 'CCTV'),
      ],
      defaultMaterials: ['Cat6 STP Cable', 'Toolless RJ45 Jacks', 'PoE Switch 16-Port', 'Weatherproof Enclosure'],
    ),
    BusinessActivity(
      type: BusinessActivityType.electrical,
      title: 'Electrical & Power',
      code: 'ACT-ELEC',
      description: '3-Phase Switchboards, Earthing Pit, Breakers & Sizing',
      icon: Icons.bolt_rounded,
      accentColor: const Color(0xFFF59E0B),
      technicalStandards: ['Suruhanjaya Tenaga / NEPRA', 'IEC 60364 Standards', 'Insulation > 1.0 MΩ'],
      inspectionItems: [
        ActivityCheckItem(id: 'e1', title: 'Phase Balancing (Red/Yellow/Blue)', category: 'Electrical'),
        ActivityCheckItem(id: 'e2', title: 'Earth Resistance Test (< 1.0 Ω)', category: 'Electrical'),
        ActivityCheckItem(id: 'e3', title: 'Insulation Resistance (500V DC Megger)', category: 'Electrical'),
        ActivityCheckItem(id: 'e4', title: 'MCB / ELCB Trip & Torque Check', category: 'Electrical'),
      ],
      defaultMaterials: ['Armoured 4C x 16mm²', 'MCB 16A/32A Type C', 'Copper Earth Tape', 'Contactor 40A'],
    ),
    BusinessActivity(
      type: BusinessActivityType.streetLighting,
      title: 'Smart Street Lighting',
      code: 'ACT-LGHT',
      description: 'Octagonal Poles, High-Mast, LED Drivers & Astro-Timers',
      icon: Icons.wb_incandescent_rounded,
      accentColor: const Color(0xFF10B981),
      technicalStandards: ['IP66/IP67 Ingress', 'Surge Protection 10kV', 'ANSI C136.41 7-Pin NEMA'],
      inspectionItems: [
        ActivityCheckItem(id: 'l1', title: 'Luminaire Angle & Tilt Calibration', category: 'Lighting'),
        ActivityCheckItem(id: 'l2', title: 'LED Driver Current & Thermal Load', category: 'Lighting'),
        ActivityCheckItem(id: 'l3', title: 'Photocell & Astro-Timer Sequencing', category: 'Lighting'),
        ActivityCheckItem(id: 'l4', title: 'Feeder Pillar Loop Impedance (< 0.8Ω)', category: 'Lighting'),
      ],
      defaultMaterials: ['150W LED Luminaire', '7-Pin NEMA Photocell', 'Cut-Out Fuse 16A', 'Cast-Resin Joint Kit'],
    ),
    BusinessActivity(
      type: BusinessActivityType.itSolutions,
      title: 'IT & Smart Solutions',
      code: 'ACT-ITNT',
      description: 'Fiber Splicing, Managed Switches (Moxa/Cisco), IoT Gateways',
      icon: Icons.router_rounded,
      accentColor: const Color(0xFFA855F7),
      technicalStandards: ['TIA-568-C.3 Fiber Specs', 'VLAN 802.1Q Segregation', 'TLS 1.3 Encryption'],
      inspectionItems: [
        ActivityCheckItem(id: 'i1', title: 'Core Fusion Splicing (< 0.05dB Loss)', category: 'IT/Network'),
        ActivityCheckItem(id: 'i2', title: 'Industrial Switch Port & VLAN Map', category: 'IT/Network'),
        ActivityCheckItem(id: 'i3', title: 'Server Rack Cable Lacing & Patching', category: 'IT/Network'),
        ActivityCheckItem(id: 'i4', title: 'IoT Edge Gateway Ping & Packet Drop', category: 'IT/Network'),
      ],
      defaultMaterials: ['Single-Mode Pigtails', 'Cat6A Patch Panel', 'SFP Transceiver 1.25G', 'Industrial 24V PSU'],
    ),
  ];
}
