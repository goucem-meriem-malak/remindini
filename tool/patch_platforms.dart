// Run once after `flutter create`, from the project root:
//   dart run tool/patch_platforms.dart
// It adds what local notifications need on Android and copies the notification icon.
// Safe to run again: it skips anything already done.
import 'dart:io';

const _receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';

void main() {
  final root = Directory.current.path;
  final sep = Platform.pathSeparator;
  String p(String rel) => '$root$sep${rel.replaceAll('/', sep)}';
  if (!Directory(p('android')).existsSync()) {
    stdout.writeln('No android folder. Run: flutter create --org com.gmm --project-name remindini .');
    exit(1);
  }
  _step('AndroidManifest.xml', () => _manifest(File(p('android/app/src/main/AndroidManifest.xml'))));
  _step('android/app/build.gradle(.kts)', () => _gradle(p('android/app')));
  _step('notification icons', () => _icons(Directory(p('tool/android_res')), Directory(p('android/app/src/main/res'))));
}

void _step(String name, bool Function() fn) {
  try {
    stdout.writeln('${fn() ? 'patched      ' : 'already done '}$name');
  } on Object catch (e) {
    stdout.writeln('FAILED        $name: $e');
    stdout.writeln('              See SETUP.md, "Manual Android steps".');
  }
}

bool _manifest(File f) {
  var t = f.readAsStringSync();
  final before = t;
  if (!t.contains('POST_NOTIFICATIONS')) {
    final i = t.indexOf('>', t.indexOf('<manifest'));
    t = '${t.substring(0, i + 1)}\n'
        '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
        '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
        '${t.substring(i + 1)}';
  }
  if (!t.contains('ScheduledNotificationReceiver')) {
    final i = t.lastIndexOf('</application>');
    if (i < 0) throw StateError('</application> not found');
    t = '${t.substring(0, i)}$_receivers    ${t.substring(i)}';
  }
  if (!t.contains('android:allowBackup')) {
    t = t.replaceFirst('<application', '<application\n        android:allowBackup="false"');
  }
  t = t.replaceFirst('android:label="remindini"', 'android:label="Remindini"');
  if (t == before) return false;
  f.writeAsStringSync(t);
  return true;
}

bool _gradle(String dir) {
  final kts = File('$dir${Platform.pathSeparator}build.gradle.kts');
  final groovy = File('$dir${Platform.pathSeparator}build.gradle');
  final isKts = kts.existsSync();
  final f = isKts ? kts : groovy;
  if (!f.existsSync()) throw StateError('no build.gradle(.kts) found');
  var t = f.readAsStringSync();
  final before = t;
  if (!t.contains('oreLibraryDesugaring')) {
    if (!t.contains('compileOptions {')) throw StateError('compileOptions block not found');
    t = t.replaceFirst('compileOptions {',
        isKts ? 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true' : 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    t += isKts
        ? '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n'
        : "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.5'\n}\n";
  }
  if (t == before) return false;
  f.writeAsStringSync(t);
  return true;
}

bool _icons(Directory from, Directory to) {
  var copied = false;
  for (final d in from.listSync().whereType<Directory>()) {
    final name = d.path.split(Platform.pathSeparator).last;
    final target = Directory('${to.path}${Platform.pathSeparator}$name')..createSync(recursive: true);
    for (final file in d.listSync().whereType<File>()) {
      final dest = File('${target.path}${Platform.pathSeparator}${file.path.split(Platform.pathSeparator).last}');
      final bytes = file.readAsBytesSync();
      if (!dest.existsSync() || !_same(dest.readAsBytesSync(), bytes)) {
        dest.writeAsBytesSync(bytes);
        copied = true;
      }
    }
  }
  return copied;
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
