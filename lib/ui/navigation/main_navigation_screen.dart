import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/localization/app_localization.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';
import 'package:mobile_wholesale_erp/ui/screens/home/home_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/more/more_hub_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/parties/parties_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/sales/new_sale_screen.dart';
import 'package:mobile_wholesale_erp/ui/screens/stock/stock_catalog_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    NewSaleScreen(),
    StockCatalogScreen(),
    PartiesScreen(),
    MoreHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isUrdu = appState.language == 'ur';

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primaryTeal,
          unselectedItemColor: AppColors.textMuted,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: context.tr('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.point_of_sale_rounded),
              label: context.tr('nav_sales'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_rounded),
              label: context.tr('nav_stock'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_alt_rounded),
              label: context.tr('nav_parties'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_rounded),
              label: context.tr('nav_more'),
            ),
          ],
        ),
      ),
    );
  }
}

