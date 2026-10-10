import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/store.dart';
import 'theme/app_theme.dart';

class SamiPOSApp extends StatelessWidget {
  const SamiPOSApp({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Store>.value(
      value: store,
      child: const _ThemedMaterialApp(),
    );
  }
}

/// Sits below the provider so it can observe theme-mode changes and
/// let MaterialApp cross-fade between the light and dark themes.
class _ThemedMaterialApp extends StatelessWidget {
  const _ThemedMaterialApp();

  @override
  Widget build(BuildContext context) {
    final Store store = context.watch<Store>();
    return MaterialApp(
      title: 'Sami POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: store.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeOutCubic,
      home: const LoginScreen(),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => const HomeShell(),
      },
    );
  }
}
