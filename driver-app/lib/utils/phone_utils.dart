/// Utility functions for phone number handling
class PhoneUtils {
  /// Converts Arabic-Indic numerals (٠-٩) to English digits (0-9)
  /// Also handles Eastern Arabic-Indic numerals (۰-۹)
  static String convertArabicToEnglishDigits(String input) {
    const Map<String, String> arabicToEnglish = {
      // Arabic-Indic numerals
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
      // Eastern Arabic-Indic numerals
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    };
    
    String result = input;
    arabicToEnglish.forEach((arabic, english) {
      result = result.replaceAll(arabic, english);
    });
    return result;
  }

  /// Normalizes a phone number to +9720XXXXXXXX format
  /// This matches the backend normalization logic
  static String? normalizePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null;
    }

    // Remove whitespace
    String normalized = phone.trim().replaceAll(RegExp(r'\s+'), '');

    // Remove all non-digit characters except leading +
    normalized = normalized.replaceAll(RegExp(r'[^\d+]'), '');

    // Remove leading + for processing
    bool hasPlus = normalized.startsWith('+');
    if (hasPlus) {
      normalized = normalized.substring(1);
    }

    // Already in correct format +9720XXXXXXXX (13 digits starting with 9720)
    if (normalized.startsWith('9720') && normalized.length == 13) {
      return '+$normalized';
    }

    // +972XXXXXXXX (12 digits starting with 972, missing the 0)
    // Example: 972593202026 -> should become 9720593202026
    if (normalized.startsWith('972') && normalized.length == 12) {
      // Insert 0 after 972: 972 + 0 + rest
      normalized = '9720${normalized.substring(3)}';
      return '+$normalized';
    }

    // Starts with 0XXXXXXXX (local format, 10 digits)
    // Example: 0593202026 -> should become 9720593202026
    if (normalized.startsWith('0') && normalized.length == 10) {
      normalized = '972$normalized';
      return '+$normalized';
    }

    // Just digits without country code (9 digits)
    // Example: 593202026 -> should become 9720593202026
    if (normalized.length == 9 && !normalized.startsWith('0')) {
      normalized = '9720$normalized';
      return '+$normalized';
    }

    // Already has +9720 but might have extra formatting
    if (normalized.startsWith('9720') && normalized.length >= 13) {
      // Take first 13 digits
      normalized = normalized.substring(0, 13);
      return '+$normalized';
    }

    // Default: try to ensure it starts with +9720
    if (normalized.startsWith('972') && !normalized.startsWith('9720')) {
      normalized = '9720${normalized.substring(3)}';
    } else if (!normalized.startsWith('972')) {
      // If it doesn't start with 972, add it
      if (normalized.startsWith('0')) {
        normalized = '972$normalized';
      } else {
        normalized = '9720$normalized';
      }
    }

    // Ensure it's exactly 13 digits after country code
    if (normalized.length > 13) {
      normalized = normalized.substring(0, 13);
    } else if (normalized.length < 13) {
      // Pad with zeros if too short (shouldn't happen normally)
      normalized = normalized.padRight(13, '0');
    }

    return '+$normalized';
  }
}

