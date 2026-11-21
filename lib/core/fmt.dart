import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../models/subscription.dart';
import 'l10n.dart';

/// Locale-aware formatting for money, dates and relative days.
class Fmt {
  Fmt(this.lang) : s = S(lang);
  final String lang;
  final S s;

  static Fmt of(BuildContext c) => Fmt(Localizations.localeOf(c).languageCode);

  static final Map<String, NumberFormat> _money = {};

  String money(num cents, String currency) {
    final nf = _money.putIfAbsent(
      '$lang|$currency',
      () => NumberFormat.simpleCurrency(locale: lang, name: currency),
    );
    return nf.format(cents / 100);
  }

  String date(DateTime d) => DateFormat.yMMMd(lang).format(d);
  String dayMonth(DateTime d) => DateFormat.MMMd(lang).format(d);
  String monthYear(DateTime d) => DateFormat.yMMMM(lang).format(d);
  String weekdayNarrow(DateTime d) => DateFormat('EEEEE', lang).format(d);
  String time(int minutes) => DateFormat.jm(lang).format(DateTime(2024, 1, 1, minutes ~/ 60, minutes % 60));

  /// "Today", "Tomorrow", "in 5 days".
  String rel(int days) {
    if (days <= 0) return s.t('today');
    if (days == 1) return s.t('tomorrow');
    return s.plural('inDays', days);
  }

  String whenText(DateTime d, DateTime today) {
    final n = daysBetween(today, d);
    return n <= 30 ? rel(n) : dayMonth(d);
  }

  String cycleLabel(BillingCycle c) => s.t('cyc_${c.name}');
  String cycleSuffix(BillingCycle c) => s.t('per_${c.name}');
  String remindLabel(int days) => days == 0 ? s.t('remindSame') : s.plural('before', days);
}

const List<String> kCurrencies = [
  'USD', 'EUR', 'GBP', 'DZD', 'MAD', 'TND', 'EGP', 'SAR', 'AED', 'TRY', 'CAD',
  'AUD', 'CHF', 'JPY', 'INR', 'BRL', 'MXN', 'CNY', 'RUB', 'NGN', 'ZAR',
];
