import 'business_activity.dart';

class CustomerProject {
  final String customerId;
  final String customerName;
  final String projectCode;
  final String projectName;
  final String siteAddress;
  final String clientPicName;
  final String clientPicPhone;
  final List<BusinessActivityType> contractedActivities;

  const CustomerProject({
    required this.customerId,
    required this.customerName,
    required this.projectCode,
    required this.projectName,
    required this.siteAddress,
    required this.clientPicName,
    required this.clientPicPhone,
    required this.contractedActivities,
  });

  static List<CustomerProject> getMockProjects(String countryCode) {
    if (countryCode == 'PK') {
      return const [
        CustomerProject(
          customerId: 'CUST-PK-01',
          customerName: 'Punjab Safe Cities Authority (PSCA)',
          projectCode: 'PSCA-LHR-2026',
          projectName: 'Lahore SafeCity Surveillance Phase 4',
          siteAddress: 'Junction Gantry 14-B, Ferozepur Road, Lahore',
          clientPicName: 'Engr. Tariq Mehmood (Project Director)',
          clientPicPhone: '+923004456789',
          contractedActivities: [
            BusinessActivityType.cctv,
            BusinessActivityType.itSolutions,
          ],
        ),
        CustomerProject(
          customerId: 'CUST-PK-02',
          customerName: 'Capital Development Authority (CDA)',
          projectCode: 'CDA-ISB-881',
          projectName: 'Kashmir Highway Smart Lighting & Power',
          siteAddress: 'Sector G-9 Interchanges Feeder Pillar #4',
          clientPicName: 'Malik Zeeshan (Executive Engineer)',
          clientPicPhone: '+923335567890',
          contractedActivities: [
            BusinessActivityType.electrical,
            BusinessActivityType.streetLighting,
          ],
        ),
      ];
    }

    return const [
      CustomerProject(
        customerId: 'CUST-MY-01',
        customerName: 'Apex Infra Properties Sdn Bhd',
        projectCode: 'AIP-PRJ-2026-08',
        projectName: 'Menara Apex Integrated Surveillance Overhaul',
        siteAddress: 'Level B2 Server Room & Perimeter Gantry, Puchong',
        clientPicName: 'Ir. Farhan Malik (Resident Engineer)',
        clientPicPhone: '+601126448678',
        contractedActivities: [
          BusinessActivityType.cctv,
          BusinessActivityType.electrical,
          BusinessActivityType.itSolutions,
        ],
      ),
      CustomerProject(
        customerId: 'CUST-MY-02',
        customerName: 'Majlis Bandaraya Shah Alam (MBSA)',
        projectCode: 'MBSA-SL-994',
        projectName: 'Persiaran Smart Streetlight LED Replacement',
        siteAddress: 'Persiaran Kayangan Substation Pillar 12, Shah Alam',
        clientPicName: 'En. Razak Osman (Penolong Jurutera)',
        clientPicPhone: '+60123456789',
        contractedActivities: [
          BusinessActivityType.streetLighting,
          BusinessActivityType.electrical,
        ],
      ),
    ];
  }
}
