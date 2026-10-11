import 'package:flutter/material.dart';

import 'app.dart';
import 'services/local_database.dart';
import 'state/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.init();
  final Store store = Store();
  await store.load();
  runApp(SamiPOSApp(store: store));
}
