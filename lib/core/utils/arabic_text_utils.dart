/// Helpers for matching user-entered Arabic text against stored strings.
///
/// Arabic substring search fails for users when the query and source differ in
/// diacritics, hamza form, or alef/ya variants. Normalize both sides before
/// comparing so "إبراهيم" matches "ابراهيم", "مصطفى" matches "مصطفي", etc.
class ArabicTextUtils {
  ArabicTextUtils._();

  /// Matches any Arabic diacritic (tashkeel), tatweel, and the Quranic marks.
  static final _diacritics = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08E1\u08E3-\u08FF\u0640]',
  );

  /// Normalize an Arabic string for case/diacritic/variant-insensitive matching.
  /// Returns an empty string for null input.
  static String normalize(String? input) {
    if (input == null || input.isEmpty) return '';
    var s = input;

    s = s.replaceAll(_diacritics, '');

    // Unify alef variants → bare alef
    s = s.replaceAll(RegExp(r'[\u0622\u0623\u0625]'), '\u0627');
    // Alef maksura → ya
    s = s.replaceAll('\u0649', '\u064A');
    // Ta marbuta → ha
    s = s.replaceAll('\u0629', '\u0647');
    // Standalone hamza-on-ya / hamza-on-waw → ya / waw
    s = s.replaceAll('\u0626', '\u064A');
    s = s.replaceAll('\u0624', '\u0648');
    // Bare hamza → drop
    s = s.replaceAll('\u0621', '');

    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return s;
  }

  /// True if [source] contains [query] after normalizing both sides.
  static bool contains(String? source, String? query) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    return normalize(source).contains(q);
  }
}
