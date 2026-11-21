import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../routes.dart';
import '../widgets/glass.dart';
import 'calendar.dart';
import 'edit_subscription.dart';
import 'home.dart';
import 'insights.dart';
import 'settings_screen.dart';

/// Main frame: four tabs and a floating glass bar with a central add button.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back (maybe after midnight): refresh dates and re-plan reminders.
    if (state == AppLifecycleState.resumed && mounted) AppScope.read(context).touch();
  }

  void _add() => Navigator.of(context).push(pushRoute<void>(const EditScreen(), modal: true));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pad = MediaQuery.paddingOf(context);
    const pages = <Widget>[HomeScreen(), CalendarScreen(), InsightsScreen(), SettingsScreen()];
    return AppScaffold(
      body: Stack(children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Mo.out,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(anim), child: child),
            ),
            child: KeyedSubtree(key: ValueKey(_i), child: pages[_i]),
          ),
        ),
        Positioned(
          left: Sp.x4,
          right: Sp.x4,
          bottom: pad.bottom + Sp.x3,
          child: Glass(
            blur: true,
            radius: 32,
            padding: const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: Sp.x2),
            child: Row(children: [
              _NavItem(icon: Icons.home_rounded, label: s.t('nav_home'), on: _i == 0, onTap: () => setState(() => _i = 0)),
              _NavItem(icon: Icons.calendar_month_rounded, label: s.t('nav_calendar'), on: _i == 1, onTap: () => setState(() => _i = 1)),
              SizedBox(
                width: 68,
                child: Center(
                  child: Pressable(
                    onTap: _add,
                    label: s.t('nav_add'),
                    scale: 0.94,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: Brand.ctaGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Brand.teal.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -2)],
                      ),
                      child: const Icon(Icons.add_rounded, color: Brand.onTeal, size: 30),
                    ),
                  ),
                ),
              ),
              _NavItem(icon: Icons.donut_large_rounded, label: s.t('nav_insights'), on: _i == 2, onTap: () => setState(() => _i = 2)),
              _NavItem(icon: Icons.settings_rounded, label: s.t('nav_settings'), on: _i == 3, onTap: () => setState(() => _i = 3)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final color = on ? Theme.of(context).colorScheme.primary : p.muted;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        label: label,
        child: SizedBox(
          height: 56,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedScale(scale: on ? 1.08 : 1, duration: Mo.screen, curve: Mo.out, child: Icon(icon, color: color, size: 26)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: Mo.screen,
              curve: Mo.out,
              width: on ? 18 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: on ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
