import 'package:flutter/material.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../models/subscription.dart';
import '../category_style.dart';
import 'glass.dart';

/// One subscription row. The icon is a shared element into the detail screen.
class SubTile extends StatelessWidget {
  const SubTile({super.key, required this.sub, required this.today, required this.onTap, this.heroTag = true});
  final Subscription sub;
  final DateTime today;
  final VoidCallback onTap;
  final bool heroTag;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final f = Fmt.of(context);
    final s = f.s;
    final inactive = sub.status != SubStatus.active;
    final next = sub.nextCharge(today);
    final days = daysBetween(today, next);
    final soon = !inactive && days <= 3;
    final icon = SubIcon(category: sub.category, name: sub.name);
    final whenText = switch (sub.status) {
      SubStatus.paused => s.t('f_paused'),
      SubStatus.cancelled => s.t('f_cancelled'),
      _ => f.whenText(next, today),
    };
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: inactive ? 0.62 : 1,
        child: Glass(
          padding: const EdgeInsets.all(Sp.x3),
          child: Row(children: [
            heroTag ? Hero(tag: 'icon-${sub.id}', child: icon) : icon,
            const SizedBox(width: Sp.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(sub.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.body(context, size: 16, w: FontWeight.w700)),
                  ),
                  if (sub.trialOn(today)) ...[
                    const SizedBox(width: Sp.x2),
                    Pill(s.t('trialBadge'), color: Brand.orange, fg: p.dark ? Brand.orange : const Color(0xFFB45309)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('${catLabel(s, sub.category)} · ${f.cycleLabel(sub.cycle)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.muted(context)),
              ]),
            ),
            const SizedBox(width: Sp.x2),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(f.money(sub.priceCents, sub.currency), style: Tx.num(context, size: 16)),
              const SizedBox(height: 2),
              Text(whenText,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: soon ? p.warn : p.muted)),
            ]),
          ]),
        ),
      ),
    );
  }
}
