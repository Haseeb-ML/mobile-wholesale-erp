import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/core/theme/app_theme.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/providers/cart_provider.dart';
import 'package:mobile_wholesale_erp/providers/catalog_provider.dart';
import 'package:mobile_wholesale_erp/providers/dashboard_provider.dart';
import 'package:mobile_wholesale_erp/providers/party_provider.dart';
import 'package:mobile_wholesale_erp/providers/purchase_provider.dart';
import 'package:mobile_wholesale_erp/providers/report_provider.dart';
import 'package:mobile_wholesale_erp/ui/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  final catalogProvider = CatalogProvider();
  final partyProvider = PartyProvider();
  final dashboardProvider = DashboardProvider();
  final purchaseProvider = PurchaseProvider();
  final reportProvider = ReportProvider();

  runApp(
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

  // Initialize offline SQLite database & seed demo in background so UI mounts immediately
  try {
    await appState.initialize();
    await catalogProvider.loadProducts();
    await partyProvider.loadParties();
    await dashboardProvider.refresh();
  } catch (e, stack) {
    debugPrint('Background initialization notice: $e\n$stack');
  }
}

class MobileWholesaleErpApp extends StatelessWidget {
  const MobileWholesaleErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'Mobile Wholesale ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(appState.language),
      locale: Locale(appState.language),
      supportedLocales: const [
        Locale('en', ''),
        Locale('ur', ''),
      ],
      localizationsDelegates: const [
        AppLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationScreen(),
    );
  }
}
