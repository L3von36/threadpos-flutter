import 'package:flutter/material.dart';

import 'app.dart';
import 'state/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Store store = Store();
  await store.load();
  runApp(SamiPOSApp(store: store));
}
