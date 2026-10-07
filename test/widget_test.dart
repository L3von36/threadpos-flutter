import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:threadpos_app/app.dart';
import 'package:threadpos_app/state/store.dart';
import 'package:threadpos_app/utils/format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login renders, sign-in reaches the register',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Store store = Store();
    await store.load();

    await tester.pumpWidget(ThreadPOSApp(store: store));
    await tester.pump();

    expect(find.text('ThreadPOS'), findsOneWidget);
    expect(find.text('Seller'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);

    await tester.tap(find.text('Sign in to workspace'));
    await tester.pumpAndSettle();

    // Home shell with the Sell tab active.
    expect(find.text('Sell'), findsWidgets);
    expect(find.byIcon(Icons.storefront), findsWidgets);
  });

  test('money formatting groups thousands', () {
    expect(money(12500), 'ETB 12,500');
    expect(money(950), 'ETB 950');
    expect(money(1234567), 'ETB 1,234,567');
  });
}
