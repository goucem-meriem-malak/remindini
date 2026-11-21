import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remindini/core/l10n.dart';
import 'package:remindini/data/app_state.dart';
import 'package:remindini/models/subscription.dart';

Subscription make(AppState st, String name, int cents) => Subscription(
      id: st.newId(),
      nid: st.takeNid(),
      name: name,
      priceCents: cents,
      currency: 'EUR',
      cycle: BillingCycle.monthly,
      anchor: DateTime(2026, 12, 3),
    );

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('remindini_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('saves and reloads', () async {
    final a = AppState(dir: dir);
    await a.init();
    a.upsert(make(a, 'Spotify', 1099));
    a.upsert(make(a, 'Disney+', 899));
    await a.flush();

    final b = AppState(dir: dir);
    await b.init();
    expect(b.subs.map((e) => e.name), ['Spotify', 'Disney+']);
    expect(b.settings.nidCounter, 2);
  });

  test('remove and restore (undo)', () async {
    final a = AppState(dir: dir);
    await a.init();
    final s = make(a, 'Notion', 1000);
    a.upsert(s);
    a.remove(s.id);
    expect(a.subs, isEmpty);
    a.upsert(s);
    expect(a.byId(s.id)?.name, 'Notion');
  });

  test('status change', () async {
    final a = AppState(dir: dir);
    await a.init();
    final s = make(a, 'Gym', 2500);
    a.upsert(s);
    a.setStatus(s.id, SubStatus.paused);
    expect(a.byId(s.id)!.status, SubStatus.paused);
  });

  test('export then import on a clean install', () async {
    final a = AppState(dir: dir);
    await a.init();
    a.upsert(make(a, 'Spotify', 1099));
    a.upsert(make(a, 'iCloud+', 299));
    final backup = a.exportJson();

    final dir2 = Directory.systemTemp.createTempSync('remindini_test2');
    addTearDown(() => dir2.deleteSync(recursive: true));
    final b = AppState(dir: dir2);
    await b.init();
    expect(b.importJson(backup), 2);
    expect(b.subs.map((e) => e.name).toSet(), {'Spotify', 'iCloud+'});
    expect(b.subs.map((e) => e.nid).toSet().length, 2);
  });

  test('import rejects bad text and keeps data', () async {
    final a = AppState(dir: dir);
    await a.init();
    a.upsert(make(a, 'Spotify', 1099));
    expect(() => a.importJson('hello'), throwsFormatException);
    expect(() => a.importJson('{"app":"other","subscriptions":[]}'), throwsFormatException);
    expect(a.subs.length, 1);
  });

  test('wipe clears subscriptions and the file reflects it', () async {
    final a = AppState(dir: dir);
    await a.init();
    a.upsert(make(a, 'Spotify', 1099));
    await a.wipe();
    await a.flush();
    final b = AppState(dir: dir);
    await b.init();
    expect(b.subs, isEmpty);
  });

  test('a corrupt file is kept as .bak and the app starts clean', () async {
    File('${dir.path}${Platform.pathSeparator}remindini_data.json').writeAsStringSync('{not json');
    final a = AppState(dir: dir);
    await a.init();
    expect(a.subs, isEmpty);
    expect(File('${dir.path}${Platform.pathSeparator}remindini_data.json.bak').existsSync(), isTrue);
  });

  test('all languages have the same keys', () {
    // Plural variants (.one/.two/.few/.other) differ per language, so compare base keys.
    Set<String> base(String l) => S.all[l]!.keys.map((k) => k.replaceAll(RegExp(r'\.(one|two|few|other)$'), '')).toSet();
    expect(base('fr'), base('en'));
    expect(base('ar'), base('en'));
    for (final l in ['en', 'fr', 'ar']) {
      for (final k in S.all[l]!.keys.where((k) => k.endsWith('.one'))) {
        expect(S.all[l]!.containsKey(k.replaceAll('.one', '.other')), isTrue, reason: '$l $k needs .other');
      }
    }
  });

  test('plural categories', () {
    expect(const S('en').plural('inDays', 1), 'in 1 day');
    expect(const S('en').plural('inDays', 5), 'in 5 days');
    expect(const S('ar').plural('inDays', 2), 'بعد يومين');
    expect(const S('ar').plural('inDays', 5), 'بعد 5 أيام');
    expect(const S('ar').plural('inDays', 12), 'بعد 12 يومًا');
    expect(const S('fr').plural('inDays', 3), 'dans 3 jours');
  });
}
