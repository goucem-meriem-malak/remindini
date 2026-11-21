import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/settings.dart';
import '../routes.dart';
import '../widgets/glass.dart';
import 'legal_screen.dart';
import 'shell.dart';

/// Three short pages, then the Terms/Privacy checkbox. No account is needed.
class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with SingleTickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  int _page = 0;
  bool _agree = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduce) _float.repeat();
  }

  @override
  void dispose() {
    _pc.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_agree || _busy) return;
    setState(() => _busy = true);
    final st = AppScope.read(context);
    st.updateSettings(st.settings.copyWith(
      onboarded: true,
      legalVersion: kLegalVersion,
      legalAt: DateTime.now().toIso8601String(),
    ));
    final ok = await st.requestNotifications();
    st.updateSettings(st.settings.copyWith(notificationsOn: ok));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute<void>(const Shell()));
  }

  void _next() {
    HapticFeedback.selectionClick();
    _pc.nextPage(duration: Mo.screen, curve: Mo.out);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final st = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    final last = _page == 2;
    final pages = [
      (Icons.subscriptions_rounded, 'ob1_t', 'ob1_b'),
      (Icons.notifications_active_rounded, 'ob2_t', 'ob2_b'),
      (Icons.lock_rounded, 'ob3_t', 'ob3_b'),
    ];
    return AppScaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, 0),
          child: Row(children: [
            Hero(
              tag: 'logo',
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/logo/logo.png', width: 40, height: 40)),
            ),
            const Spacer(),
            for (final code in kLangs)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: Sp.x1),
                child: Pressable(
                  onTap: () => st.updateSettings(st.settings.copyWith(lang: code)),
                  label: code,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      child: AnimatedContainer(
                        duration: Mo.tap,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: s.lang == code ? Brand.heroGradient : null,
                          color: s.lang == code ? null : Pal.of(context).surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: Pal.of(context).border),
                        ),
                        child: Text(code.toUpperCase(),
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: s.lang == code ? Colors.white : Pal.of(context).muted)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: 3,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final (icon, t, b) = pages[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.x6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Illustration(icon: icon, controller: _float, index: i),
                  const SizedBox(height: Sp.x8),
                  Text(s.t(t), textAlign: TextAlign.center, style: Tx.title(context, size: 30)),
                  const SizedBox(height: Sp.x3),
                  Text(s.t(b), textAlign: TextAlign.center, style: Tx.body(context, size: 16, color: Pal.of(context).muted)),
                ]),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.x6, 0, Sp.x6, pad.bottom + Sp.x6),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: Mo.screen,
                  curve: Mo.out,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: i == _page ? Brand.heroGradient : null,
                    color: i == _page ? null : Pal.of(context).border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ]),
            const SizedBox(height: Sp.x6),
            AnimatedSize(
              duration: Mo.screen,
              curve: Mo.out,
              alignment: Alignment.topCenter,
              child: last
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: Sp.x4),
                      child: _AgreeRow(agree: _agree, onChanged: (v) => setState(() => _agree = v)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Row(children: [
              if (!last)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Sp.x3),
                  child: Pressable(
                    onTap: () => _pc.animateToPage(2, duration: Mo.screen, curve: Mo.out),
                    child: SizedBox(
                      height: 56,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                          child: Text(s.t('skip'), style: Tx.body(context, w: FontWeight.w600, color: Pal.of(context).muted)),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: CtaButton(
                  label: s.t(last ? 'getStarted' : 'next'),
                  onPressed: last ? (_agree && !_busy ? _finish : null) : _next,
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _AgreeRow extends StatelessWidget {
  const _AgreeRow({required this.agree, required this.onChanged});
  final bool agree;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = Pal.of(context);
    final template = s.t('agree');
    final parts = <InlineSpan>[];
    final re = RegExp(r'\{(terms|privacy)\}');
    var i = 0;
    for (final m in re.allMatches(template)) {
      if (m.start > i) parts.add(TextSpan(text: template.substring(i, m.start)));
      final kind = m.group(1)!;
      parts.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(pushRoute<void>(LegalScreen(kind: kind))),
          child: Text(s.t(kind),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
        ),
      ));
      i = m.end;
    }
    if (i < template.length) parts.add(TextSpan(text: template.substring(i)));
    return Semantics(
      checked: agree,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Pressable(
          onTap: () => onChanged(!agree),
          label: s.t('agree', {'terms': s.t('terms'), 'privacy': s.t('privacy')}),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: Mo.tap,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: agree ? Brand.heroGradient : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: agree ? Colors.transparent : p.muted, width: 1.5),
                ),
                child: agree ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
              ),
            ),
          ),
        ),
        Expanded(child: Text.rich(TextSpan(style: TextStyle(fontSize: 14, height: 1.4, color: p.text), children: parts))),
      ]),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.controller, required this.index});
  final IconData icon;
  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    const size = 240.0;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final a = controller.value * 2 * math.pi;
          Widget bob(double phase, double amp, Widget child) =>
              Transform.translate(offset: Offset(0, math.sin(a + phase) * amp), child: child);
          return Stack(alignment: Alignment.center, children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Brand.violet.withValues(alpha: 0.28), Brand.violet.withValues(alpha: 0)]),
              ),
            ),
            bob(
              0,
              6,
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  gradient: Brand.heroGradient,
                  borderRadius: BorderRadius.circular(44),
                  boxShadow: [BoxShadow(color: Brand.violetDeep.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20), spreadRadius: -8)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(44),
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 66,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                    Icon(icon, size: 64, color: Colors.white),
                  ]),
                ),
              ),
            ),
            PositionedDirectional(
              top: 18,
              end: 24,
              child: bob(
                1.6,
                5,
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: Brand.ctaGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Brand.teal.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -4)],
                  ),
                  child: Icon([Icons.attach_money_rounded, Icons.alarm_rounded, Icons.shield_rounded][index], color: Brand.onTeal, size: 28),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 26,
              start: 18,
              child: bob(
                3.2,
                5,
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF9CC4), Brand.pink], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Brand.pink.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -4)],
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
