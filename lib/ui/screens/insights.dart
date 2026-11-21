import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/subscription.dart';
import '../category_style.dart';
import '../widgets/glass.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _yearly = false;
  String? _cur;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final f = Fmt.of(context);
    final s = f.s;
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final today = dateOnly(DateTime.now());
    final paying = payingNow(st.subs, today).toList();
    final byCur = monthlyByCurrency(paying);
    final currencies = byCur.keys.toList()..sort((a, b) => byCur[b]!.compareTo(byCur[a]!));
    final cur = (_cur != null && currencies.contains(_cur))
        ? _cur!
        : (currencies.contains(st.settings.currency) ? st.settings.currency : (currencies.isEmpty ? st.settings.currency : currencies.first));
    final k = _yearly ? 12.0 : 1.0;
    final mine = paying.where((e) => e.currency == cur).toList();
    final total = (byCur[cur] ?? 0) * k;

    final cats = <Category, double>{};
    for (final e in mine) {
      cats.update(e.category, (v) => v + e.monthlyCents * k, ifAbsent: () => e.monthlyCents * k);
    }
    final catList = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = (List<Subscription>.of(mine)..sort((a, b) => b.monthlyCents.compareTo(a.monthlyCents))).take(5).toList();
    final saved = st.subs.where((e) => e.status == SubStatus.cancelled && e.currency == cur).fold<double>(0, (a, e) => a + e.yearlyCents);
    final trialPotential = st.subs
        .where((e) => e.status == SubStatus.active && e.trialOn(today) && e.currency == cur)
        .fold<double>(0, (a, e) => a + e.monthlyCents * k);
    final avg = mine.isEmpty ? 0.0 : total / mine.length;

    return ListView(
      key: const PageStorageKey('insights'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, 128 + pad.bottom),
      children: [
        Text(s.t('insTitle'), style: Tx.title(context, size: 30)),
        const SizedBox(height: Sp.x4),
        Seg<bool>(
          value: _yearly,
          options: [(false, s.t('cyc_monthly')), (true, s.t('cyc_yearly'))],
          onChanged: (v) => setState(() => _yearly = v),
        ),
        if (currencies.length > 1) ...[
          const SizedBox(height: Sp.x3),
          Wrap(spacing: Sp.x2, children: [
            for (final c in currencies)
              Pressable(
                onTap: () => setState(() => _cur = c),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    widthFactor: 1,
                    child: AnimatedContainer(
                      duration: Mo.screen,
                      curve: Mo.out,
                      padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: c == cur ? Brand.heroGradient : null,
                        color: c == cur ? null : p.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: p.border),
                      ),
                      child: Text(c, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c == cur ? Colors.white : p.muted)),
                    ),
                  ),
                ),
              ),
          ]),
        ],
        const SizedBox(height: Sp.x4),
        if (mine.isEmpty)
          Glass(
            padding: const EdgeInsets.all(Sp.x8),
            child: Center(child: Text(s.t('insNoData'), textAlign: TextAlign.center, style: Tx.muted(context, size: 15))),
          )
        else ...[
          FadeSlideIn(
            child: Glass(
              padding: const EdgeInsets.all(Sp.x6),
              child: Column(children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('$cur-$_yearly-${mine.length}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Mo.out,
                    builder: (context, t, _) => CustomPaint(
                      painter: _Donut([for (final e in catList) (catStyle(e.key).b, e.value)], t, p.border),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.x8),
                          child: FittedBox(child: Text(f.money(total, cur), style: Tx.num(context, size: 26))),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.x4),
                Align(alignment: AlignmentDirectional.centerStart, child: Text(s.t('insCat'), style: Tx.body(context, w: FontWeight.w700))),
                const SizedBox(height: Sp.x2),
                for (final e in catList)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: catStyle(e.key).b, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: Sp.x3),
                      Expanded(child: Text(catLabel(s, e.key), style: Tx.body(context))),
                      Text(f.money(e.value, cur), style: Tx.num(context, size: 14, w: FontWeight.w600)),
                    ]),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: Sp.x6),
          Text(s.t('insTop'), style: Tx.title(context, size: 20)),
          const SizedBox(height: Sp.x3),
          Glass(
            child: Column(children: [
              for (final e in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.body(context, w: FontWeight.w600))),
                      Text(f.money(e.monthlyCents * k, cur), style: Tx.num(context, size: 14, w: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      key: ValueKey('${e.id}-$_yearly'),
                      tween: Tween(begin: 0, end: top.first.monthlyCents == 0 ? 0 : e.monthlyCents / top.first.monthlyCents),
                      duration: const Duration(milliseconds: 700),
                      curve: Mo.out,
                      builder: (context, v, _) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(8)),
                          child: FractionallySizedBox(
                            widthFactor: math.max(0.02, v),
                            alignment: AlignmentDirectional.centerStart,
                            child: DecoratedBox(decoration: BoxDecoration(gradient: catStyle(e.category).gradient, borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: Sp.x4),
          Row(children: [
            Expanded(child: _Stat(label: s.t('insAvg'), value: f.money(avg, cur))),
            if (trialPotential > 0) ...[
              const SizedBox(width: Sp.x3),
              Expanded(child: _Stat(label: s.t('insTrials'), value: '+${f.money(trialPotential, cur)}', warn: true)),
            ],
          ]),
        ],
        if (saved > 0) ...[
          const SizedBox(height: Sp.x3),
          Glass(
            color: p.dark ? const Color(0x2634D6B8) : const Color(0xFFE6FAF5),
            child: Row(children: [
              Icon(Icons.savings_rounded, color: p.ok),
              const SizedBox(width: Sp.x3),
              Expanded(child: Text(s.t('insSaved'), style: Tx.body(context, w: FontWeight.w600))),
              Text(f.money(saved, cur), style: Tx.num(context, size: 16, color: p.ok)),
            ]),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.warn = false});
  final String label, value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Tx.muted(context, size: 12.5)),
        const SizedBox(height: Sp.x2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: Tx.num(context, size: 20, color: warn ? p.warn : null))),
      ]),
    );
  }
}

class _Donut extends CustomPainter {
  _Donut(this.segs, this.t, this.track);
  final List<(Color, double)> segs;
  final double t;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(c, r, paint);
    final total = segs.fold<double>(0, (a, e) => a + e.$2);
    if (total <= 0) return;
    final gap = segs.length > 1 ? 0.16 : 0.0;
    var start = -math.pi / 2;
    for (final (color, v) in segs) {
      final ang = v / total * 2 * math.pi * t;
      final sweep = ang - gap;
      if (sweep > 0.01) {
        paint.color = color;
        canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      }
      start += ang;
    }
  }

  @override
  bool shouldRepaint(_Donut old) => old.t != t || old.segs != segs || old.track != track;
}
