import 'package:flutter/material.dart';
import '../models/user_session.dart';

class LoginScreen extends StatefulWidget {
  final Function(UserSession) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'superadmin@fieldops.my');

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _loginAs(String role, String tenantId, String companyName, String name, String tier) {
    final session = UserSession(
      id: 'usr_${role.toLowerCase()}',
      token: 'jwt_${role.toLowerCase()}_token_2026',
      name: name,
      email: _emailController.text,
      role: role,
      tenantId: tenantId,
      companyName: companyName,
      planTier: tier,
    );
    widget.onLoginSuccess(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_rounded, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 6),
                        Text(
                          "MULTI-TENANT MOTHERBOARD ENGINE",
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "FIELDOPS ENTERPRISE",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Unified B2B Platform for Contractors, Utilities & ELV Infrastructure",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SELECT RUNTIME ROLE (3-TIER ARCHITECTURE):",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 12),
                      _roleButton(
                        title: "1. SUPER ADMIN (SaaS Platform Owner)",
                        subtitle: "Manage subscriber tenants, global licenses, MRR & modules",
                        icon: Icons.shield_rounded,
                        color: const Color(0xFFA855F7),
                        onTap: () => _loginAs('SUPERADMIN', 'SYSTEM_PLATFORM', 'FieldOps Central HQ', 'System Chief Architect', 'PLATFORM_ROOT'),
                      ),
                      const SizedBox(height: 8),
                      _roleButton(
                        title: "2. TENANT ADMIN (Company Ops Manager)",
                        subtitle: "Manage AlphaTech company staff, van inventory & job tickets",
                        icon: Icons.admin_panel_settings_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => _loginAs('ADMIN', 'tenant_alphatec_01', 'AlphaTech Networks Sdn Bhd', 'Hazwan Ops Lead', 'ENTERPRISE'),
                      ),
                      const SizedBox(height: 8),
                      _roleButton(
                        title: "3. FIELD TECHNICIAN (On-Site Specialist)",
                        subtitle: "Mobile check-in, zero-pricing van stock & checklist execution",
                        icon: Icons.engineering_rounded,
                        color: const Color(0xFF0284C7),
                        onTap: () => _loginAs('TECHNICIAN', 'tenant_alphatec_01', 'AlphaTech Networks Sdn Bhd', 'Ahmad Faizal Bin Razali', 'ENTERPRISE'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF030712),
          borderRadius: BorderRadius.circular(12),
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
                  Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF475569), size: 14),
          ],
        ),
      ),
    );
  }
}
