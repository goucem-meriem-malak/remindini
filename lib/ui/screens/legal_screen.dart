import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/legal_text.dart';
import '../../core/theme.dart';
import '../../models/settings.dart';
import '../widgets/glass.dart';

/// Terms of Use or Privacy Policy, readable inside the app. [kind] is 'terms' or 'privacy'.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final sections = kLegal[kind]?[s.lang] ?? kLegal[kind]!['en']!;
    return AppScaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, pad.bottom + Sp.x8),
        children: [
          Row(children: [
            RoundIconButton(icon: Icons.arrow_back_rounded, label: MaterialLocalizations.of(context).backButtonTooltip, onTap: () => Navigator.of(context).maybePop()),
          ]),
          const SizedBox(height: Sp.x6),
          Text(s.t(kind), style: Tx.title(context, size: 30)),
          const SizedBox(height: Sp.x2),
          Text('$kLegalVersion · ${s.t('legalDraft')}', style: Tx.muted(context)),
          const SizedBox(height: Sp.x6),
          Glass(
            padding: const EdgeInsets.all(Sp.x6 - 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: Sp.x6),
                Text('${i + 1}. ${sections[i][0]}', style: Tx.body(context, size: 16, w: FontWeight.w700)),
                const SizedBox(height: Sp.x2),
                Text(sections[i][1], style: Tx.body(context, color: p.muted).copyWith(height: 1.5)),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
