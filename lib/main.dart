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
  UserSession? _currentSession = const UserSession(
    id: 'TENANT-ADMIN-DEMO',
    token: 'TOKEN-ADMIN-DEMO',
    name: 'Adil Javed (HQ Admin)',
    email: 'admin@fieldops.io',
    role: 'ADMIN',
    tenantId: 'TENANT-MY-001',
    companyName: 'Adil Trading Services',
    planTier: 'ENTERPRISE',
    countryCode: 'MY',
    currencySymbol: 'RM ',
  );
  
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
    final store = CentralOperationsStore();

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final clients = store.clients;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 36),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    "FIELDOPS ENTERPRISE",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    "Modular Global SaaS ERP Platform",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 28),

                // 1. Root Super Admin Access
                _portalCard(
                  title: "SUPER ADMIN PLATFORM ROOT",
                  subtitle: "Global Multi-Tenant Governance & Licensing",
                  badge: "ROOT ACCESS",
                  badgeColor: const Color(0xFF818CF8),
                  icon: Icons.shield_rounded,
                  iconBg: const Color(0xFF312E81),
                  onTap: () {
                    onSelectSession(
                      const UserSession(
                        id: 'ROOT-SUPER-ADMIN',
                        token: 'SUPER-TOKEN-001',
                        name: 'Global Platform Director',
                        email: 'root@fieldops.io',
                        role: 'SUPER_ADMIN',
                        tenantId: 'PLATFORM-ROOT',
                        companyName: 'FieldOps Global Cloud',
                        planTier: 'ENTERPRISE_ROOT',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 2. Dynamic Client Tenant Cards from CentralOperationsStore
                ...clients.map((c) {
                  final isPk = c.countryCode == 'PK';
                  final isSg = c.countryCode == 'SG';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _portalCard(
                      title: "TENANT COMMAND: [${c.countryCode}] ${c.companyName}",
                      subtitle: "Reg: ${isPk ? 'PEC & NEPRA' : (isSg ? 'BCA & EMA' : 'CIDB & ST')} � Currency: ${c.currency}",
                      badge: c.tier.name.toUpperCase().replaceAll('_', ' '),
                      badgeColor: const Color(0xFF10B981),
                      icon: Icons.apartment_rounded,
                      iconBg: const Color(0xFF064E3B),
                      onTap: () {
                        store.updateConfig(
                          name: c.companyName,
                          biometrics: c.enableBiometrics,
                          vanStores: c.enableVanStores,
                          testing: c.enableTestingCommissioning,
                          signOff: c.enableClientEndorsement,
                        );

                        onSelectSession(
                          UserSession(
                            id: "TENANT-ADMIN-${c.tenantId}",
                            token: "TOKEN-${c.tenantId}",
                            name: "${c.companyName} Admin",
                            email: c.contactEmail,
                            role: 'ADMIN',
                            tenantId: c.tenantId,
                            companyName: c.companyName,
                            planTier: c.tier.name.toUpperCase(),
                            countryCode: c.countryCode,
                            currencySymbol: isPk ? 'PKR ' : (isSg ? 'SGD' : 'RM'),
                            regulatoryBody: isPk ? 'PEC & NEPRA' : (isSg ? 'BCA / EMA' : 'CIDB & ST'),
                            taxEngine: isPk ? 'FBR Digital (18%)' : (isSg ? 'IRAS GST (9%)' : 'LHDN MyInvois (SST 8%)'),
                            taxRate: isPk ? 0.18 : (isSg ? 0.09 : 0.08),
                          ),
                        );
                      },
                    ),
                  );
                }),

                // 3. Technician Workspace
                _portalCard(
                  title: "FIELD TECHNICIAN WORKSPACE",
                  subtitle: "Active Dispatch Target � QR Scanner & Photo Docket",
                  badge: "FIELD APP",
                  badgeColor: const Color(0xFFF59E0B),
                  icon: Icons.engineering_rounded,
                  iconBg: const Color(0xFF78350F),
                  onTap: () {
                    final firstClient = clients.first;
                    onSelectSession(
                      UserSession(
                        id: 'TECH-101',
                        token: 'TECH-TOKEN-101',
                        name: 'Ahmad Faizal (ST PW4)',
                        email: 'ahmad.tech@fieldops.io',
                        role: 'TECHNICIAN',
                        tenantId: firstClient.tenantId,
                        companyName: firstClient.companyName,
                        planTier: firstClient.tier.name.toUpperCase(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _portalCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
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
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(color: badgeColor, fontSize: 6.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5),
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
