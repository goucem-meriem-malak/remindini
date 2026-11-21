import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/settings.dart';
import '../routes.dart';
import '../widgets/glass.dart';
import '../widgets/pickers.dart';
import 'legal_screen.dart';

const String kAppVersion = '1.0.0';
const String kOwnerName = 'Goucem Meriem Malak';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final f = Fmt.of(context);
    final s = f.s;
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final cfg = st.settings;

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(top: Sp.x6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: Sp.x1, bottom: Sp.x3),
              child: Text(title, style: Tx.body(context, size: 14, w: FontWeight.w700, color: p.muted)),
            ),
            Glass(padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x1), child: Column(children: children)),
          ]),
        );

    Widget tile(IconData icon, String title, {String? value, Widget? trailing, VoidCallback? onTap, Color? color, bool last = false}) {
      final c = color ?? p.text;
      return Column(children: [
        Pressable(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(children: [
              Icon(icon, size: 22, color: color ?? Theme.of(context).colorScheme.primary),
              const SizedBox(width: Sp.x3),
              Expanded(child: Text(title, style: Tx.body(context, w: FontWeight.w600, color: c))),
              if (value != null) Text(value, style: Tx.muted(context, size: 14)),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null) Icon(Icons.chevron_right_rounded, color: p.muted),
            ]),
          ),
        ),
        if (!last) Divider(height: 1, thickness: 1, color: p.border),
      ]);
    }

    Widget seg<T>(String label, T value, List<(T, String)> options, ValueChanged<T> on) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.x3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Tx.body(context, w: FontWeight.w600)),
            const SizedBox(height: Sp.x2),
            Seg<T>(value: value, options: options, onChanged: on),
          ]),
        );

    return ListView(
      key: const PageStorageKey('settings'),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, 128 + pad.bottom),
      children: [
        Text(s.t('setTitle'), style: Tx.title(context, size: 30)),
        section(s.t('secAppearance'), [
          seg<String>(s.t('theme'), cfg.theme, [('system', s.t('themeSystem')), ('light', s.t('themeLight')), ('dark', s.t('themeDark'))],
              (v) => st.updateSettings(cfg.copyWith(theme: v))),
          Divider(height: 1, thickness: 1, color: p.border),
          seg<String>(s.t('language'), cfg.lang, [('system', s.t('themeSystem')), ('en', 'EN'), ('fr', 'FR'), ('ar', 'عربي')],
              (v) => st.updateSettings(cfg.copyWith(lang: v))),
        ]),
        section(s.t('secNotif'), [
          tile(
            Icons.notifications_active_rounded,
            s.t('notifOn'),
            trailing: Switch(
              value: cfg.notificationsOn,
              activeThumbColor: Colors.white,
              activeTrackColor: Brand.teal,
              onChanged: (v) async {
                if (!v) {
                  st.updateSettings(cfg.copyWith(notificationsOn: false));
                  return;
                }
                final ok = await st.requestNotifications();
                st.updateSettings(st.settings.copyWith(notificationsOn: ok));
                if (!ok && context.mounted) showToast(context, s.t('notifDenied'));
              },
            ),
          ),
          tile(
            Icons.schedule_rounded,
            s.t('notifTime'),
            value: f.time(cfg.reminderMinutes),
            last: true,
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: cfg.reminderMinutes ~/ 60, minute: cfg.reminderMinutes % 60),
              );
              if (t != null) st.updateSettings(st.settings.copyWith(reminderMinutes: t.hour * 60 + t.minute));
            },
          ),
        ]),
        section(s.t('secMoney'), [
          tile(Icons.payments_rounded, s.t('defCurrency'), value: cfg.currency, last: true, onTap: () async {
            final c = await pickCurrency(context, cfg.currency);
            if (c != null) st.updateSettings(st.settings.copyWith(currency: c));
          }),
        ]),
        section(s.t('secData'), [
          tile(Icons.copy_rounded, s.t('exportData'), onTap: () async {
            await Clipboard.setData(ClipboardData(text: st.exportJson()));
            if (context.mounted) showToast(context, s.t('exportDone'));
          }),
          tile(Icons.restore_rounded, s.t('importData'), onTap: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (!context.mounted) return;
            final text = data?.text ?? '';
            final ok = await confirm(context, title: s.t('restoreTitle'), body: s.t('restoreBody'), yes: s.t('restore'), no: s.t('cancel'));
            if (!ok) return;
            try {
              final n = st.importJson(text);
              if (context.mounted) showToast(context, s.t('importDone', {'n': '$n'}));
            } on FormatException {
              if (context.mounted) showToast(context, s.t('importFail'));
            } on Object {
              if (context.mounted) showToast(context, s.t('importFail'));
            }
          }),
          tile(Icons.delete_forever_rounded, s.t('wipe'), color: p.warn, last: true, onTap: () async {
            final ok = await confirm(context, title: s.t('wipeTitle'), body: s.t('wipeBody'), yes: s.t('delete'), no: s.t('cancel'), danger: true);
            if (!ok) return;
            await st.wipe();
            if (context.mounted) showToast(context, s.t('wipeDone'));
          }),
        ]),
        section(s.t('secAbout'), [
          tile(Icons.description_rounded, s.t('terms'), onTap: () => Navigator.of(context).push(pushRoute<void>(const LegalScreen(kind: 'terms')))),
          tile(Icons.privacy_tip_rounded, s.t('privacy'), onTap: () => Navigator.of(context).push(pushRoute<void>(const LegalScreen(kind: 'privacy')))),
          tile(Icons.info_rounded, s.t('version'), value: kAppVersion, last: true),
        ]),
        const SizedBox(height: Sp.x6),
        Center(
          child: Column(children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset('assets/logo/logo.png', width: 48, height: 48)),
            const SizedBox(height: Sp.x2),
            Text(s.t('madeBy', {'name': kOwnerName}), style: Tx.muted(context)),
            Text(s.t('license'), style: Tx.muted(context, size: 12)),
          ]),
        ),
      ],
    );
  }
}
