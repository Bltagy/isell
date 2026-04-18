import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Box names used throughout the app.
class HiveBoxes {
  static const String cart = 'cart';
  static const String onboarding = 'onboarding';
  static const String appConfig = 'app_config';
}

/// Keys used inside Hive boxes.
class _HiveKeys {
  static const String onboardingDone = 'onboarding_done';
  static const String baseUrl = 'base_url';
  static const String userData = 'user_data';
}

/// Default API base URL.
/// Set at build/run time with --dart-define=BASE_URL=http://your-server:8055
/// Falls back to the LAN IP if not provided.
/// - Physical device: http://<your-machine-ip>:8055
/// - Android emulator: http://10.0.2.2:8055
/// - iOS simulator: http://localhost:8055
const String kDefaultBaseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://isell.dev-ark.com',
);

/// Keys used in flutter_secure_storage.
class _SecureKeys {
  static const String authToken = 'auth_token';
}

class StorageService {
  StorageService({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;

  // ── Initialisation ──────────────────────────────────────────────────────────

  /// Call once at app startup before using any Hive boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(HiveBoxes.cart),
      Hive.openBox<dynamic>(HiveBoxes.onboarding),
      Hive.openBox<dynamic>(HiveBoxes.appConfig),
    ]);
  }

  // ── Auth token (secure storage) ─────────────────────────────────────────────

  Future<String?> getToken() => _secure.read(key: _SecureKeys.authToken);

  Future<void> saveToken(String token) =>
      _secure.write(key: _SecureKeys.authToken, value: token);

  Future<void> clearToken() => _secure.delete(key: _SecureKeys.authToken);

  // ── Onboarding flag (Hive) ───────────────────────────────────────────────────

  bool getOnboardingDone() {
    final box = Hive.box<dynamic>(HiveBoxes.onboarding);
    return box.get(_HiveKeys.onboardingDone, defaultValue: false) as bool;
  }

  Future<void> setOnboardingDone({bool value = true}) {
    final box = Hive.box<dynamic>(HiveBoxes.onboarding);
    return box.put(_HiveKeys.onboardingDone, value);
  }

  // ── Base URL (Hive appConfig box) ────────────────────────────────────────────

  String getBaseUrl() =>
      appConfigBox.get(_HiveKeys.baseUrl, defaultValue: kDefaultBaseUrl) as String;

  Future<void> saveBaseUrl(String url) =>
      appConfigBox.put(_HiveKeys.baseUrl, url);

  // ── User data (Hive) ─────────────────────────────────────────────────────────

  Future<void> saveUser(Map<String, dynamic> user) =>
      appConfigBox.put(_HiveKeys.userData, user);

  Map<String, dynamic>? getUser() {
    final raw = appConfigBox.get(_HiveKeys.userData);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> clearUser() => appConfigBox.delete(_HiveKeys.userData);

  // ── App config cache (Hive) ──────────────────────────────────────────────────

  Box<dynamic> get appConfigBox => Hive.box<dynamic>(HiveBoxes.appConfig);

  Future<void> saveAppConfig(Map<String, dynamic> config) =>
      appConfigBox.putAll(config);

  Map<String, dynamic> getAppConfig() =>
      Map<String, dynamic>.from(appConfigBox.toMap());

  Future<void> clearAppConfig() => appConfigBox.clear();

  // ── Cart (Hive) ──────────────────────────────────────────────────────────────

  Box<dynamic> get cartBox => Hive.box<dynamic>(HiveBoxes.cart);

  Future<void> clearCart() => cartBox.clear();
}
