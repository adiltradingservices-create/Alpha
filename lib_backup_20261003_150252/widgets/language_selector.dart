import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/locale_service.dart';

class LanguageSelector extends StatelessWidget {
  final bool isCompact;
  const LanguageSelector({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.currentLanguage,
      builder: (context, current, _) {
        if (isCompact) {
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              LocaleService.toggleLanguage();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    current == AppLanguage.ms ? 'BM' : 'EN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPill(
                label: 'Bahasa Melayu',
                flag: '🇲🇾',
                isSelected: current == AppLanguage.ms,
                onTap: () {
                  HapticFeedback.selectionClick();
                  LocaleService.setLanguage(AppLanguage.ms);
                },
              ),
              const SizedBox(width: 4),
              _buildPill(
                label: 'English',
                flag: '🇬🇧',
                isSelected: current == AppLanguage.en,
                onTap: () {
                  HapticFeedback.selectionClick();
                  LocaleService.setLanguage(AppLanguage.en);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill({
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF030712) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}