class UserSession {
  final String id;
  final String token;
  final String name;
  final String email;
  final String role; // 'SUPER_ADMIN', 'ADMIN', 'TECHNICIAN'
  final String tenantId;
  final String companyName;
  final String planTier;
  final String countryCode; // 'MY', 'PK', 'GLOBAL'
  final String currencySymbol; // 'RM', 'PKR ₨', 'USD'
  final String regulatoryBody; // 'CIDB & ST', 'PEC & NEPRA', 'GLOBAL/IEC'
  final String taxEngine; // 'LHDN MyInvois (SST 8%)', 'FBR Digital (18%)', 'Standard VAT'
  final double taxRate; // 0.08, 0.18, 0.10

  const UserSession({
    required this.id,
    required this.token,
    required this.name,
    required this.email,
    required this.role,
    required this.tenantId,
    required this.companyName,
    required this.planTier,
    this.countryCode = 'MY',
    this.currencySymbol = 'RM',
    this.regulatoryBody = 'CIDB & ST',
    this.taxEngine = 'LHDN MyInvois (SST 8%)',
    this.taxRate = 0.08,
  });

  factory UserSession.forRegion({
    required String id,
    required String token,
    required String name,
    required String email,
    required String role,
    required String tenantId,
    required String companyName,
    required String planTier,
    required String countryCode,
  }) {
    switch (countryCode.toUpperCase()) {
      case 'PK':
        return UserSession(
          id: id,
          token: token,
          name: name,
          email: email,
          role: role,
          tenantId: tenantId,
          companyName: companyName,
          planTier: planTier,
          countryCode: 'PK',
          currencySymbol: 'PKR ₨',
          regulatoryBody: 'PEC & NEPRA Code',
          taxEngine: 'FBR Digital Invoicing (18%)',
          taxRate: 0.18,
        );
      case 'GLOBAL':
        return UserSession(
          id: id,
          token: token,
          name: name,
          email: email,
          role: role,
          tenantId: tenantId,
          companyName: companyName,
          planTier: planTier,
          countryCode: 'GLOBAL',
          currencySymbol: 'USD',
          regulatoryBody: 'IEC / ISO Standards',
          taxEngine: 'Standard VAT (10%)',
          taxRate: 0.10,
        );
      case 'MY':
      default:
        return UserSession(
          id: id,
          token: token,
          name: name,
          email: email,
          role: role,
          tenantId: tenantId,
          companyName: companyName,
          planTier: planTier,
          countryCode: 'MY',
          currencySymbol: 'RM',
          regulatoryBody: 'CIDB & Suruhanjaya Tenaga',
          taxEngine: 'LHDN MyInvois (SST 8%)',
          taxRate: 0.08,
        );
    }
  }
}
