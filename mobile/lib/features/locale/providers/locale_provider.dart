import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/api/api_client.dart';

const _boxName = 'locale';
const _localeKey = 'locale_code';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ar')) {
    _init();
  }

  void _init() {
    final box = Hive.box<dynamic>(_boxName);
    final saved = box.get(_localeKey) as String?;
    if (saved != null) {
      state = Locale(saved);
      globalLocaleCode = saved;
    } else {
      // Auto-detect from device language
      final deviceLang = Platform.localeName.split('_').first;
      final supported = ['en', 'ar'];
      final lang = supported.contains(deviceLang) ? deviceLang : 'ar';
      state = Locale(lang);
      globalLocaleCode = lang;
      box.put(_localeKey, lang);
    }
  }

  /// Toggles between en and ar.
  void toggle() {
    final next = state.languageCode == 'en' ? 'ar' : 'en';
    state = Locale(next);
    globalLocaleCode = next;
    Hive.box<dynamic>(_boxName).put(_localeKey, next);
  }

  void setLocale(String languageCode) {
    state = Locale(languageCode);
    globalLocaleCode = languageCode;
    Hive.box<dynamic>(_boxName).put(_localeKey, languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
