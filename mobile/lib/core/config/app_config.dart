import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../storage/storage_service.dart';

/// Holds tenant-specific configuration loaded from /api/v1/settings/app-config.
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoUrl,
    this.deliveryFee = 0,
    this.taxPercentage = 0,
  });

  final String appName;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String? logoUrl;
  final int deliveryFee;
  final double taxPercentage;

  static const AppConfig defaults = AppConfig(
    appName: 'Food App',
    primaryColor: Color(0xFFE53935),
    secondaryColor: Color(0xFFFF7043),
    accentColor: Color(0xFFFFC107),
  );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final rawLogo = json['logo_url'] as String?;
    final resolvedLogo = _resolveUrl(rawLogo);

    debugPrint('=== AppConfig.fromJson ===');
    debugPrint('keys: ${json.keys.toList()}');
    debugPrint('raw logo_url: $rawLogo');
    debugPrint('resolved logoUrl: $resolvedLogo');

    return AppConfig(
      appName: (json['app_name_en'] ?? json['app_name']) as String? ?? 'Food App',
      primaryColor: _hexToColor(json['primary_color'] as String? ?? '#E53935'),
      secondaryColor: _hexToColor(json['secondary_color'] as String? ?? '#FF7043'),
      accentColor: _hexToColor(json['accent_color'] as String? ?? '#FFC107'),
      logoUrl: resolvedLogo,
      deliveryFee: json['delivery_fee'] as int? ?? 0,
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Turns a relative path like /storage/settings/x.png into a full URL.
  static String? _resolveUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    // Strip trailing slash from base, prepend to relative path
    final base = StorageService().getBaseUrl();
    final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final resolved = '$cleanBase$value';
    debugPrint('_resolveUrl: $value -> $resolved');
    return resolved;
  }

  static Color _hexToColor(String hex) {
    final sanitized = hex.replaceAll('#', '');
    final value = int.tryParse(
      sanitized.length == 6 ? 'FF$sanitized' : sanitized,
      radix: 16,
    );
    return Color(value ?? 0xFFE53935);
  }
}
