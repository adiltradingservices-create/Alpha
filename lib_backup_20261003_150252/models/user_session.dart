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
  final String currencySymbol; // 'RM', 'PKR ₨', '$'
  final String regulatoryBody; // 'CIDB & ST', 'PEC & NEPRA', 'GLOBAL'
  final String taxEngine; // 'LHDN MyInvois', 'FBR Digital Invoicing', 'VAT'

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
  });
}
