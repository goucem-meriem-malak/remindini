import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const List<String> kLangs = ['en', 'fr', 'ar'];

/// Version of the Terms and Privacy texts. Change it when the texts change.
const String kLegalVersion = '2026-11-19';

const Map<String, String> _countryCurrency = {
  'DZ': 'DZD', 'MA': 'MAD', 'TN': 'TND', 'EG': 'EGP', 'SA': 'SAR', 'AE': 'AED', 'TR': 'TRY',
  'US': 'USD', 'GB': 'GBP', 'CA': 'CAD', 'AU': 'AUD', 'CH': 'CHF', 'JP': 'JPY', 'IN': 'INR',
  'BR': 'BRL', 'MX': 'MXN', 'CN': 'CNY', 'RU': 'RUB', 'NG': 'NGN', 'ZA': 'ZAR',
  'FR': 'EUR', 'DE': 'EUR', 'ES': 'EUR', 'IT': 'EUR', 'PT': 'EUR', 'NL': 'EUR', 'BE': 'EUR',
  'IE': 'EUR', 'AT': 'EUR', 'FI': 'EUR', 'GR': 'EUR',
};

class Settings {
  const Settings({
    this.theme = 'system',
    this.lang = 'system',
    this.currency = 'USD',
    this.notificationsOn = true,
    this.reminderMinutes = 9 * 60,
    this.onboarded = false,
    this.legalVersion = '',
    this.legalAt = '',
    this.nidCounter = 0,
  });

  final String theme; // system | light | dark
  final String lang; // system | en | fr | ar
  final String currency;
  final bool notificationsOn;
  final int reminderMinutes;
  final bool onboarded;
  final String legalVersion;
  final String legalAt;
  final int nidCounter;

  factory Settings.defaults() {
    final country = ui.PlatformDispatcher.instance.locale.countryCode;
    return Settings(currency: _countryCurrency[country] ?? 'USD');
  }

  Settings copyWith({
    String? theme,
    String? lang,
    String? currency,
    bool? notificationsOn,
    int? reminderMinutes,
    bool? onboarded,
    String? legalVersion,
    String? legalAt,
    int? nidCounter,
  }) =>
      Settings(
        theme: theme ?? this.theme,
        lang: lang ?? this.lang,
        currency: currency ?? this.currency,
        notificationsOn: notificationsOn ?? this.notificationsOn,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        onboarded: onboarded ?? this.onboarded,
        legalVersion: legalVersion ?? this.legalVersion,
        legalAt: legalAt ?? this.legalAt,
        nidCounter: nidCounter ?? this.nidCounter,
      );

  ThemeMode get themeMode => switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Locale? get locale => kLangs.contains(lang) ? Locale(lang) : null;

  /// The language actually in use (used by notifications, which have no screen context).
  String get langCode {
    if (kLangs.contains(lang)) return lang;
    final device = ui.PlatformDispatcher.instance.locale.languageCode;
    return kLangs.contains(device) ? device : 'en';
  }

  bool get legalAccepted => legalVersion == kLegalVersion;

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'lang': lang,
        'currency': currency,
        'notificationsOn': notificationsOn,
        'reminderMinutes': reminderMinutes,
        'onboarded': onboarded,
        'legalVersion': legalVersion,
        'legalAt': legalAt,
        'nidCounter': nidCounter,
      };

  factory Settings.fromJson(Map<String, dynamic> m) {
    final d = Settings.defaults();
    final theme = m['theme'];
    final lang = m['lang'];
    final cur = m['currency'];
    return Settings(
      theme: (theme == 'light' || theme == 'dark') ? theme as String : 'system',
      lang: (lang is String && kLangs.contains(lang)) ? lang : 'system',
      currency: (cur is String && RegExp(r'^[A-Z]{3}$').hasMatch(cur)) ? cur : d.currency,
      notificationsOn: m['notificationsOn'] != false,
      reminderMinutes: ((m['reminderMinutes'] as num?) ?? 540).toInt().clamp(0, 1439).toInt(),
      onboarded: m['onboarded'] == true,
      legalVersion: (m['legalVersion'] as String?) ?? '',
      legalAt: (m['legalAt'] as String?) ?? '',
      nidCounter: ((m['nidCounter'] as num?) ?? 0).toInt().clamp(0, 100000000).toInt(),
    );
  }
}
