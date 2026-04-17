import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/debug/error_reporter.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/app_config/providers/app_config_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/locale/providers/locale_provider.dart';
import 'features/products/providers/products_provider.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();
  await Hive.openBox<dynamic>('locale');
  ErrorReporter.init(); // must be after StorageService.init()
  runApp(const ProviderScope(child: FoodOrderingApp()));
}

class FoodOrderingApp extends ConsumerWidget {
  const FoodOrderingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final configAsync = ref.watch(appConfigProvider);
    final config = configAsync.valueOrNull ?? AppConfig.defaults;
    final locale = ref.watch(localeProvider);

    // Refresh data providers when locale changes — but NOT the router provider,
    // which would cause a full navigation reset.
    ref.listen(localeProvider, (prev, next) {
      if (prev?.languageCode != next.languageCode) {
        ref.invalidate(homeProvider);
        ref.invalidate(productsProvider);
        // Do NOT invalidate authProvider — that would reset auth state.
      }
    });

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config, locale: locale.languageCode),
      darkTheme: AppTheme.dark(config, locale: locale.languageCode),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: kLocalizationDelegates,
    );
  }
}
