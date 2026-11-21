import 'package:flutter/material.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/subscription.dart';
import '../category_style.dart';
import '../routes.dart';
import '../widgets/glass.dart';
import '../widgets/pickers.dart';
import 'edit_subscription.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final sub = st.byId(id);
    if (sub == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const AppScaffold(body: SizedBox.expand());
    }
    final f = Fmt.of(context);
    final s = f.s;
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final today = dateOnly(DateTime.now());
    final style = catStyle(sub.category);
    final next = sub.nextCharge(today);
    final upcoming = sub.status == SubStatus.active ? sub.charges(today, DateTime(today.year + 3, today.month, today.day)).take(4).toList() : <DateTime>[];

    Widget row(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.x3),
          child: Row(children: [
            Expanded(child: Text(label, style: Tx.muted(context, size: 14))),
            const SizedBox(width: Sp.x3),
            Flexible(child: Text(value, textAlign: TextAlign.end, style: Tx.num(context, size: 15, w: FontWeight.w600, color: color))),
          ]),
        );
    Widget divider() => Divider(height: 1, thickness: 1, color: p.border);

    final statusText = switch (sub.status) {
      SubStatus.active => sub.trialOn(today) ? s.t('trialBadge') : s.t('f_active'),
      SubStatus.paused => s.t('f_paused'),
      SubStatus.cancelled => s.t('f_cancelled'),
    };

    return AppScaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, pad.bottom + Sp.x8),
        children: [
          Row(children: [
            RoundIconButton(icon: Icons.arrow_back_rounded, label: MaterialLocalizations.of(context).backButtonTooltip, onTap: () => Navigator.of(context).maybePop()),
            const Spacer(),
            RoundIconButton(
              icon: Icons.edit_rounded,
              label: s.t('edit'),
              onTap: () => Navigator.of(context).push(pushRoute<void>(EditScreen(existing: sub), modal: true)),
            ),
          ]),
          const SizedBox(height: Sp.x6),
          Center(child: Hero(tag: 'icon-${sub.id}', child: SubIcon(category: sub.category, name: sub.name, size: 92))),
          const SizedBox(height: Sp.x4),
          Text(sub.name, textAlign: TextAlign.center, style: Tx.title(context, size: 30)),
          const SizedBox(height: Sp.x2),
          Center(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: f.money(sub.priceCents, sub.currency), style: Tx.num(context, size: 24)),
                TextSpan(text: ' ${f.cycleSuffix(sub.cycle)}', style: Tx.muted(context, size: 16)),
              ]),
            ),
          ),
          const SizedBox(height: Sp.x3),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Pill(statusText, color: sub.status == SubStatus.active ? Brand.teal : Brand.orange, fg: sub.status == SubStatus.active ? p.ok : (p.dark ? Brand.orange : const Color(0xFFB45309))),
            const SizedBox(width: Sp.x2),
            Pill(catLabel(s, sub.category), color: style.b, fg: p.dark ? style.a : style.b),
          ]),
          if (sub.trialOn(today)) ...[
            const SizedBox(height: Sp.x4),
            Glass(
              color: p.dark ? const Color(0x26FFA24C) : const Color(0xFFFFF4E5),
              child: Row(children: [
                const Icon(Icons.hourglass_bottom_rounded, color: Brand.orange),
                const SizedBox(width: Sp.x3),
                Expanded(child: Text(s.t('trialEndsOn', {'date': f.date(sub.anchor)}), style: Tx.body(context, w: FontWeight.w600))),
              ]),
            ),
          ],
          const SizedBox(height: Sp.x6),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x1),
            child: Column(children: [
              row(s.t('detNext'), sub.status == SubStatus.active ? '${f.date(next)} · ${f.rel(daysBetween(today, next))}' : '—'),
              divider(),
              row(s.t('cycle'), f.cycleLabel(sub.cycle)),
              divider(),
              row(s.t('detMonthly'), f.money(sub.monthlyCents, sub.currency)),
              divider(),
              row(s.t('detYearly'), f.money(sub.yearlyCents, sub.currency)),
              divider(),
              row(s.t('detReminder'), f.remindLabel(sub.remindDays)),
              if (sub.notes.isNotEmpty) ...[
                divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.x3),
                  child: Align(alignment: AlignmentDirectional.centerStart, child: Text(sub.notes, style: Tx.body(context, color: p.muted))),
                ),
              ],
            ]),
          ),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: Sp.x6),
            Text(s.t('detUpcoming'), style: Tx.title(context, size: 20)),
            const SizedBox(height: Sp.x3),
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x1),
              child: Column(children: [
                for (var i = 0; i < upcoming.length; i++) ...[
                  if (i > 0) divider(),
                  row(f.date(upcoming[i]), f.money(sub.priceCents, sub.currency)),
                ],
              ]),
            ),
          ],
          const SizedBox(height: Sp.x6),
          if (sub.status == SubStatus.active)
            SoftButton(label: s.t('pause'), icon: Icons.pause_circle_rounded, onTap: () => st.setStatus(sub.id, SubStatus.paused))
          else
            SoftButton(label: s.t('resume'), icon: Icons.play_circle_rounded, onTap: () => st.setStatus(sub.id, SubStatus.active)),
          if (sub.status != SubStatus.cancelled) ...[
            const SizedBox(height: Sp.x3),
            SoftButton(
              label: s.t('markCancelled'),
              icon: Icons.cancel_rounded,
              onTap: () async {
                final ok = await confirm(context, title: s.t('cancTitle'), body: s.t('cancBody'), yes: s.t('markCancelled'), no: s.t('cancel'));
                if (ok) st.setStatus(sub.id, SubStatus.cancelled);
              },
            ),
          ],
          const SizedBox(height: Sp.x3),
          SoftButton(
            label: s.t('delete'),
            icon: Icons.delete_rounded,
            danger: true,
            onTap: () async {
              final ok = await confirm(context, title: s.t('delTitle'), body: s.t('delBody'), yes: s.t('delete'), no: s.t('cancel'), danger: true);
              if (!ok || !context.mounted) return;
              final removed = sub;
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              st.remove(sub.id);
              nav.pop();
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(SnackBar(
                content: Text('${s.t('deleted')} · ${removed.name}'),
                action: SnackBarAction(label: s.t('undo'), textColor: Brand.teal, onPressed: () => st.upsert(removed)),
              ));
            },
          ),
          const SizedBox(height: Sp.x6),
          Text(s.t('cancelTip'), textAlign: TextAlign.center, style: Tx.muted(context)),
        ],
      ),
    );
  }
}
