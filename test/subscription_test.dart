import 'package:flutter_test/flutter_test.dart';
import 'package:remindini/models/subscription.dart';

Subscription sub({
  required DateTime anchor,
  BillingCycle cycle = BillingCycle.monthly,
  bool trial = false,
  int cents = 1599,
  String name = 'Netflix',
}) =>
    Subscription(id: 'a1', nid: 1, name: name, priceCents: cents, currency: 'USD', cycle: cycle, anchor: anchor, trial: trial);

void main() {
  group('dates', () {
    test('month end is clamped', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
      expect(addMonthsClamped(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    });

    test('daysBetween ignores time and daylight saving', () {
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
      expect(daysBetween(DateTime(2026, 11, 20), DateTime(2026, 11, 20)), 0);
    });
  });

  group('next charge', () {
    test('future anchor is the next charge', () {
      final s = sub(anchor: DateTime(2026, 12, 5));
      expect(s.nextCharge(DateTime(2026, 11, 20)), DateTime(2026, 12, 5));
    });

    test('monthly rolls forward and keeps the original day', () {
      final s = sub(anchor: DateTime(2026, 1, 31));
      expect(s.nextCharge(DateTime(2026, 2, 10)), DateTime(2026, 2, 28));
      expect(s.nextCharge(DateTime(2026, 3, 1)), DateTime(2026, 3, 31));
      expect(s.nextCharge(DateTime(2026, 4, 1)), DateTime(2026, 4, 30));
      expect(s.nextCharge(DateTime(2026, 3, 31)), DateTime(2026, 3, 31));
    });

    test('weekly', () {
      final s = sub(anchor: DateTime(2026, 11, 2), cycle: BillingCycle.weekly);
      expect(s.nextCharge(DateTime(2026, 11, 20)), DateTime(2026, 11, 23));
      expect(s.nextCharge(DateTime(2026, 11, 23)), DateTime(2026, 11, 23));
    });

    test('yearly and quarterly', () {
      expect(sub(anchor: DateTime(2025, 12, 1), cycle: BillingCycle.yearly).nextCharge(DateTime(2026, 11, 20)), DateTime(2026, 12, 1));
      expect(sub(anchor: DateTime(2026, 1, 10), cycle: BillingCycle.quarterly).nextCharge(DateTime(2026, 11, 20)), DateTime(2027, 1, 10));
    });

    test('charges lists every date in a range', () {
      final s = sub(anchor: DateTime(2026, 1, 15));
      final list = s.charges(DateTime(2026, 11, 1), DateTime(2027, 1, 31));
      expect(list, [DateTime(2026, 11, 15), DateTime(2026, 12, 15), DateTime(2027, 1, 15)]);
    });
  });

  group('trials and totals', () {
    test('trial is on until the first charge day', () {
      final s = sub(anchor: DateTime(2026, 11, 25), trial: true);
      expect(s.trialOn(DateTime(2026, 11, 20)), isTrue);
      expect(s.trialOn(DateTime(2026, 11, 25)), isTrue);
      expect(s.trialOn(DateTime(2026, 11, 26)), isFalse);
    });

    test('monthly and yearly cost', () {
      expect(sub(anchor: DateTime(2026, 1, 1), cents: 12000, cycle: BillingCycle.yearly).monthlyCents, closeTo(1000, 0.001));
      expect(sub(anchor: DateTime(2026, 1, 1), cents: 1200, cycle: BillingCycle.quarterly).monthlyCents, closeTo(400, 0.001));
      expect(sub(anchor: DateTime(2026, 1, 1), cents: 300, cycle: BillingCycle.weekly).monthlyCents, closeTo(1300, 0.001));
    });

    test('paying subscriptions skip trials, paused and cancelled', () {
      final today = DateTime(2026, 11, 20);
      final list = [
        sub(anchor: DateTime(2026, 11, 1), name: 'Spotify', cents: 1099),
        sub(anchor: DateTime(2026, 11, 28), trial: true, name: 'Notion'),
        sub(anchor: DateTime(2026, 11, 1), name: 'Gym').copyWith(status: SubStatus.paused),
        sub(anchor: DateTime(2026, 11, 1), name: 'Old').copyWith(status: SubStatus.cancelled),
      ];
      final paying = payingNow(list, today).toList();
      expect(paying.map((e) => e.name), ['Spotify']);
      expect(monthlyByCurrency(paying)['USD'], closeTo(1099, 0.001));
    });
  });

  group('json', () {
    test('round trip', () {
      final s = sub(anchor: DateTime(2026, 12, 5), trial: true).copyWith(notes: 'Family plan', remindDays: 3);
      final back = Subscription.fromJson(s.toJson());
      expect(back.toJson(), s.toJson());
    });

    test('rejects broken data', () {
      expect(() => Subscription.fromJson({'id': 'x', 'name': 'A', 'anchor': 'nope'}), throwsFormatException);
      expect(() => Subscription.fromJson({'id': 'x', 'name': '   ', 'anchor': '2026-01-01'}), throwsFormatException);
    });

    test('clamps absurd values', () {
      final s = Subscription.fromJson({
        'id': 'x', 'name': 'A' * 200, 'anchor': '2026-01-01', 'priceCents': -5, 'remindDays': 999, 'currency': 'dollars',
      });
      expect(s.name.length, 60);
      expect(s.priceCents, 0);
      expect(s.remindDays, 30);
      expect(s.currency, 'USD');
    });
  });
}
