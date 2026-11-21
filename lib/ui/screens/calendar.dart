import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/subscription.dart';
import '../category_style.dart';
import '../routes.dart';
import '../widgets/glass.dart';
import '../widgets/sub_tile.dart';
import 'detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _sel;

  @override
  void initState() {
    super.initState();
    final t = dateOnly(DateTime.now());
    _month = DateTime(t.year, t.month);
    _sel = t;
  }

  void _shift(int d) => setState(() {
        _month = DateTime(_month.year, _month.month + d);
        final t = dateOnly(DateTime.now());
        _sel = (t.year == _month.year && t.month == _month.month) ? t : _month;
      });

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final f = Fmt.of(context);
    final s = f.s;
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final today = dateOnly(DateTime.now());

    final first = _month;
    final last = DateTime(_month.year, _month.month + 1, 0);
    final active = st.subs.where((e) => e.status == SubStatus.active).toList();
    final byDay = <int, List<Subscription>>{};
    final totals = <String, double>{};
    for (final e in active) {
      for (final d in e.charges(first, last)) {
        byDay.putIfAbsent(d.day, () => []).add(e);
        totals.update(e.currency, (v) => v + e.priceCents, ifAbsent: () => e.priceCents.toDouble());
      }
    }

    final fdow = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
    final offset = (first.weekday % 7 - fdow + 7) % 7;
    final cells = offset + last.day;
    final rows = (cells / 7).ceil();
    // 2024-01-07 is a Sunday.
    final labels = [for (var i = 0; i < 7; i++) f.weekdayNarrow(DateTime(2024, 1, 7 + (fdow + i) % 7))];
    final selList = _sel.month == _month.month && _sel.year == _month.year ? (byDay[_sel.day] ?? const <Subscription>[]) : const <Subscription>[];
    final primary = DateFormat.yMMMM(f.lang);
    final title = primary.format(first);

    return ListView(
      key: const PageStorageKey('calendar'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, 128 + pad.bottom),
      children: [
        Row(children: [
          Expanded(child: Text(title, style: Tx.title(context, size: 26))),
          RoundIconButton(icon: Icons.chevron_left_rounded, label: '‹', onTap: () => _shift(-1)),
          const SizedBox(width: Sp.x2),
          RoundIconButton(icon: Icons.chevron_right_rounded, label: '›', onTap: () => _shift(1)),
        ]),
        const SizedBox(height: Sp.x4),
        Glass(
          padding: const EdgeInsets.all(Sp.x3),
          child: Column(children: [
            Row(children: [
              for (final l in labels) Expanded(child: Center(child: Text(l, style: Tx.muted(context, size: 12.5, w: FontWeight.w700)))),
            ]),
            const SizedBox(height: Sp.x2),
            for (var r = 0; r < rows; r++)
              Row(children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _cell(context, r * 7 + c - offset + 1, last.day, byDay, today, p)),
              ]),
          ]),
        ),
        const SizedBox(height: Sp.x4),
        Glass(
          gradient: Brand.heroGradient,
          border: false,
          child: Row(children: [
            Expanded(child: Text(s.t('calTotal'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
            Flexible(
              child: Text(
                totals.isEmpty ? '—' : totals.entries.map((e) => f.money(e.value, e.key)).join(' · '),
                textAlign: TextAlign.end,
                style: Tx.num(context, size: 18, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: Sp.x4),
        Text(f.date(_sel), style: Tx.title(context, size: 18)),
        const SizedBox(height: Sp.x3),
        if (selList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.x6),
            child: Center(child: Text(s.t('calNothing'), style: Tx.muted(context, size: 15))),
          )
        else
          for (final e in selList)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.x3),
              child: SubTile(
                sub: e,
                today: today,
                heroTag: false,
                onTap: () => Navigator.of(context).push(pushRoute<void>(DetailScreen(id: e.id))),
              ),
            ),
      ],
    );
  }

  Widget _cell(BuildContext context, int day, int daysInMonth, Map<int, List<Subscription>> byDay, DateTime today, Pal p) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 52);
    final date = DateTime(_month.year, _month.month, day);
    final sel = date == _sel;
    final isToday = date == today;
    final subs = byDay[day] ?? const <Subscription>[];
    return Pressable(
      onTap: () => setState(() => _sel = date),
      scale: 0.94,
      child: SizedBox(
        height: 52,
        child: Center(
          child: AnimatedContainer(
            duration: Mo.screen,
            curve: Mo.out,
            width: 44,
            height: 48,
            decoration: BoxDecoration(
              gradient: sel ? Brand.heroGradient : null,
              borderRadius: BorderRadius.circular(14),
              border: isToday && !sel ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5) : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$day', style: Tx.num(context, size: 15, w: FontWeight.w600, color: sel ? Colors.white : p.text)),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final e in subs.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? Colors.white : catStyle(e.category).b),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
