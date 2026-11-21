import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../routes.dart';
import 'onboarding.dart';
import 'shell.dart';

/// Launch screen. Runs while the app really loads its data (no fake waiting):
/// the hand-over happens when both the data and the 1-second reveal are done.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.state});
  final AppState state;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    final reduce = ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: reduce ? 200 : 1000));
    _run();
  }

  Future<void> _run() async {
    final st = widget.state;
    final init = st.loaded ? Future<void>.value() : st.init();
    await Future.wait([init, _c.forward().orCancel]).catchError((Object _) => <void>[]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeRoute<void>(st.settings.onboarded && st.settings.legalAccepted ? const Shell() : const Onboarding()),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Match the native splash (system brightness) so there is no flash on hand-off.
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bg = dark ? const Color(0xFF120E26) : const Color(0xFFF1ECFF);
    final text = dark ? const Color(0xFFF3F0FF) : const Color(0xFF1B1536);
    final muted = dark ? const Color(0xFFB4AED2) : const Color(0xFF625C7E);
    final s = S.of(context);
    final ar = s.rtl;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            double seg(double a, double b, [Curve curve = Curves.easeOut]) =>
                curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());
            final pop = seg(0, 0.6, Curves.easeOutBack);
            final fade = seg(0, 0.35);
            final sweep = seg(0.3, 0.85, Curves.easeInOut);
            final word = seg(0.5, 0.85, Mo.out);
            final tag = seg(0.62, 1.0, Mo.out);
            final stop = sweep * 1.6 - 0.3;
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Opacity(
                opacity: fade,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * pop,
                  child: Hero(
                    tag: 'logo',
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (r) => LinearGradient(
                        begin: const Alignment(-1, -0.4),
                        end: const Alignment(1, 0.4),
                        colors: [Colors.transparent, Colors.white.withValues(alpha: 0.55), Colors.transparent],
                        stops: [
                          (stop - 0.15).clamp(0.0, 1.0).toDouble(),
                          stop.clamp(0.0, 1.0).toDouble(),
                          (stop + 0.15).clamp(0.0, 1.0).toDouble(),
                        ],
                      ).createShader(r),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset('assets/logo/logo.png', width: 128, height: 128),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.x6),
              Opacity(
                opacity: word,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - word)),
                  child: Text('Remindini',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: ar ? 0 : -0.9,
                          color: text)),
                ),
              ),
              const SizedBox(height: Sp.x2),
              Opacity(
                opacity: tag,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - tag)),
                  child: Text(s.t('tagline'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: muted)),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
