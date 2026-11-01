/// Service for detecting and sanitizing inappropriate / foul language
/// across conversations (English and Filipino / Tagalog).
class ProfanityFilterService {
  ProfanityFilterService._();
  static final ProfanityFilterService instance = ProfanityFilterService._();

  // Common English profanities, slurs and vulgarities
  static const Set<String> _englishProfanities = {
    'fuck', 'fucking', 'fucker', 'fck', 'fuk', 'fudge', 'shit', 'shitty',
    'sh!t', 'bitch', 'bitching', 'b!tch', 'asshole', 'ass', r'a$$hole',
    'bastard', 'cunt', 'dick', 'pussy', 'slut', 'whore', 'motherfucker',
    'bullshit', 'cock', 'retard', 'dumbass', 'jackass', 'moron', 'idiot',
    'dipshit', 'fag', 'faggot', 'nigger', 'nigga', 'blowjob', 'piss',
  };

  // Filipino / Tagalog profanities, curses, and abusive terms
  static const Set<String> _tagalogProfanities = {
    'gago', 'gaga', 'tarantado', 'tarantada', 'tangina', 'tang ina',
    'putangina', 'putang ina', 'puta', 'pota', 'ulol', 'tanga',
    'buwisit', 'bwisit', 'leche', 'letse', 'hudas', 'peste', 'pakyaw',
    'kupal', 'hindot', 'ungas', 'punyeta', 'lintik', 'pakshet', 'pakyu',
    'yawa', 'bilat', 'puke', 'burat', 'bayag', 'tamod', 'kantot', 'iyot',
    'pokpok', 'bobo', 'inutil', 'siraulo', 'hayop',
  };

  // Precompiled regex for leetspeak and obfuscated variations
  static final List<RegExp> _regexFilters = [
    RegExp(r'\bf+[*@#!$]+k\b', caseSensitive: false),
    RegExp(r'\bf+[u*@#!$]+c?k\w*\b', caseSensitive: false),
    RegExp(r'\bsh+[i!*1]+t\w*\b', caseSensitive: false),
    RegExp(r'\bb+[i!*1]+t+c+h\w*\b', caseSensitive: false),
    RegExp(r'\ba+[*@$]{2,}h+o+l+e\b', caseSensitive: false),
    RegExp(r'\bp+[u*@!o]+t+[@a*]+(ng)?\s*([i!*1]+n+[@a*]+)?\b', caseSensitive: false),
    RegExp(r'\bt+[@a*]+n+g\s*[i!*1]+n+[@a*]+\b', caseSensitive: false),
    RegExp(r'\bg+[@a*4]+g+[o0*]+\b', caseSensitive: false),
    RegExp(r'\bu+[l1|]+[o0*]+[l1|]+\b', caseSensitive: false),
    RegExp(r'\bt+[@a*4]+r+[@a*4]+n+t+[@a*4]+d+[o0*]+\b', caseSensitive: false),
    RegExp(r'\bk+[u*]+p+[@a*4]+[l1|]+\b', caseSensitive: false),
    RegExp(r'\bp+[@a*4]+k+y+[u*]+\b', caseSensitive: false),
  ];

  /// Checks if the input text contains any foul or inappropriate words.
  bool hasProfanity(String text) {
    if (text.trim().isEmpty) return false;
    final normalized = _normalizeText(text);

    // 1. Check direct word tokens
    final words = normalized.split(RegExp(r'\s+'));
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (cleanWord.isEmpty) continue;
      if (_englishProfanities.contains(cleanWord) || _tagalogProfanities.contains(cleanWord)) {
        return true;
      }
    }

    // 2. Check multi-word phrase combinations (e.g. 'tang ina', 'putang ina')
    for (final phrase in _tagalogProfanities) {
      if (phrase.contains(' ') && normalized.contains(phrase)) {
        return true;
      }
    }

    // 3. Check regex leetspeak patterns
    for (final regex in _regexFilters) {
      if (regex.hasMatch(text) || regex.hasMatch(normalized)) {
        return true;
      }
    }

    return false;
  }

  /// Identifies all detected inappropriate words in the text.
  List<String> findProfanities(String text) {
    if (text.trim().isEmpty) return [];
    final normalized = _normalizeText(text);
    final detected = <String>{};

    final words = normalized.split(RegExp(r'\s+'));
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (_englishProfanities.contains(cleanWord) || _tagalogProfanities.contains(cleanWord)) {
        detected.add(word);
      }
    }

    for (final phrase in _tagalogProfanities) {
      if (phrase.contains(' ') && normalized.contains(phrase)) {
        detected.add(phrase);
      }
    }

    for (final regex in _regexFilters) {
      final matches = regex.allMatches(text);
      for (final match in matches) {
        final matchedStr = match.group(0);
        if (matchedStr != null) detected.add(matchedStr);
      }
    }

    return detected.toList();
  }

  /// Masks detected profanities with asterisks (e.g., 'f***', 'g***')
  String maskProfanity(String text) {
    if (text.trim().isEmpty) return text;
    String masked = text;

    for (final profanity in [..._englishProfanities, ..._tagalogProfanities]) {
      final pattern = RegExp('\\b${RegExp.escape(profanity)}\\b', caseSensitive: false);
      masked = masked.replaceAllMapped(pattern, (match) {
        final original = match.group(0)!;
        if (original.length <= 2) return '*' * original.length;
        return original[0] + ('*' * (original.length - 2)) + original[original.length - 1];
      });
    }

    for (final regex in _regexFilters) {
      masked = masked.replaceAllMapped(regex, (match) {
        final original = match.group(0)!;
        if (original.length <= 2) return '*' * original.length;
        return original[0] + ('*' * (original.length - 2)) + original[original.length - 1];
      });
    }

    return masked;
  }

  String _normalizeText(String text) {
    return text.toLowerCase().trim();
  }
}
