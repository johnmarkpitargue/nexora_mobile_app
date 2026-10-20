import 'package:flutter/material.dart';
import '../theme/rider_theme.dart';

class GuessResult {
  final String reason;
  final String suggestion;

  const GuessResult({required this.reason, required this.suggestion});
}

class ErrorGuessTile extends StatelessWidget {
  final String reason;
  final String suggestion;
  final VoidCallback? onApply;

  const ErrorGuessTile({
    super.key,
    required this.reason,
    required this.suggestion,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // soft amber warning background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                    fontFamily: RiderTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 1),
                RichText(
                  text: TextSpan(
                    text: 'Did you mean: ',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF78350F),
                      fontFamily: RiderTheme.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: suggestion,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Static Error Guessing Helpers ---

  static GuessResult? guessPhone(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return null;

    // Case 1: Pasted with +63
    if (raw.startsWith('+63')) {
      var clean = raw.substring(3).trim();
      if (clean.startsWith('0')) clean = clean.substring(1).trim();
      if (clean.isNotEmpty) {
        return GuessResult(
          reason: 'Duplicate country code detected (+63 already included)',
          suggestion: clean,
        );
      }
    }

    // Case 2: Pasted with 63 without plus
    if (raw.startsWith('63') && raw.length > 10) {
      var clean = raw.substring(2).trim();
      if (clean.startsWith('0')) clean = clean.substring(1).trim();
      if (clean.isNotEmpty) {
        return GuessResult(
          reason: 'Country code 63 detected (+63 already included)',
          suggestion: clean,
        );
      }
    }

    // Case 3: Leading 0 entered (e.g. 0917 123 4567)
    if (raw.startsWith('0')) {
      final clean = raw.substring(1).trim();
      if (clean.isNotEmpty) {
        return GuessResult(
          reason: 'Leading "0" detected (omit 0 when using +63)',
          suggestion: clean,
        );
      }
    }

    // Case 4: Raw 10 digits without spacing
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10 && !raw.contains(' ')) {
      final formatted =
          '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
      return GuessResult(
        reason: 'Format as readable PH mobile number',
        suggestion: formatted,
      );
    }

    return null;
  }

  static GuessResult? guessName(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return null;

    // Case 1: Unintended digits in legal name
    if (RegExp(r'[0-9]').hasMatch(raw)) {
      final clean = raw.replaceAll(RegExp(r'[0-9]'), '').trim();
      if (clean.isNotEmpty && clean != raw) {
        return GuessResult(
          reason: 'Unintended numbers detected in legal name',
          suggestion: clean,
        );
      }
    }

    // Case 2: Lowercase words
    final words = raw.split(RegExp(r'\s+'));
    bool hasLower = false;
    final capitalized = words.map((w) {
      if (w.isEmpty) return '';
      if (w[0] != w[0].toUpperCase()) hasLower = true;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    if (hasLower && capitalized.trim().isNotEmpty && capitalized != raw) {
      return GuessResult(
        reason: 'Legal names should be capitalized',
        suggestion: capitalized,
      );
    }

    return null;
  }

  static GuessResult? guessPlate(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return null;

    // Case 1: Motorcycle plate without hyphen (e.g. 138NXR or 138nxr or 138 NXR)
    final mcRegex = RegExp(r'^(\d{3})\s*([A-Za-z]{3})$');
    if (mcRegex.hasMatch(raw)) {
      final match = mcRegex.firstMatch(raw)!;
      return GuessResult(
        reason: 'Standard Philippine Motorcycle plate format',
        suggestion: '${match.group(1)}-${match.group(2)!.toUpperCase()}',
      );
    }

    // Case 2: 4-wheel plate missing space (e.g. NXR1384 or nxr1384)
    final carRegex = RegExp(r'^([A-Za-z]{3})\s*[-]?\s*(\d{4})$');
    if (carRegex.hasMatch(raw)) {
      final match = carRegex.firstMatch(raw)!;
      return GuessResult(
        reason: 'Standard Philippine 4-wheel plate format',
        suggestion: '${match.group(1)!.toUpperCase()} ${match.group(2)}',
      );
    }

    // Case 3: Lowercase letters
    if (raw != raw.toUpperCase() && RegExp(r'[a-z]').hasMatch(raw)) {
      return GuessResult(
        reason: 'Plate numbers are capitalized by standard',
        suggestion: raw.toUpperCase(),
      );
    }

    return null;
  }

  static GuessResult? guessExpiryDate(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return null;

    // Case 1: YYYY-MM-DD or YYYY/MM/DD entered
    final isoRegex = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$');
    if (isoRegex.hasMatch(raw)) {
      final match = isoRegex.firstMatch(raw)!;
      final y = match.group(1)!;
      final m = match.group(2)!.padLeft(2, '0');
      final d = match.group(3)!.padLeft(2, '0');
      return GuessResult(
        reason: 'Standard format is MM/DD/YYYY',
        suggestion: '$m/$d/$y',
      );
    }

    // Case 2: Expired date (year < 2026)
    final parts = raw.split('/');
    if (parts.length == 3) {
      final y = int.tryParse(parts[2]);
      if (y != null && y < 2026) {
        return GuessResult(
          reason: 'License expired in $y. Did you mean valid renewal year?',
          suggestion: '${parts[0]}/${parts[1]}/2028',
        );
      }
    }

    return null;
  }

  static GuessResult? guessPhilId(String text) {
    final raw = text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 16 && !raw.contains(' - ')) {
      final formatted =
          '${digits.substring(0, 4)} - ${digits.substring(4, 8)} - ${digits.substring(8, 12)} - ${digits.substring(12, 16)}';
      return GuessResult(
        reason: 'Standard 4-digit grouped PhilID serial format',
        suggestion: formatted,
      );
    }
    return null;
  }
}
