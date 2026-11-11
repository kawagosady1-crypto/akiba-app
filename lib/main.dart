import 'package:flutter/material.dart';

import 'screens.dart';
import 'services.dart';
import 'settings.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  appLocked.value = app.hasPin;
  app.addListener(HomeWidgetSync.schedule);
  HomeWidgetSync.schedule();
  runApp(const AkibaApp());
}

class AkibaApp extends StatefulWidget {
  const AkibaApp({super.key});

  @override
  State<AkibaApp> createState() => _AkibaAppState();
}

class _AkibaAppState extends State<AkibaApp> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      // Lock again after one minute away from the app.
      if (app.hasPin &&
          p != null &&
          DateTime.now().difference(p).inSeconds >= 60) {
        _navKey.currentState?.popUntil((r) => r.isFirst);
        appLocked.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([app, appLocked]),
      builder: (context, _) {
        Widget home;
        if (!app.onboarded) {
          home = const OnboardingScreen();
        } else if (appLocked.value && app.hasPin) {
          home = const LockScreen();
        } else {
          home = const Shell();
        }
        return MaterialApp(
          navigatorKey: _navKey,
          title: 'Akiba',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(app.colorTheme, Brightness.light),
          darkTheme: buildTheme(app.colorTheme, Brightness.dark,
              black: app.themeMode == 'black'),
          themeMode: themeModeFor(app.themeMode),
          home: home,
        );
      },
    );
  }
}
