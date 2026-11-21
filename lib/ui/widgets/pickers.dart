import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import 'glass.dart';

/// Bottom sheet frame with a handle.
Future<T?> showSheet<T>(BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final p = Pal.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Sp.x2),
          child: Glass(
            radius: Rd.xl,
            blur: true,
            color: p.dark ? const Color(0xE6211A46) : const Color(0xF2FFFFFF),
            padding: const EdgeInsets.fromLTRB(Sp.x4, Sp.x3, Sp.x4, Sp.x4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: Sp.x3),
              Flexible(child: builder(context)),
            ]),
          ),
        ),
      );
    },
  );
}

Future<String?> pickCurrency(BuildContext context, String current) {
  final f = Fmt.of(context);
  return showSheet<String>(context, (context) {
    final p = Pal.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: kCurrencies.length,
        itemBuilder: (context, i) {
          final code = kCurrencies[i];
          final symbol = NumberFormat.simpleCurrency(locale: f.lang, name: code).currencySymbol;
          final sel = code == current;
          return Pressable(
            onTap: () => Navigator.of(context).pop(code),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: Sp.x3),
              decoration: BoxDecoration(
                color: sel ? Brand.violet.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(Rd.s),
              ),
              child: Row(children: [
                SizedBox(width: 48, child: Text(symbol, style: Tx.num(context, size: 16))),
                Expanded(child: Text(code, style: Tx.body(context, w: FontWeight.w600))),
                if (sel) Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary),
              ]),
            ),
          );
        },
      ),
    );
  });
}

/// Yes/no dialog. Returns true when confirmed.
Future<bool> confirm(BuildContext context, {required String title, required String body, required String yes, required String no, bool danger = false}) async {
  final p = Pal.of(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: Tx.title(context, size: 20)),
      content: Text(body, style: Tx.body(context, color: p.muted)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(no, style: TextStyle(color: p.muted, fontWeight: FontWeight.w600))),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(yes, style: TextStyle(color: danger ? p.warn : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Floating message that sits above the glass navigation bar.
void showToast(BuildContext context, String text, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  final bottom = MediaQuery.paddingOf(context).bottom;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(text),
    margin: EdgeInsets.fromLTRB(Sp.x4, 0, Sp.x4, bottom + 96),
    action: actionLabel == null ? null : SnackBarAction(label: actionLabel, textColor: Brand.teal, onPressed: onAction ?? () {}),
  ));
}
