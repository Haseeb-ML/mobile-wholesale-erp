import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/seed_service.dart';
import 'package:mobile_wholesale_erp/models/shop_settings.dart';

class AppState extends ChangeNotifier {
  ShopSettings _settings = ShopSettings.defaultSettings();
  bool _isDemoMode = true;
  bool _isInitialized = false;

  ShopSettings get settings => _settings;
  bool get isDemoMode => _isDemoMode;
  bool get isInitialized => _isInitialized;
  String get activeRole => _settings.activeRole;
  String get language => _settings.language;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDemoMode = prefs.getBool('is_demo_mode') ?? true;
    DatabaseHelper.instance.setDemoMode(_isDemoMode);

    if (_isDemoMode) {
      // Seed demo data if database is fresh
      await SeedService.instance.seedDemoData();
    }

    await loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('shop_settings', where: 'id = 1');
      if (rows.isNotEmpty) {
        _settings = ShopSettings.fromMap(rows.first);
      } else {
        _settings = ShopSettings.defaultSettings();
        await db.insert('shop_settings', {'id': 1, ..._settings.toMap()});
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    notifyListeners();
  }

  Future<void> updateSettings(ShopSettings newSettings) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('shop_settings', newSettings.toMap(), where: 'id = 1');
    _settings = newSettings;
    notifyListeners();
  }

  Future<void> setRole(String role) async {
    _settings = _settings.copyWith(activeRole: role);
    final db = await DatabaseHelper.instance.database;
    await db.update('shop_settings', {'active_role': role}, where: 'id = 1');
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _settings = _settings.copyWith(language: lang);
    final db = await DatabaseHelper.instance.database;
    await db.update('shop_settings', {'language': lang}, where: 'id = 1');
    notifyListeners();
  }

  Future<void> switchToDemoMode() async {
    _isDemoMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_demo_mode', true);
    DatabaseHelper.instance.setDemoMode(true);
    await SeedService.instance.seedDemoData();
    await loadSettings();
    notifyListeners();
  }

  Future<void> switchToRealMode({required String shopName, required String phone, required String address, String? pin}) async {
    _isDemoMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_demo_mode', false);
    DatabaseHelper.instance.setDemoMode(false);

    final db = await DatabaseHelper.instance.database;
    final initialSettings = ShopSettings(
      shopName: shopName,
      address: address,
      phone: phone,
      invoiceFooter: 'Goods once sold can only be returned within 3 days in saleable condition. Thank you for your business!',
      activeRole: 'owner',
    );
    await db.insert('shop_settings', {'id': 1, ...initialSettings.toMap()}, conflictAlgorithm: ConflictAlgorithm.replace);
    await loadSettings();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    if (!_isDemoMode) return;
    await DatabaseHelper.instance.resetDemoDatabase();
    await SeedService.instance.seedDemoData();
    await loadSettings();
    notifyListeners();
  }
}
