import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/fmt.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/subscription.dart';
import '../category_style.dart';
import '../widgets/glass.dart';
import '../widgets/pickers.dart';

const List<(String, Category)> _quick = [
  ('Netflix', Category.streaming),
  ('Spotify', Category.music),
  ('YouTube Premium', Category.streaming),
  ('Amazon Prime', Category.streaming),
  ('Disney+', Category.streaming),
  ('Apple Music', Category.music),
  ('iCloud+', Category.cloud),
  ('Google One', Category.cloud),
  ('ChatGPT Plus', Category.software),
  ('Microsoft 365', Category.software),
  ('Adobe Creative Cloud', Category.software),
  ('Xbox Game Pass', Category.gaming),
  ('PlayStation Plus', Category.gaming),
  ('Notion', Category.software),
  ('Duolingo', Category.education),
  ('Gym', Category.fitness),
];

/// Turns Arabic-Indic digits into Latin digits and accepts "," as the decimal mark.
double? parsePrice(String raw) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var t = raw.trim().replaceAll(',', '.').replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  final v = double.tryParse(t);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

class EditScreen extends StatefulWidget {
  const EditScreen({super.key, this.existing});
  final Subscription? existing;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late Category _cat;
  late BillingCycle _cycle;
  late bool _trial;
  late DateTime _date;
  late int _remind;
  late String _cur;
  bool _dateError = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final st = AppScope.read(context);
    final today = dateOnly(DateTime.now());
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e == null ? '' : (e.priceCents / 100).toStringAsFixed(2));
    _notes = TextEditingController(text: e?.notes ?? '');
    _cat = e?.category ?? Category.streaming;
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _trial = e?.trialOn(today) ?? false;
    _date = e?.nextCharge(today) ?? addMonthsClamped(today, 1);
    _remind = e?.remindDays ?? 2;
    _cur = e?.currency ?? st.settings.currency;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) && _trial ? today : _date,
      firstDate: _trial ? today : DateTime(today.year - 2, today.month, today.day),
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (d != null) setState(() {
      _date = dateOnly(d);
      _dateError = false;
    });
  }

  void _save() {
    final today = dateOnly(DateTime.now());
    final ok = _form.currentState!.validate();
    final badDate = _trial && _date.isBefore(today);
    if (badDate) setState(() => _dateError = true);
    if (!ok || badDate) return;
    final st = AppScope.read(context);
    final base = widget.existing;
    final price = parsePrice(_price.text)!;
    st.upsert(Subscription(
      id: base?.id ?? st.newId(),
      nid: base?.nid ?? st.takeNid(),
      name: _name.text.trim(),
      priceCents: (price * 100).round(),
      currency: _cur,
      cycle: _cycle,
      anchor: _date,
      trial: _trial,
      category: _cat,
      remindDays: _remind,
      notes: _notes.text.trim(),
      status: base?.status ?? SubStatus.active,
    ));
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String hint) {
    final p = Pal.of(context);
    OutlineInputBorder b(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(Rd.m), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      hintStyle: Tx.muted(context, size: 15),
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x4),
      border: b(p.border),
      enabledBorder: b(p.border),
      focusedBorder: b(Theme.of(context).colorScheme.primary, 1.5),
      errorBorder: b(p.warn),
      focusedErrorBorder: b(p.warn, 1.5),
      errorStyle: TextStyle(color: p.warn, fontSize: 12.5, fontWeight: FontWeight.w600),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: Sp.x2, top: Sp.x6),
        child: Text(t, style: Tx.body(context, size: 14, w: FontWeight.w700)),
      );

  Widget _chip(String text, bool on, VoidCallback onTap, {IconData? icon}) {
    final p = Pal.of(context);
    return Pressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          widthFactor: 1,
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: on ? Colors.white : p.muted), const SizedBox(width: 6)],
              Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: on ? Colors.white : p.muted)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = Fmt.of(context);
    final s = f.s;
    final p = Pal.of(context);
    final pad = MediaQuery.paddingOf(context);
    final editing = widget.existing != null;
    final today = dateOnly(DateTime.now());

    return AppScaffold(
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.x4, pad.top + Sp.x3, Sp.x4, Sp.x2),
          child: Row(children: [
            RoundIconButton(icon: Icons.close_rounded, label: s.t('cancel'), onTap: () => Navigator.of(context).maybePop()),
            Expanded(child: Text(s.t(editing ? 'editTitle' : 'addTitle'), textAlign: TextAlign.center, style: Tx.title(context, size: 20))),
            const SizedBox(width: 48),
          ]),
        ),
        Expanded(
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (!editing) ...[
                  _label(s.t('quickPick')),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quick.length,
                      separatorBuilder: (context, i) => const SizedBox(width: Sp.x2),
                      itemBuilder: (context, i) => _chip(_quick[i].$1, _name.text == _quick[i].$1, () => setState(() {
                            _name.text = _quick[i].$1;
                            _cat = _quick[i].$2;
                          })),
                    ),
                  ),
                ],
                _label(s.t('name')),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  style: Tx.body(context, size: 16),
                  decoration: _dec(s.t('nameHint')).copyWith(counterText: ''),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.t('errName') : null,
                ),
                _label(s.t('price')),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]'))],
                      style: Tx.num(context, size: 16, w: FontWeight.w600),
                      decoration: _dec('0.00'),
                      validator: (v) {
                        final n = parsePrice(v ?? '');
                        return (n == null || n < 0 || n > 9999999) ? s.t('errPrice') : null;
                      },
                    ),
                  ),
                  const SizedBox(width: Sp.x3),
                  Pressable(
                    onTap: () async {
                      final c = await pickCurrency(context, _cur);
                      if (c != null) setState(() => _cur = c);
                    },
                    label: s.t('currency'),
                    child: Glass(
                      radius: Rd.m,
                      shadow: false,
                      padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                      child: SizedBox(
                        height: 54,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_cur, style: Tx.num(context, size: 16)),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more_rounded, color: p.muted),
                        ]),
                      ),
                    ),
                  ),
                ]),
                _label(s.t('cycle')),
                Wrap(spacing: Sp.x2, runSpacing: 0, children: [
                  for (final c in BillingCycle.values) _chip(f.cycleLabel(c), _cycle == c, () => setState(() => _cycle = c)),
                ]),
                const SizedBox(height: Sp.x4),
                Glass(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x2),
                  child: Column(children: [
                    Row(children: [
                      Icon(Icons.hourglass_bottom_rounded, color: _trial ? Brand.orange : p.muted),
                      const SizedBox(width: Sp.x3),
                      Expanded(child: Text(s.t('freeTrial'), style: Tx.body(context, w: FontWeight.w700))),
                      Switch(
                        value: _trial,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Brand.teal,
                        onChanged: (v) => setState(() {
                          _trial = v;
                          _dateError = false;
                          if (v && _date.isBefore(today)) _date = today;
                          if (v) _remind = _remind > 3 ? 1 : _remind;
                        }),
                      ),
                    ]),
                    AnimatedSize(
                      duration: Mo.screen,
                      curve: Mo.out,
                      alignment: Alignment.topCenter,
                      child: _trial
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: Sp.x3),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(s.t('trialHelp'), style: Tx.muted(context)),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ]),
                ),
                _label(s.t(_trial ? 'trialEnds' : 'nextPayment')),
                if (_trial)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.x2),
                    child: Wrap(spacing: Sp.x2, children: [
                      for (final n in const [7, 14, 30])
                        _chip(s.t('nDays', {'n': '$n'}), daysBetween(today, _date) == n, () => setState(() {
                              _date = DateTime(today.year, today.month, today.day + n);
                              _dateError = false;
                            })),
                    ]),
                  ),
                Pressable(
                  onTap: _pickDate,
                  child: Glass(
                    radius: Rd.m,
                    shadow: false,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
                    child: SizedBox(
                      height: 54,
                      child: Row(children: [
                        Icon(Icons.event_rounded, color: _dateError ? p.warn : Theme.of(context).colorScheme.primary),
                        const SizedBox(width: Sp.x3),
                        Expanded(child: Text(f.date(_date), style: Tx.body(context, size: 16, w: FontWeight.w600))),
                        Icon(Icons.expand_more_rounded, color: p.muted),
                      ]),
                    ),
                  ),
                ),
                if (_dateError)
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.x2),
                    child: Text(s.t('errTrialDate'), style: TextStyle(color: p.warn, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                _label(s.t('category')),
                Wrap(spacing: Sp.x2, children: [
                  for (final c in Category.values) _chip(catLabel(s, c), _cat == c, () => setState(() => _cat = c), icon: catStyle(c).icon),
                ]),
                _label(s.t('remind')),
                Wrap(spacing: Sp.x2, children: [
                  for (final d in const [0, 1, 2, 3, 7]) _chip(f.remindLabel(d), _remind == d, () => setState(() => _remind = d)),
                ]),
                _label(s.t('notes')),
                TextFormField(
                  controller: _notes,
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 4,
                  style: Tx.body(context),
                  decoration: _dec('').copyWith(counterText: ''),
                ),
                SizedBox(height: 120 + pad.bottom),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x2, Sp.x4, pad.bottom + Sp.x3),
          child: CtaButton(label: s.t('save'), icon: Icons.check_rounded, onPressed: _save),
        ),
      ]),
    );
  }
}
