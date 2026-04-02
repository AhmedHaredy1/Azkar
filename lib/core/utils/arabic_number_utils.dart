/// Utility class for Arabic number conversions.
class ArabicNumberUtils {
  ArabicNumberUtils._();

  /// Eastern Arabic numeral characters (٠١٢٣٤٥٦٧٨٩)
  static const List<String> _easternArabicDigits = [
    '\u0660', // ٠
    '\u0661', // ١
    '\u0662', // ٢
    '\u0663', // ٣
    '\u0664', // ٤
    '\u0665', // ٥
    '\u0666', // ٦
    '\u0667', // ٧
    '\u0668', // ٨
    '\u0669', // ٩
  ];

  /// Converts Western digits (0-9) to Eastern Arabic digits (٠-٩).
  ///
  /// Example:
  /// ```dart
  /// ArabicNumberUtils.toEasternArabic(123); // '١٢٣'
  /// ```
  static String toEasternArabic(int number) {
    return toEasternArabicFromString(number.toString());
  }

  /// Converts a string containing Western digits to Eastern Arabic digits.
  ///
  /// Non-digit characters are preserved as-is.
  ///
  /// Example:
  /// ```dart
  /// ArabicNumberUtils.toEasternArabicFromString('سورة 12'); // 'سورة ١٢'
  /// ```
  static String toEasternArabicFromString(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final digit = int.tryParse(char);
      if (digit != null) {
        buffer.write(_easternArabicDigits[digit]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Converts Eastern Arabic digits (٠-٩) back to Western digits (0-9).
  ///
  /// Example:
  /// ```dart
  /// ArabicNumberUtils.toWestern('١٢٣'); // 123
  /// ```
  static int? toWestern(String easternArabic) {
    final western = toWesternString(easternArabic);
    return int.tryParse(western);
  }

  /// Converts a string containing Eastern Arabic digits to Western digits.
  static String toWesternString(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final index = _easternArabicDigits.indexOf(char);
      if (index != -1) {
        buffer.write(index.toString());
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
