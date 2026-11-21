import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'data/app_state.dart';
import 'models/settings.dart';
import 'ui/screens/splash.dart';

class RemindiniApp extends StatelessWidget {
  const RemindiniApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final cfg = state.settings;
          return MaterialApp(
            title: 'Remindini',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: cfg.themeMode,
            locale: cfg.locale,
            supportedLocales: [for (final l in kLangs) Locale(l)],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashGate(state: state),
          );
        },
      ),
    );
  }
}
