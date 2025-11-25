import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

class LocaleViewModel extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleViewModel() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        _locale = Locale(localeCode);
      }
      // Always notify listeners to ensure UI updates with the current locale
      notifyListeners();
    } catch (e) {
      // If loading fails, use default locale (Arabic)
      _locale = const Locale('ar');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale, {bool syncToBackend = true}) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      
      // Sync language preference to backend if user is authenticated and syncToBackend is true
      if (syncToBackend) {
        try {
          final token = prefs.getString('token');
          if (token != null) {
            await ApiClient.patch(
              '/users/preferred-language',
              body: {'preferredLanguage': locale.languageCode},
            );
          }
        } catch (e) {
          // Silently fail if backend sync fails (user might not be logged in)
          debugPrint('Failed to sync language preference to backend: $e');
        }
      }
    } catch (e) {
      // If saving fails, continue with the locale change
      debugPrint('Failed to save locale: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  void toggleLanguage() {
    if (isArabic) {
      setLanguage('en');
    } else {
      setLanguage('ar');
    }
  }

  /// Sync language preference from backend (called after login/auth check)
  Future<void> syncFromBackend(String? preferredLanguage) async {
    if (preferredLanguage != null && (preferredLanguage == 'ar' || preferredLanguage == 'en')) {
      // Only update if different from current locale to avoid unnecessary updates
      if (_locale.languageCode != preferredLanguage) {
        // Don't sync back to backend when syncing FROM backend to avoid loops
        await setLocale(Locale(preferredLanguage), syncToBackend: false);
      }
    }
  }
}

