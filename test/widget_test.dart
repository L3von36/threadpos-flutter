import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:samipos_app/app.dart';
import 'package:samipos_app/models/models.dart';
import 'package:samipos_app/state/store.dart';
import 'package:samipos_app/utils/format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login renders, sign-in reaches the register',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Store store = Store();
    await store.load();

    await tester.pumpWidget(SamiPOSApp(store: store));
    await tester.pump();

    expect(find.text('Sami POS'), findsOneWidget);
    expect(find.text('Seller'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);

    await tester.tap(find.text('Sign in to workspace'));
    await tester.pumpAndSettle();

    // Home shell with the Sell tab active.
    expect(find.text('Sell'), findsWidgets);
    expect(find.byIcon(Icons.storefront), findsWidgets);
  });

  testWidgets('theme toggle switches to dark mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Store store = Store();
    await store.load();

    await tester.pumpWidget(SamiPOSApp(store: store));
    await tester.pump();

    final BuildContext before = tester.element(find.byType(Scaffold));
    expect(Theme.of(before).brightness, Brightness.light);

    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();

    expect(store.themeMode, ThemeMode.dark);
    final BuildContext after = tester.element(find.byType(Scaffold));
    expect(Theme.of(after).brightness, Brightness.dark);
  });

  testWidgets('manager sign-in shows the 3-tab shell',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Store store = Store();
    await store.load();

    await tester.pumpWidget(SamiPOSApp(store: store));
    await tester.pump();

    await tester.tap(find.text('Manager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in to workspace'));
    await tester.pumpAndSettle();

    // Manager bottom bar: Add / Stock / Sales only — no Sell, no Scan.
    expect(find.text('Add'), findsWidgets);
    expect(find.text('Stock'), findsWidgets);
    expect(find.text('Sales'), findsWidgets);
    expect(find.text('Sell'), findsNothing);
  });

  test('cart discount math applies percent off the subtotal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Store store = Store();
    await store.load();

    final Product p = store.products.first;
    store.addToCart(p, size: p.sizes.first, qty: 2);
    final double subtotal = store.cartSubtotal;
    expect(store.cartTotal, subtotal);

    store.setDiscountPct(10);
    expect(store.discountPct, 10);
    expect(store.cartTotal, closeTo(subtotal * 0.9, 0.01));

    store.clearCart();
    expect(store.cartSubtotal, 0);
  });

  test('range analytics cover today and prior window', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Store store = Store();
    await store.load();

    expect(store.todaySales, isNotEmpty);
    expect(store.salesForRange(SalesRange.d7).length,
        greaterThanOrEqualTo(store.todaySales.length));
    // 30 days of seeded history means both windows have a baseline.
    expect(store.priorRevenueFor(SalesRange.d7), greaterThan(0));
    expect(store.rangeDelta(SalesRange.d7), isNotNull);
  });

  test('money formatting groups thousands', () {
    expect(money(12500), 'ETB 12,500');
    expect(money(950), 'ETB 950');
    expect(money(1234567), 'ETB 1,234,567');
  });
}
