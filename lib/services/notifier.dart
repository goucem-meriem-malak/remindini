import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/fmt.dart';
import '../core/l10n.dart';
import '../models/settings.dart';
import '../models/subscription.dart';

class _Pending {
  _Pending(this.id, this.when, this.title, this.body);
  final int id;
  final DateTime when;
  final String title;
  final String body;
}

/// Local reminders only. No server, no push token, nothing leaves the phone.
class Notifier {
  final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('ic_stat_remindini');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _p.initialize(settings: const InitializationSettings(android: android, iOS: darwin));
    _ready = true;
  }

  /// Asks the system for permission. Returns true when allowed.
  Future<bool> requestPermission() async {
    await init();
    final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (a != null) return (await a.requestNotificationsPermission()) ?? false;
    final i = _p.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (i != null) return (await i.requestPermissions(alert: true, badge: true, sound: true)) ?? false;
    return false;
  }

  /// Cancels everything and schedules the next reminders again.
  /// Each subscription gets its next two charges; the closest 60 are kept
  /// (iOS allows at most 64 pending notifications).
  Future<void> reschedule(List<Subscription> subs, Settings st) async {
    await init();
    await _p.cancelAll();
    if (!st.notificationsOn) return;

    final lang = st.langCode;
    final s = S(lang);
    final f = Fmt(lang);
    final now = DateTime.now();
    final today = dateOnly(now);
    final horizon = DateTime(today.year + 1, today.month, today.day);
    final list = <_Pending>[];

    for (final sub in subs) {
      if (sub.status != SubStatus.active) continue;
      var slot = 0;
      for (final charge in sub.charges(today, horizon).take(2)) {
        final isTrialEnd = sub.trial && charge == sub.anchor;
        final offsets = <int>{sub.remindDays, if (isTrialEnd) 1};
        for (final off in offsets) {
          if (slot > 9) break;
          final at = DateTime(charge.year, charge.month, charge.day - off, st.reminderMinutes ~/ 60, st.reminderMinutes % 60);
          if (!at.isAfter(now)) continue;
          final amount = f.money(sub.priceCents, sub.currency);
          final params = {'name': sub.name, 'when': f.rel(off), 'amount': amount, 'date': f.date(charge)};
          list.add(_Pending(
            sub.nid * 10 + slot,
            at,
            s.t(isTrialEnd ? 'nTrialT' : 'nChargeT', params),
            s.t(isTrialEnd ? 'nTrialB' : 'nChargeB', params),
          ));
          slot++;
        }
      }
    }

    list.sort((a, b) => a.when.compareTo(b.when));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'payments',
        s.t('chName'),
        channelDescription: s.t('chDesc'),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final e in list.take(60)) {
      await _p.zonedSchedule(
        id: e.id,
        title: e.title,
        body: e.body,
        // The instant is absolute, so UTC is a valid zone to carry it.
        scheduledDate: tz.TZDateTime.from(e.when, tz.UTC),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
