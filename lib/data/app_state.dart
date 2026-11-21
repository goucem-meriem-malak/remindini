import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../models/settings.dart';
import '../models/subscription.dart';
import '../services/notifier.dart';

/// App data lives in one JSON file on the phone. Offline first, no server.
class AppState extends ChangeNotifier {
  AppState({this.dir, this.notifier});

  /// Folder for the data file. Null means the app documents folder.
  final Directory? dir;
  final Notifier? notifier;

  bool loaded = false;
  List<Subscription> subs = const [];
  Settings settings = Settings.defaults();

  File? _file;
  Future<void> _queue = Future.value();
  final Random _rng = Random();

  Future<void> init() async {
    final d = dir ?? await getApplicationDocumentsDirectory();
    _file = File('${d.path}${Platform.pathSeparator}remindini_data.json');
    await _load();
    loaded = true;
    notifyListeners();
    unawaited(_reschedule());
  }

  Subscription? byId(String id) {
    for (final s in subs) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ---- ids ----
  String newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rng.nextInt(1 << 20).toRadixString(36)}';

  int takeNid() {
    settings = settings.copyWith(nidCounter: settings.nidCounter + 1);
    return settings.nidCounter;
  }

  // ---- changes ----
  void upsert(Subscription s) {
    final i = subs.indexWhere((e) => e.id == s.id);
    subs = i < 0 ? [...subs, s] : [...subs.sublist(0, i), s, ...subs.sublist(i + 1)];
    _changed();
  }

  void remove(String id) {
    subs = subs.where((e) => e.id != id).toList();
    _changed();
  }

  void setStatus(String id, SubStatus status) {
    final s = byId(id);
    if (s != null) upsert(s.copyWith(status: status));
  }

  void updateSettings(Settings s) {
    settings = s;
    _changed();
  }

  /// Forces a refresh, for example when the app comes back after midnight.
  void touch() {
    notifyListeners();
    unawaited(_reschedule());
  }

  Future<void> wipe() async {
    subs = const [];
    _changed();
  }

  // ---- backup ----
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'remindini',
        'schema': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
        'subscriptions': subs.map((e) => e.toJson()).toList(),
      });

  /// Replaces all subscriptions with the backup. Returns how many were restored.
  /// Throws [FormatException] when the text is not a valid backup.
  int importJson(String raw) {
    if (raw.length > 2000000) throw const FormatException('Too large');
    final d = jsonDecode(raw);
    if (d is! Map || d['app'] != 'remindini' || d['subscriptions'] is! List) {
      throw const FormatException('Not a Remindini backup');
    }
    final list = (d['subscriptions'] as List);
    if (list.length > 500) throw const FormatException('Too many items');
    final parsed = list.map((e) => Subscription.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final seen = <String>{};
    subs = [
      for (final e in parsed)
        if (seen.add(e.id)) e.copyWith(nid: takeNid()),
    ];
    _changed();
    return subs.length;
  }

  // ---- storage ----
  Future<void> _load() async {
    final f = _file!;
    try {
      if (!await f.exists()) return;
      final d = jsonDecode(await f.readAsString());
      if (d is! Map) throw const FormatException('bad file');
      settings = Settings.fromJson(Map<String, dynamic>.from((d['settings'] as Map?) ?? {}));
      final list = (d['subscriptions'] as List?) ?? const [];
      final out = <Subscription>[];
      for (final e in list) {
        try {
          out.add(Subscription.fromJson(Map<String, dynamic>.from(e as Map)));
        } on Object {
          // Skip one broken record instead of losing everything.
        }
      }
      subs = out;
    } on Object {
      // Keep the unreadable file as a backup and start clean.
      try {
        await f.rename('${f.path}.bak');
      } on Object {
        // Nothing more to do.
      }
    }
  }

  void _changed() {
    notifyListeners();
    _persist();
    unawaited(_reschedule());
  }

  void _persist() {
    final f = _file;
    if (f == null) return;
    final data = jsonEncode({
      'schema': 1,
      'settings': settings.toJson(),
      'subscriptions': subs.map((e) => e.toJson()).toList(),
    });
    _queue = _queue.then((_) async {
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(data, flush: true);
      await tmp.rename(f.path);
    }).catchError((Object _) {});
  }

  /// Waits until pending writes are done (used by tests).
  @visibleForTesting
  Future<void> flush() => _queue;

  Future<void> _reschedule() async {
    final n = notifier;
    if (n == null) return;
    try {
      await n.reschedule(subs, settings);
    } on Object {
      // Reminders are best effort; the app keeps working.
    }
  }

  /// Asks for notification permission. Returns true when allowed.
  Future<bool> requestNotifications() async {
    final n = notifier;
    if (n == null) return false;
    try {
      return await n.requestPermission();
    } on Object {
      return false;
    }
  }
}

/// Gives widgets access to [AppState] and rebuilds them when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without listening (safe inside initState and callbacks).
  static AppState read(BuildContext c) => c.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
