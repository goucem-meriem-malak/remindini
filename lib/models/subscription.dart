import 'dart:math' as math;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days between two calendar dates, safe across daylight-saving changes.
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Adds months and keeps the day inside the target month (Jan 31 + 1 month = Feb 28).
DateTime addMonthsClamped(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12;
  final m = total % 12 + 1;
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, math.min(d.day, last));
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum BillingCycle { weekly, monthly, quarterly, semiannual, yearly }

extension BillingCycleX on BillingCycle {
  int get months => switch (this) {
        BillingCycle.weekly => 0,
        BillingCycle.monthly => 1,
        BillingCycle.quarterly => 3,
        BillingCycle.semiannual => 6,
        BillingCycle.yearly => 12,
      };

  /// How much of one payment counts per month.
  double get perMonth => this == BillingCycle.weekly ? 52 / 12 : 1 / months;
}

enum Category { streaming, music, gaming, software, cloud, news, fitness, education, utilities, other }

enum SubStatus { active, paused, cancelled }

T _enum<T extends Enum>(List<T> values, Object? v, T fallback) {
  for (final e in values) {
    if (e.name == v) return e;
  }
  return fallback;
}

String _clip(String s, int max) {
  final r = s.trim().runes;
  return r.length <= max ? s.trim() : String.fromCharCodes(r.take(max));
}

class Subscription {
  const Subscription({
    required this.id,
    required this.nid,
    required this.name,
    required this.priceCents,
    required this.currency,
    required this.cycle,
    required this.anchor,
    this.trial = false,
    this.category = Category.other,
    this.remindDays = 2,
    this.notes = '',
    this.status = SubStatus.active,
  });

  final String id;

  /// Small integer used to build notification ids.
  final int nid;
  final String name;
  final int priceCents;
  final String currency;
  final BillingCycle cycle;

  /// First (or next known) paid charge. For a free trial this is the day the trial ends.
  final DateTime anchor;
  final bool trial;
  final Category category;
  final int remindDays;
  final String notes;
  final SubStatus status;

  Subscription copyWith({
    String? name,
    int? priceCents,
    String? currency,
    BillingCycle? cycle,
    DateTime? anchor,
    bool? trial,
    Category? category,
    int? remindDays,
    String? notes,
    SubStatus? status,
    int? nid,
  }) =>
      Subscription(
        id: id,
        nid: nid ?? this.nid,
        name: name ?? this.name,
        priceCents: priceCents ?? this.priceCents,
        currency: currency ?? this.currency,
        cycle: cycle ?? this.cycle,
        anchor: anchor ?? this.anchor,
        trial: trial ?? this.trial,
        category: category ?? this.category,
        remindDays: remindDays ?? this.remindDays,
        notes: notes ?? this.notes,
        status: status ?? this.status,
      );

  /// True while the free trial has not ended yet.
  bool trialOn(DateTime today) => trial && !anchor.isBefore(dateOnly(today));

  /// The first charge date on or after [from].
  DateTime nextCharge(DateTime from) {
    final today = dateOnly(from);
    if (!anchor.isBefore(today)) return anchor;
    if (cycle == BillingCycle.weekly) {
      final days = daysBetween(anchor, today);
      final k = (days + 6) ~/ 7;
      return DateTime(anchor.year, anchor.month, anchor.day + 7 * k);
    }
    final months = cycle.months;
    final diff = (today.year - anchor.year) * 12 + today.month - anchor.month;
    var k = math.max(0, diff ~/ months - 1);
    while (true) {
      final c = addMonthsClamped(anchor, k * months);
      if (!c.isBefore(today)) return c;
      k++;
    }
  }

  /// All charge dates from [from] to [to], both included.
  List<DateTime> charges(DateTime from, DateTime to) {
    final out = <DateTime>[];
    final end = dateOnly(to);
    var d = nextCharge(from);
    var guard = 0;
    while (!d.isAfter(end) && guard++ < 500) {
      out.add(d);
      d = nextCharge(DateTime(d.year, d.month, d.day + 1));
    }
    return out;
  }

  double get monthlyCents => priceCents * cycle.perMonth;
  double get yearlyCents => monthlyCents * 12;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nid': nid,
        'name': name,
        'priceCents': priceCents,
        'currency': currency,
        'cycle': cycle.name,
        'anchor': isoDate(anchor),
        'trial': trial,
        'category': category.name,
        'remindDays': remindDays,
        'notes': notes,
        'status': status.name,
      };

  /// Strict parsing with limits. Throws [FormatException] on bad data.
  factory Subscription.fromJson(Map<String, dynamic> m) {
    final anchor = DateTime.tryParse((m['anchor'] as String?) ?? '');
    final id = m['id'];
    if (anchor == null || id is! String || id.isEmpty || id.length > 64) {
      throw const FormatException('Invalid subscription');
    }
    final name = _clip((m['name'] as String?) ?? '', 60);
    if (name.isEmpty) throw const FormatException('Invalid subscription name');
    final cur = ((m['currency'] as String?) ?? 'USD').toUpperCase();
    return Subscription(
      id: id,
      nid: ((m['nid'] as num?) ?? 0).toInt().clamp(0, 100000000).toInt(),
      name: name,
      priceCents: ((m['priceCents'] as num?) ?? 0).toInt().clamp(0, 1000000000).toInt(),
      currency: RegExp(r'^[A-Z]{3}$').hasMatch(cur) ? cur : 'USD',
      cycle: _enum(BillingCycle.values, m['cycle'], BillingCycle.monthly),
      anchor: dateOnly(anchor),
      trial: m['trial'] == true,
      category: _enum(Category.values, m['category'], Category.other),
      remindDays: ((m['remindDays'] as num?) ?? 2).toInt().clamp(0, 30).toInt(),
      notes: _clip((m['notes'] as String?) ?? '', 300),
      status: _enum(SubStatus.values, m['status'], SubStatus.active),
    );
  }
}

// ---- Totals ---------------------------------------------------------------

/// Subscriptions that cost money today (active, and not inside a free trial).
Iterable<Subscription> payingNow(Iterable<Subscription> subs, DateTime today) =>
    subs.where((e) => e.status == SubStatus.active && !e.trialOn(today));

/// Monthly cost in cents, grouped by currency (no exchange rates are used).
Map<String, double> monthlyByCurrency(Iterable<Subscription> subs) {
  final m = <String, double>{};
  for (final e in subs) {
    m.update(e.currency, (v) => v + e.monthlyCents, ifAbsent: () => e.monthlyCents);
  }
  return m;
}
