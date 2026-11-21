import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/subscription.dart';
import '../category_style.dart';

/// Page frame: soft gradient with two light blobs, like the design reference.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      backgroundColor: p.bg1,
      body: Stack(children: [
        const Positioned.fill(child: RepaintBoundary(child: _Backdrop())),
        Positioned.fill(child: body),
      ]),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.bg1, p.bg2]),
      ),
      child: Stack(children: [
        PositionedDirectional(top: -140, end: -100, child: _Blob(Brand.violet, p.dark ? 0.30 : 0.20)),
        PositionedDirectional(bottom: -160, start: -120, child: _Blob(Brand.teal, p.dark ? 0.15 : 0.16)),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.color, this.alpha);
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 380,
        height: 380,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)]),
          ),
        ),
      );
}

/// Frosted surface. Use `blur: true` only for floating things (nav bar, sheets, hero).
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.x4),
    this.radius = Rd.l,
    this.blur = false,
    this.color,
    this.gradient,
    this.border = true,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color? color;
  final Gradient? gradient;
  final bool border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final br = BorderRadius.circular(radius);
    Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? (blur ? p.glass : p.surface)) : null,
        gradient: gradient,
        borderRadius: br,
        border: border ? Border.all(color: p.border) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (blur) {
      inner = ClipRRect(
        borderRadius: br,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: inner),
      );
    }
    if (!shadow || p.dark) return inner;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: br, boxShadow: const [
        BoxShadow(color: Color(0x0A281C64), blurRadius: 2, offset: Offset(0, 1)),
        BoxShadow(color: Color(0x14281C64), blurRadius: 24, spreadRadius: -4, offset: Offset(0, 8)),
      ]),
      child: inner,
    );
  }
}

/// Press feedback: scale 0.98, light haptic.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.98, this.label});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null || widget.onLongPress != null;
    return Semantics(
      button: widget.onTap != null,
      enabled: on,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on ? (_) => _set(true) : null,
        onTapUp: on ? (_) => _set(false) : null,
        onTapCancel: on ? () => _set(false) : null,
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(scale: _down ? widget.scale : 1, duration: Mo.tap, curve: Mo.out, child: widget.child),
      ),
    );
  }
}

/// Main call-to-action: teal gradient pill (as in the reference).
class CtaButton extends StatelessWidget {
  const CtaButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final on = onPressed != null;
    final fg = on ? Brand.onTeal : p.muted;
    return Pressable(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Mo.tap,
        curve: Mo.out,
        height: 56,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Sp.x6),
        decoration: BoxDecoration(
          gradient: on ? Brand.ctaGradient : null,
          color: on ? null : (p.dark ? const Color(0x14FFFFFF) : const Color(0x14281C64)),
          borderRadius: BorderRadius.circular(28),
          boxShadow: on
              ? [BoxShadow(color: Brand.teal.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -4)]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: fg, size: 22), const SizedBox(width: Sp.x2)],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
          ),
        ]),
      ),
    );
  }
}

/// Quiet button for secondary actions.
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.icon, required this.onTap, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final color = danger ? p.warn : p.text;
    return Pressable(
      onTap: onTap,
      child: Glass(
        radius: Rd.m,
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
        shadow: false,
        child: SizedBox(
          height: 52,
          child: Row(children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: Sp.x3),
            Expanded(child: Text(label, style: Tx.body(context, w: FontWeight.w600, color: color))),
          ]),
        ),
      ),
    );
  }
}

/// Round icon button (48px touch target).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, required this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Pressable(
      onTap: onTap,
      label: label,
      child: Glass(
        radius: 24,
        padding: EdgeInsets.zero,
        shadow: false,
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: p.text, size: 22)),
      ),
    );
  }
}

/// Segmented control.
class Seg<T> extends StatelessWidget {
  const Seg({super.key, required this.value, required this.options, required this.onChanged});
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Glass(
      radius: Rd.m,
      padding: const EdgeInsets.all(4),
      shadow: false,
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: Mo.screen,
                curve: Mo.out,
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: Sp.x2),
                decoration: BoxDecoration(
                  gradient: o.$1 == value ? Brand.heroGradient : null,
                  borderRadius: BorderRadius.circular(Rd.s),
                ),
                child: Text(o.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: o.$1 == value ? Colors.white : p.muted)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Small tinted label.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, this.fg});
  final String text;
  final Color color;
  final Color? fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg ?? color)),
      );
}

/// Fade in plus 8px move up, 40ms between siblings. Respects reduced motion.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  Timer? _t;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduce) {
      _on = true;
    } else {
      _t = Timer(Duration(milliseconds: 40 * (widget.index > 10 ? 10 : widget.index)), () {
        if (mounted) setState(() => _on = true);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _on ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        curve: Mo.out,
        child: AnimatedSlide(
          offset: _on ? Offset.zero : const Offset(0, 0.04),
          duration: const Duration(milliseconds: 350),
          curve: Mo.out,
          child: widget.child,
        ),
      );
}

/// Shimmer that matches the real layout (used while data loads).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.p);
  final double p;
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * p, 0, 0);
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final hi = p.dark ? const Color(0x33FFFFFF) : const Color(0xCCFFFFFF);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          colors: [Colors.transparent, hi, Colors.transparent],
          stops: const [0.3, 0.5, 0.7],
          transform: _SlideGradient(_c.value * 2 - 1),
        ).createShader(r),
        child: child,
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = Rd.s});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: p.dark ? const Color(0x1AFFFFFF) : const Color(0x14281C64),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Glossy tile with the first letter of the subscription, in its category colors.
class SubIcon extends StatelessWidget {
  const SubIcon({super.key, required this.category, required this.name, this.size = 48});
  final Category category;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final st = catStyle(category);
    final letter = name.trim().isEmpty ? '?' : String.fromCharCodes(name.trim().runes.take(1)).toUpperCase();
    final r = size * 0.34;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: st.gradient,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [BoxShadow(color: st.b.withValues(alpha: 0.35), blurRadius: size * 0.28, offset: Offset(0, size * 0.12), spreadRadius: -2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.38), Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Text(letter, style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w800, height: 1)),
        ]),
      ),
    );
  }
}

/// Teal progress bar with a round thumb (from the reference's loading bar).
class HeroProgress extends StatelessWidget {
  const HeroProgress({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: LayoutBuilder(builder: (context, c) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Mo.out,
          builder: (context, v, _) {
            final w = c.maxWidth * v;
            return Stack(alignment: AlignmentDirectional.centerStart, children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(8))),
              Container(width: w, height: 8, decoration: BoxDecoration(gradient: Brand.ctaGradient, borderRadius: BorderRadius.circular(8))),
              PositionedDirectional(
                start: (w - 10).clamp(0.0, c.maxWidth - 20).toDouble(),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Brand.teal, width: 4),
                    boxShadow: [BoxShadow(color: Brand.teal.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
              ),
            ]);
          },
        );
      }),
    );
  }
}

/// Empty state with the logo floating on soft rings.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body, this.cta, this.onCta});
  final String title;
  final String body;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(alignment: Alignment.center, children: [
            for (final (d, a) in [(180.0, 0.07), (136.0, 0.12)])
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Brand.violet.withValues(alpha: a)),
              ),
            Glass(
              radius: 32,
              blur: true,
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/logo/logo.png', width: 64, height: 64),
              ),
            ),
          ]),
        ),
        const SizedBox(height: Sp.x4),
        Text(title, textAlign: TextAlign.center, style: Tx.title(context, size: 22)),
        const SizedBox(height: Sp.x2),
        Text(body, textAlign: TextAlign.center, style: Tx.body(context, color: p.muted)),
        if (cta != null) ...[
          const SizedBox(height: Sp.x6),
          CtaButton(label: cta!, icon: Icons.add_rounded, onPressed: onCta),
        ],
      ]),
    );
  }
}
