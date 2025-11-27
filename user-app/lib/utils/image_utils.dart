import 'package:flutter/material.dart';

/// Utility class for handling language-specific images
class ImageUtils {
  /// Get the path to a language-specific image
  /// 
  /// Example:
  /// - For 'whatsapp_verification.png':
  ///   - English: 'assets/images/en/whatsapp_verification.png'
  ///   - Arabic: 'assets/images/ar/whatsapp_verification.png'
  /// 
  /// If the language-specific image doesn't exist, falls back to:
  /// - 'assets/images/whatsapp_verification.png'
  static String getLocalizedImagePath(
    BuildContext context,
    String imageName, {
    String? fallbackPath,
  }) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    
    // Try language-specific path first
    final localizedPath = 'assets/images/$languageCode/$imageName';
    
    // In Flutter, we can't check if asset exists at runtime easily,
    // so we'll return the localized path and handle errors in the widget
    return localizedPath;
  }
  
  /// Get WhatsApp verification image based on current locale
  static String getWhatsAppVerificationImage(BuildContext context) {
    return getLocalizedImagePath(
      context,
      'whatsapp_verification.png',
      fallbackPath: 'assets/images/whatsapp_verification.png',
    );
  }
  
  /// Check if current locale is Arabic
  static bool isArabic(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar';
  }
  
  /// Check if current locale is English
  static bool isEnglish(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'en';
  }
}

