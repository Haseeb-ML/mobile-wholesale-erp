import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/main.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/cart_provider.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/providers/purchase_provider.dart';
import 'package:mobile_wholesale_erp/providers/report_provider.dart';

void main() {
  testWidgets('App renders main widget tree cleanly', (WidgetTester tester) async {
    final appState = AppState();
    final catalogProvider = CatalogProvider();
    final partyProvider = PartyProvider();
    final dashboardProvider = DashboardProvider();
    final purchaseProvider = PurchaseProvider();
    final reportProvider = ReportProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appState),
          ChangeNotifierProvider.value(value: catalogProvider),
          ChangeNotifierProvider.value(value: partyProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
          ChangeNotifierProvider.value(value: purchaseProvider),
          ChangeNotifierProvider.value(value: reportProvider),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const MobileWholesaleErpApp(),
      ),
    );

    // Verify MaterialApp mounts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
