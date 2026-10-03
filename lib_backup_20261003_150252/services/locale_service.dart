import 'package:flutter/material.dart';

enum AppLanguage { en, ms }

class LocaleService {
  static final ValueNotifier<AppLanguage> currentLanguage = ValueNotifier(AppLanguage.en);

  static void toggleLanguage() {
    currentLanguage.value = currentLanguage.value == AppLanguage.ms 
        ? AppLanguage.en 
        : AppLanguage.ms;
  }

  static void setLanguage(AppLanguage lang) {
    currentLanguage.value = lang;
  }

  static String tr(String key) {
    final lang = currentLanguage.value;
    return _translations[key]?[lang] ?? key;
  }

  static final Map<String, Map<AppLanguage, String>> _translations = {
    // Auth & General
    'compliance_badge': {
      AppLanguage.ms: 'Platform Diperakui LHDN MyInvois & DOSH',
      AppLanguage.en: 'LHDN MyInvois & DOSH Certified Platform',
    },
    'app_sub': {
      AppLanguage.ms: 'SaaS Operasi Tapak, Inventori & E-Invois Berkanun',
      AppLanguage.en: 'Field Operations, Inventory & Statutory E-Invoicing SaaS',
    },
    'email_label': {
      AppLanguage.ms: 'Identiti Emel Syarikat',
      AppLanguage.en: 'Corporate Email Identity',
    },
    'password_label': {
      AppLanguage.ms: 'Kata Laluan Keselamatan',
      AppLanguage.en: 'Security Password',
    },
    'login_btn': {
      AppLanguage.ms: 'LOG MASUK RUANG KERJA',
      AppLanguage.en: 'LOGIN TO WORKSPACE',
    },
    'demo_roles': {
      AppLanguage.ms: 'PERANAN UJIAN CEPAT (DEMO)',
      AppLanguage.en: 'QUICK DEMO ROLES',
    },
    'role_tech': {
      AppLanguage.ms: 'Juruteknik Tapak',
      AppLanguage.en: 'Field Technician',
    },
    'role_admin': {
      AppLanguage.ms: 'Panel Pentadbir',
      AppLanguage.en: 'Admin Panel',
    },
    'compliance_footer': {
      AppLanguage.ms: 'Pematuhan Lembaga Hasil Dalam Negeri (LHDN) • SST 8%',
      AppLanguage.en: 'Inland Revenue Board (LHDN) Compliance • SST 8%',
    },

    // Shell & Admin
    'ops_center': {
      AppLanguage.ms: 'Pusat Kawalan Operasi',
      AppLanguage.en: 'Operations Command Center',
    },
    'total_billing': {
      AppLanguage.ms: 'Jumlah Pengebilan',
      AppLanguage.en: 'Total Billed Amount',
    },
    'site_orders': {
      AppLanguage.ms: 'Pesanan Tapak',
      AppLanguage.en: 'Field Work Orders',
    },
    'recent_audits': {
      AppLanguage.ms: 'AUDIT TUGASAN TAPAK TERKINI',
      AppLanguage.en: 'RECENT FIELD DISPATCH AUDITS',
    },
    'verified_badge': {
      AppLanguage.ms: 'DISAHKAN',
      AppLanguage.en: 'VERIFIED',
    },
    'no_jobs': {
      AppLanguage.ms: 'Tiada tugasan tapak direkodkan setakat ini.',
      AppLanguage.en: 'No field jobs recorded so far.',
    },
    'view_pdf': {
      AppLanguage.ms: 'Lihat Invois PDF',
      AppLanguage.en: 'View PDF Invoice',
    },
    'dynamic_modules': {
      AppLanguage.ms: 'DAFTAR MODUL DINAMIK (PELAN SAAS)',
      AppLanguage.en: 'DYNAMIC MODULE REGISTRY (SAAS TIERS)',
    },
    'active_badge': {
      AppLanguage.ms: 'AKTIF',
      AppLanguage.en: 'ACTIVE',
    },
    'no_active_modules': {
      AppLanguage.ms: 'Tiada modul aktif untuk juruteknik ini.',
      AppLanguage.en: 'No active modules for this technician profile.',
    },

    // Bottom Action Button
    'submit_audit': {
      AppLanguage.ms: 'SELESAI & HANTAR AUDIT SHIFT',
      AppLanguage.en: 'COMPLETE SHIFT & LOG TELEMETRY',
    },

    // Credentials Module & Badges
    'active_status': {
      AppLanguage.ms: 'STATUS AKTIF',
      AppLanguage.en: 'ACTIVE STATUS',
    },
    'cred_module_title': {
      AppLanguage.ms: 'PROFIL PEKERJA & KELAYAKAN (CIDB / ST)',
      AppLanguage.en: 'WORKFORCE DOSSIER & STATUTORY CERTS (CIDB / ST)',
    },
    'staff_directory': {
      AppLanguage.ms: 'DIREKTORI PEKERJA & KELAYAKAN TAPAK',
      AppLanguage.en: 'WORKFORCE DIRECTORY & COMPLIANCE LEDGER',
    },
    'register_staff': {
      AppLanguage.ms: 'DAFTAR STAF',
      AppLanguage.en: 'REGISTER STAFF',
    },
    'search_staff_hint': {
      AppLanguage.ms: 'Cari nama, No. IC, ID staf...',
      AppLanguage.en: 'Search name, IC, staff ID...',
    },
    'filter_all': {
      AppLanguage.ms: 'Semua',
      AppLanguage.en: 'All',
    },
    'register_new_staff': {
      AppLanguage.ms: 'PENDAFTARAN PROFIL PEKERJA LENGKAP',
      AppLanguage.en: 'REGISTER NEW WORKER DOSSIER',
    },
    'update_staff': {
      AppLanguage.ms: 'KEMASKINI DOSIER KAKITANGAN',
      AppLanguage.en: 'UPDATE WORKER DOSSIER',
    },
    'confirm_register': {
      AppLanguage.ms: 'SAHKAN & DAFTAR DOSIER PEKERJA',
      AppLanguage.en: 'VERIFY & REGISTER DOSSIER',
    },
    'confirm_update': {
      AppLanguage.ms: 'KEMASKINI DOSIER LENGKAP',
      AppLanguage.en: 'UPDATE DOSSIER',
    },
  };
}
