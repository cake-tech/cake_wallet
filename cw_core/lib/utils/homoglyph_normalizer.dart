/// Normalizes homoglyph characters (Cyrillic, Greek, etc.) to their ASCII equivalents
/// to detect spoofing attacks like "UЅDС" (Cyrillic) vs "USDC" (ASCII)
String normalizeHomoglyphs(String text) {
  final homoglyphMap = {
    // Cyrillic letters that look like Latin
    'А': 'A', // Cyrillic A
    'В': 'B', // Cyrillic Ve
    'Е': 'E', // Cyrillic Ie
    'К': 'K', // Cyrillic Ka
    'М': 'M', // Cyrillic Em
    'Н': 'H', // Cyrillic En
    'О': 'O', // Cyrillic O
    'Р': 'P', // Cyrillic Er
    'С': 'C', // Cyrillic Es
    'Т': 'T', // Cyrillic Te
    'У': 'Y', // Cyrillic U
    'Х': 'X', // Cyrillic Kha
    'а': 'a',
    'в': 'b',
    'е': 'e',
    'к': 'k',
    'м': 'm',
    'н': 'h',
    'о': 'o',
    'р': 'p',
    'с': 'c',
    'т': 't',
    'у': 'y',
    'х': 'x',
    'Ѕ': 'S', // Cyrillic Dze (looks like S)
    'ѕ': 's',
    'І': 'I', // Cyrillic I
    'і': 'i',
    'Ј': 'J', // Cyrillic Je
    'ј': 'j',
    // Greek letters that look like Latin
    'Α': 'A', // Alpha
    'Β': 'B', // Beta
    'Ε': 'E', // Epsilon
    'Ζ': 'Z', // Zeta
    'Η': 'H', // Eta
    'Ι': 'I', // Iota
    'Κ': 'K', // Kappa
    'Μ': 'M', // Mu
    'Ν': 'N', // Nu
    'Ο': 'O', // Omicron
    'Ρ': 'P', // Rho
    'Τ': 'T', // Tau
    'Υ': 'Y', // Upsilon
    'Χ': 'X', // Chi
    'α': 'a',
    'β': 'b',
    'ε': 'e',
    'ζ': 'z',
    'η': 'h',
    'ι': 'i',
    'κ': 'k',
    'μ': 'm',
    'ν': 'n',
    'ο': 'o',
    'ρ': 'p',
    'τ': 't',
    'υ': 'y',
    'χ': 'x',
  };

  return text.split('').map((char) => homoglyphMap[char] ?? char).join('');
}
