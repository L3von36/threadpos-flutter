import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/store.dart';
import 'theme/app_theme.dart';

class ThreadPOSApp extends StatelessWidget {
  const ThreadPOSApp({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Store>.value(
      value: store,
      child: MaterialApp(
        title: 'ThreadPOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const LoginScreen(),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => const HomeShell(),
        },
      ),
    );
  }
}
