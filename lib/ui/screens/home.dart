import 'package:flutter/material.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/settings.dart';
import '../../models/subscription.dart';
import '../routes.dart';
import '../widgets/glass.dart';
import '../widgets/pickers.dart';
import '../widgets/sub_tile.dart';
import 'detail_screen.dart';
import 'edit_subscription.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'all';
  bool _search = false;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _match(Subscription e, DateTime today) {
    switch (_filter) {
      case 'active':
        return e.status == SubStatus.active && !e.trialOn(today);
      case 'trials':
        return e.status == SubStatus.active && e.trialOn(today);
      case 'paused':
        return e.status == SubStatus.paused;
      case 'cancelled':
        return e.status == SubStatus.cancelled;
      default:
        return true;
    }
  }

  void _open(Subscription e) => Navigator.of(context).push(pushRoute<void>(DetailScreen(id: e.id)));

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final f = Fmt.of(context);
    final s = f.s;
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final today = dateOnly(DateTime.now());
    final q = _q.text.trim().toLowerCase();

    final list = st.subs.where((e) => _match(e, today) && (q.isEmpty || e.name.toLowerCase().contains(q))).toList()
      ..sort((a, b) {
        int rank(Subscription x) => x.status == SubStatus.active ? 0 : (x.status == SubStatus.paused ? 1 : 2);
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.nextCharge(today).compareTo(b.nextCharge(today));
      });

    final attention = st.subs.where((e) => e.status == SubStatus.active && e.trialOn(today) && daysBetween(today, e.anchor) <= 7).toList()
      ..sort((a, b) => a.anchor.compareTo(b.anchor));

    final filters = [('all', 'f_all'), ('active', 'f_active'), ('trials', 'f_trials'), ('paused', 'f_paused'), ('cancelled', 'f_cancelled')];

    return CustomScrollView(
      key: const PageStorageKey('home'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(children: [
                Hero(
                  tag: 'logo',
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/logo/logo.png', width: 40, height: 40)),
                ),
                const SizedBox(width: Sp.x3),
                Expanded(child: Text(s.t('appName'), style: Tx.title(context, size: 24))),
                RoundIconButton(
                  icon: _search ? Icons.close_rounded : Icons.search_rounded,
                  label: s.t('search'),
                  onTap: () => setState(() {
                    _search = !_search;
                    if (!_search) _q.clear();
                  }),
                ),
              ]),
              AnimatedSize(
                duration: Mo.screen,
                curve: Mo.out,
                alignment: Alignment.topCenter,
                child: _search
                    ? Padding(
                        padding: const EdgeInsets.only(top: Sp.x3),
                        child: Glass(
                          radius: Rd.m,
                          shadow: false,
                          padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                          child: TextField(
                            controller: _q,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            style: Tx.body(context),
                            decoration: InputDecoration(
                              hintText: s.t('search'),
                              hintStyle: Tx.muted(context, size: 15),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: Sp.x4),
              if (!st.loaded) const _Skeleton() else FadeSlideIn(child: _HeroCard(subs: st.subs, settings: st.settings, today: today)),
            ]),
          ),
        ),
        if (st.loaded && st.subs.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              title: s.t('emptyTitle'),
              body: s.t('emptyBody'),
              cta: s.t('emptyCta'),
              onCta: () => Navigator.of(context).push(pushRoute<void>(const EditScreen(), modal: true)),
            ),
          ),
        if (attention.isNotEmpty) ...[
          SliverToBoxAdapter(child: _SectionTitle(s.t('trialsSoon'))),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                itemCount: attention.length,
                separatorBuilder: (context, i) => const SizedBox(width: Sp.x3),
                itemBuilder: (context, i) => FadeSlideIn(index: i, child: _AttentionCard(sub: attention[i], today: today, onTap: () => _open(attention[i]))),
              ),
            ),
          ),
        ],
        if (st.subs.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x2),
                itemCount: filters.length,
                separatorBuilder: (context, i) => const SizedBox(width: Sp.x2),
                itemBuilder: (context, i) {
                  final (key, label) = filters[i];
                  final on = _filter == key;
                  return Pressable(
                    onTap: () => setState(() => _filter = key),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: AnimatedContainer(
                          duration: Mo.screen,
                          curve: Mo.out,
                          padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: on ? Brand.heroGradient : null,
                            color: on ? null : p.surface,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: p.border),
                          ),
                          child: Text(s.t(label), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: on ? Colors.white : p.muted)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: _SectionTitle(s.t('upcoming'))),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Sp.x8),
                child: Center(child: Text(s.t('noResults'), style: Tx.muted(context, size: 15))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (context, i) => const SizedBox(height: Sp.x3),
                itemBuilder: (context, i) {
                  final e = list[i];
                  return FadeSlideIn(
                    index: i < 8 ? i : 0,
                    child: Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsets.symmetric(horizontal: Sp.x6),
                        decoration: BoxDecoration(color: p.warn.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(Rd.l)),
                        child: Icon(Icons.delete_rounded, color: p.warn),
                      ),
                      onDismissed: (_) {
                        final removed = e;
                        st.remove(e.id);
                        showToast(context, '${s.t('deleted')} · ${removed.name}', actionLabel: s.t('undo'), onAction: () => st.upsert(removed));
                      },
                      child: SubTile(sub: e, today: today, onTap: () => _open(e)),
                    ),
                  );
                },
              ),
            ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: 128 + pad.bottom)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Sp.x4, Sp.x6, Sp.x4, Sp.x3),
        child: Text(text, style: Tx.title(context, size: 20)),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Column(children: [
          SkeletonBox(height: 210, radius: Rd.xl),
          SizedBox(height: Sp.x6),
          SkeletonBox(height: 72, radius: Rd.l),
          SizedBox(height: Sp.x3),
          SkeletonBox(height: 72, radius: Rd.l),
        ]),
      );
}

class _Orb extends StatelessWidget {
  const _Orb(this.size, this.alpha);
  final double size, alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.subs, required this.settings, required this.today});
  final List<Subscription> subs;
  final Settings settings;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final f = Fmt.of(context);
    final s = f.s;
    final paying = payingNow(subs, today).toList();
    final byCur = monthlyByCurrency(paying);
    var primary = settings.currency;
    if (byCur.isNotEmpty && !byCur.containsKey(primary)) {
      primary = (byCur.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }
    final monthly = byCur[primary] ?? 0;
    final others = byCur.entries.where((e) => e.key != primary).toList();

    Subscription? nextSub;
    DateTime? nextDate;
    for (final e in subs.where((e) => e.status == SubStatus.active)) {
      final d = e.nextCharge(today);
      if (nextDate == null || d.isBefore(nextDate)) {
        nextDate = d;
        nextSub = e;
      }
    }
    final days = nextDate == null ? 0 : daysBetween(today, nextDate);
    final progress = nextDate == null ? 0.0 : (30 - (days > 30 ? 30 : days)) / 30;
    final activeCount = subs.where((e) => e.status == SubStatus.active).length;
    const white = Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.circular(Rd.xl),
        boxShadow: [BoxShadow(color: Brand.violetDeep.withValues(alpha: 0.38), blurRadius: 36, offset: const Offset(0, 18), spreadRadius: -10)],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rd.xl),
        border: Border.all(color: white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Rd.xl),
        child: Stack(children: [
          const PositionedDirectional(top: -50, end: -40, child: _Orb(180, 0.12)),
          const PositionedDirectional(bottom: -60, start: -30, child: _Orb(150, 0.08)),
          Padding(
            padding: const EdgeInsets.all(Sp.x6 - 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(s.t('monthlySpend'), style: const TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w600))),
                Pill(s.t('activeCount', {'n': '$activeCount'}), color: white, fg: white),
              ]),
              const SizedBox(height: Sp.x2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(f.money(monthly, primary), style: Tx.num(context, size: 44, color: white)),
              ),
              if (others.isNotEmpty) ...[
                const SizedBox(height: Sp.x1),
                Text('+ ${others.map((e) => f.money(e.value, e.key)).join(' · ')}',
                    style: TextStyle(color: white.withValues(alpha: 0.92), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: Sp.x1),
              Text('${s.t('perYear')} · ${f.money(monthly * 12, primary)}',
                  style: TextStyle(color: white.withValues(alpha: 0.92), fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: Sp.x4),
              Container(
                padding: const EdgeInsets.all(Sp.x3 + 2),
                decoration: BoxDecoration(color: white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(Rd.l), border: Border.all(color: white.withValues(alpha: 0.18))),
                child: nextSub == null
                    ? Text(s.t('nothingDue'), style: const TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w600))
                    : Column(children: [
                        Row(children: [
                          Expanded(
                            child: Text('${s.t('nextCharge')} · ${nextSub.name}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: Sp.x2),
                          Text(f.whenText(nextDate!, today), style: const TextStyle(color: white, fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: Sp.x3),
                        HeroProgress(value: progress),
                      ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.sub, required this.today, required this.onTap});
  final Subscription sub;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final f = Fmt.of(context);
    final p = Pal.of(context);
    final days = daysBetween(today, sub.anchor);
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 252,
        child: Glass(
          padding: const EdgeInsets.all(Sp.x3 + 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: p.dark ? [const Color(0x33FF7AB2), const Color(0x14FFFFFF)] : [const Color(0xFFFFF0F6), Colors.white],
          ),
          child: Row(children: [
            SubIcon(category: sub.category, name: sub.name, size: 44),
            const SizedBox(width: Sp.x3),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sub.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tx.body(context, size: 15, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(f.rel(days), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.warn)),
                const SizedBox(height: 2),
                Text(f.money(sub.priceCents, sub.currency), style: Tx.num(context, size: 14, w: FontWeight.w600, color: p.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
