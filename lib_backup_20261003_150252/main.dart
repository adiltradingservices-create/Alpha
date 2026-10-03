import 'services/central_operations_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/module_registry.dart';
import 'models/user_session.dart';
import 'modules/credentials/credentials_module.dart';
import 'modules/biometrics/biometrics_module.dart';
import 'modules/van_warehouse/van_warehouse_module.dart';
import 'modules/testing_commissioning/testing_commissioning_module.dart';
import 'modules/endorsement/endorsement_module.dart';
import 'shell/super_admin_shell.dart';
import 'shell/admin_shell.dart';
import 'shell/technician_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CentralOperationsStore().initPersistence();
  runApp(const FieldOpsApp());
}

class FieldOpsApp extends StatelessWidget {
  const FieldOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final registry = ModuleRegistry();
        registry.registerModule(CredentialsModule());
        registry.registerModule(BiometricsModule());
        registry.registerModule(VanWarehouseModule());
        registry.registerModule(TestingCommissioningModule());
        registry.registerModule(EndorsementModule());
        return registry;
      },
      child: MaterialApp(
        title: 'FieldOps Enterprise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF030712),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            secondary: Color(0xFF38BDF8),
            surface: Color(0xFF0B132B),
          ),
          fontFamily: 'Roboto',
        ),
        home: const AppRootRouter(),
      ),
    );
  }
}

class AppRootRouter extends StatefulWidget {
  const AppRootRouter({super.key});

  @override
  State<AppRootRouter> createState() => _AppRootRouterState();
}

class _AppRootRouterState extends State<AppRootRouter> {
  UserSession? _currentSession;

  @override
  Widget build(BuildContext context) {
    if (_currentSession == null) {
      return _RoleSelectionScreen(
        onSelectSession: (session) {
          setState(() => _currentSession = session);
        },
      );
    }

    switch (_currentSession!.role) {
      case 'SUPER_ADMIN':
        return SuperAdminShell(
          session: _currentSession!,
          onImpersonateCompany: (impersonatedSession) {
            setState(() => _currentSession = impersonatedSession);
          },
          onLogout: () => setState(() => _currentSession = null),
        );
      case 'ADMIN':
        return AdminShell(
          session: _currentSession!,
          onLogout: () => setState(() => _currentSession = null),
        );
      case 'TECHNICIAN':
      default:
        return TechnicianShell(
          session: _currentSession!,
          onLogout: () => setState(() => _currentSession = null),
        );
    }
  }
}

class _RoleSelectionScreen extends StatelessWidget {
  final Function(UserSession) onSelectSession;

  const _RoleSelectionScreen({required this.onSelectSession});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0284C7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 36, color: Colors.black),
                ),
                const SizedBox(height: 16),
                const Text(
                  "FIELDOPS ENTERPRISE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Malaysia 🇲🇾 • Pakistan 🇵🇰 • Global 🌐",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 28),

                // 1. Super Admin Role
                _portalCard(
                  title: "SUPER ADMIN PLATFORM ROOT",
                  subtitle: "Global Multi-Tenant Governance & Licensing",
                  badge: "ROOT ACCESS",
                  color: const Color(0xFFA855F7),
                  icon: Icons.public_rounded,
                  onTap: () {
                    onSelectSession(const UserSession(
                      id: 'usr_super_01',
                      token: 'jwt_root_token',
                      name: 'Global Platform Admin',
                      email: 'root@fieldops.io',
                      role: 'SUPER_ADMIN',
                      tenantId: 'system_root',
                      companyName: 'FieldOps Cloud Infrastructure',
                      planTier: 'PLATFORM_OWNER',
                      countryCode: 'GLOBAL',
                      currencySymbol: 'USD',
                      regulatoryBody: 'ISO 27001 / SOC 2',
                      taxEngine: 'Global Multi-Engine',
                    ));
                  },
                ),
                const SizedBox(height: 12),

                // 2. Malaysia Tenant Admin
                _portalCard(
                  title: "TENANT COMMAND: MALAYSIA 🇲🇾",
                  subtitle: "AlphaTech Networks • CIDB G7 & ST (PW4) • RM",
                  badge: "COMPANY ADMIN",
                  color: const Color(0xFF10B981),
                  icon: Icons.admin_panel_settings_rounded,
                  onTap: () {
                    onSelectSession(const UserSession(
                      id: 'usr_director_my',
                      token: 'jwt_admin_my',
                      name: 'Ir. Hazwan Bin Roslan',
                      email: 'director@alphatec.my',
                      role: 'ADMIN',
                      tenantId: 'tenant_alphatec_01',
                      companyName: 'AlphaTech Networks Sdn Bhd',
                      planTier: 'ENTERPRISE SUITE',
                      countryCode: 'MY',
                      currencySymbol: 'RM',
                      regulatoryBody: 'CIDB G7 & ST',
                      taxEngine: 'LHDN MyInvois (SST 8%)',
                    ));
                  },
                ),
                const SizedBox(height: 12),

                // 3. Pakistan Tenant Admin
                _portalCard(
                  title: "TENANT COMMAND: PAKISTAN 🇵🇰",
                  subtitle: "Lahore Smart Surveillance • PEC C-3 (EE02/EE06) • PKR ₨",
                  badge: "COMPANY ADMIN",
                  color: const Color(0xFF38BDF8),
                  icon: Icons.business_rounded,
                  onTap: () {
                    onSelectSession(const UserSession(
                      id: 'usr_director_pk',
                      token: 'jwt_admin_pk',
                      name: 'Engr. M. Usman Tariq',
                      email: 'director@safecity.pk',
                      role: 'ADMIN',
                      tenantId: 'tenant_lahore_cctv_02',
                      companyName: 'Lahore Smart Surveillance & Infra Ltd',
                      planTier: 'ENTERPRISE SUITE',
                      countryCode: 'PK',
                      currencySymbol: 'PKR ₨',
                      regulatoryBody: 'PEC & NEPRA (EE02/EE06)',
                      taxEngine: 'FBR Digital Invoicing (PRA/SRB)',
                    ));
                  },
                ),
                const SizedBox(height: 12),

                // 4. Technician Shell
                _portalCard(
                  title: "FIELD TECHNICIAN WORKSPACE",
                  subtitle: "Ahmad Faizal (ST PW4) • Touch Sign-off & Offline Sync",
                  badge: "ON-DEVICE ML",
                  color: const Color(0xFFF59E0B),
                  icon: Icons.engineering_rounded,
                  onTap: () {
                    onSelectSession(const UserSession(
                      id: 'usr_tech_01',
                      token: 'jwt_tech_token',
                      name: 'Ahmad Faizal Bin Razali',
                      email: 'faizal@alphatec.my',
                      role: 'TECHNICIAN',
                      tenantId: 'tenant_alphatec_01',
                      companyName: 'AlphaTech Networks Sdn Bhd',
                      planTier: 'ENTERPRISE SUITE',
                      countryCode: 'MY',
                      currencySymbol: 'RM',
                      regulatoryBody: 'CIDB & ST (PW4)',
                      taxEngine: 'LHDN MyInvois',
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _portalCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




