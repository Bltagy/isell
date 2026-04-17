export 'package:flutter_localizations/flutter_localizations.dart';
export 'package:isell/l10n/app_localizations.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isell/l10n/app_localizations.dart';

/// Supported locales for the app.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ar'),
];

/// Delegates required by [MaterialApp.localizationsDelegates].
const List<LocalizationsDelegate<dynamic>> kLocalizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
