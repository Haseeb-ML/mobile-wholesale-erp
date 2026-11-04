import 'package:flutter/foundation.dart';
import 'package:mobile_wholesale_erp/core/database/database_helper.dart';
import 'package:mobile_wholesale_erp/core/services/accounting_service.dart';
import 'package:mobile_wholesale_erp/models/expense.dart';
import 'package:mobile_wholesale_erp/models/invoice.dart';
import 'package:mobile_wholesale_erp/models/invoice_item.dart';
import 'package:mobile_wholesale_erp/models/product.dart';
import 'package:mobile_wholesale_erp/models/purchase.dart';
import 'package:mobile_wholesale_erp/models/purchase_item.dart';
import 'package:mobile_wholesale_erp/models/return_order.dart';
import 'package:mobile_wholesale_erp/models/shop_settings.dart';

class SeedService {
  static final SeedService instance = SeedService._internal();
  SeedService._internal();

  Future<void> seedDemoData() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    // Check if demo database is already seeded
    final prodCount = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    if ((prodCount.first['count'] as int? ?? 0) > 0) {
      debugPrint('Demo database already contains data.');
      return;
    }

    debugPrint('Seeding rich offline Demo Data for Mobile Accessories Wholesale...');

    final now = DateTime.now();
    String dateOffset(int daysAgo) {
      final d = now.subtract(Duration(days: daysAgo));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    // 1. Seed Shop Settings
    final settings = ShopSettings.defaultSettings();
    await db.insert('shop_settings', {'id': 1, ...settings.toMap()});

    // Opening Cash and Bank balances
    await db.rawUpdate('UPDATE financial_accounts SET balance_paisa = 15000000 WHERE id = "cash"'); // PKR 150,000 opening cash
    await db.rawUpdate('UPDATE financial_accounts SET balance_paisa = 50000000 WHERE id = "bank"'); // PKR 500,000 opening bank

    await db.insert('account_transactions', {
      'account_id': 'cash',
      'date': dateOffset(30),
      'type': 'opening',
      'debit_paisa': 15000000,
      'credit_paisa': 0,
      'running_balance_paisa': 15000000,
      'notes': 'Shop Opening Cash Balance',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('account_transactions', {
      'account_id': 'bank',
      'date': dateOffset(30),
      'type': 'opening',
      'debit_paisa': 50000000,
      'credit_paisa': 0,
      'running_balance_paisa': 50000000,
      'notes': 'Meezan Bank Opening Balance',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Seed 5 Suppliers
    final List<Map<String, dynamic>> supplierData = [
      {
        'type': 'supplier',
        'name': 'Shenzhen Direct Importers Karachi',
        'contact_person': 'Haji Aslam',
        'phone': '0300-8273641',
        'city': 'Karachi',
        'address': 'Bolton Market, Wholesale Plaza # 4',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Direct sea container shipment supplier',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'supplier',
        'name': 'Baseus Official Distributor PK',
        'contact_person': 'Tariq Mehmood',
        'phone': '0321-9876543',
        'city': 'Lahore',
        'address': 'Hafeez Centre, 4th Floor',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Premium accessories brand distributor',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'supplier',
        'name': 'Hoco & Remax Agency Lahore',
        'contact_person': 'Mian Farhan',
        'phone': '0333-4455667',
        'city': 'Lahore',
        'address': 'Hall Road, Electronics Market',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Authorized dealer for Hoco cables & power banks',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'supplier',
        'name': 'Kingston & Sandisk Memory Hub',
        'contact_person': 'Zahid Qureshi',
        'phone': '0312-5566778',
        'city': 'Karachi',
        'address': 'Regal Trade Square, Saddar',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Original memory cards and USB flash drives',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'supplier',
        'name': 'Crown Glass & Covers Wholesale',
        'contact_person': 'Babar Ali',
        'phone': '0345-1122334',
        'city': 'Rawalpindi',
        'address': 'Babban Khan Market, Saddar',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Tempered glass, silicon & shockproof covers bulk',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
    ];

    final Map<int, int> supplierIds = {};
    for (int i = 0; i < supplierData.length; i++) {
      final id = await db.insert('parties', supplierData[i]);
      supplierIds[i + 1] = id;
    }

    // 3. Seed 8 Dealer Customers
    final List<Map<String, dynamic>> customerData = [
      {
        'type': 'customer',
        'name': 'Al-Rehman Mobile Saddar',
        'contact_person': 'Sheikh Imran',
        'phone': '0301-2345678',
        'city': 'Karachi',
        'address': 'Shop 12, Star City Mall, Saddar',
        'credit_limit_paisa': 15000000, // PKR 150,000 credit limit
        'payment_terms': 'Weekly Saturday',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'High volume dealer, reliable payment history',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Bilal Telecom Hafeez Centre',
        'contact_person': 'Bilal Ahmed',
        'phone': '0322-3456789',
        'city': 'Lahore',
        'address': 'Shop 85, Basement, Hafeez Centre',
        'credit_limit_paisa': 20000000, // PKR 200,000
        'payment_terms': 'Net 15 Days',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Regular buyer of chargers and premium earbuds',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Usman Cellular Rawalpindi',
        'contact_person': 'Chaudhry Usman',
        'phone': '0334-4567890',
        'city': 'Rawalpindi',
        'address': 'The Mall, Mobile Market',
        'credit_limit_paisa': 10000000,
        'payment_terms': 'Net 10 Days',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Buys phone cases and glass protectors in cartons',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Khan Mobiles Karkhano',
        'contact_person': 'Gul Khan',
        'phone': '0315-5678901',
        'city': 'Peshawar',
        'address': 'Karkhano Market, Sitara Plaza',
        'credit_limit_paisa': 8000000,
        'payment_terms': 'Cash on Delivery',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Peshawar border dealer, bulk cables & adapters',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Madina Cellular Kutchery Road',
        'contact_person': 'Abdul Sattar',
        'phone': '0346-6789012',
        'city': 'Faisalabad',
        'address': 'Kutchery Bazaar, Mobile Plaza',
        'credit_limit_paisa': 12000000,
        'payment_terms': 'Net 15 Days',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Faisalabad regional wholesale dealer',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Khyber Accessories Quetta',
        'contact_person': 'Naimatullah',
        'phone': '0308-7890123',
        'city': 'Quetta',
        'address': 'Liaquat Bazaar, Mobile Hub',
        'credit_limit_paisa': 6000000,
        'payment_terms': 'Cash Only',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Car chargers, mounts and heavy power banks',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Gujranwala Telecom Centre',
        'contact_person': 'Rana Waqas',
        'phone': '0323-8901234',
        'city': 'Gujranwala',
        'address': 'Model Town Market',
        'credit_limit_paisa': 10000000,
        'payment_terms': 'Weekly Thursday',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'Full line wholesale accessories retailer',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
      {
        'type': 'customer',
        'name': 'Multan Mobile Zone',
        'contact_person': 'Makhdoom Shah',
        'phone': '0336-9012345',
        'city': 'Multan',
        'address': 'Bohar Gate, Electronics Market',
        'credit_limit_paisa': 14000000,
        'payment_terms': 'Net 15 Days',
        'opening_balance_paisa': 0,
        'current_balance_paisa': 0,
        'notes': 'South Punjab regional sub-distributor',
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      },
    ];

    final Map<int, int> customerIds = {};
    for (int i = 0; i < customerData.length; i++) {
      final id = await db.insert('parties', customerData[i]);
      customerIds[i + 1] = id;
    }

    // 4. Seed 36 Realistic Mobile Accessories SKUs with offline bundled photos
    final List<Map<String, dynamic>> rawProducts = [
      // Chargers (4 SKUs)
      {
        'sku': 'CHG-PD-20W-WHT',
        'name': '20W PD Type-C Fast Charger',
        'category': 'Chargers',
        'brand': 'Faster',
        'compatible_model': 'iPhone 11-15 / Samsung',
        'color_spec': 'Glossy White',
        'image_path': 'assets/images/products/charger_20w.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 45000, // PKR 450
        'wholesale_price_paisa': 65000, // PKR 650
        'min_selling_price_paisa': 58000, // PKR 580
        'tier_min_qty': 50,
        'tier_price_paisa': 60000, // PKR 600
        'reorder_level': 20,
      },
      {
        'sku': 'CHG-PD-20W-BLK',
        'name': '20W PD Type-C Fast Charger (Black)',
        'category': 'Chargers',
        'brand': 'Faster',
        'compatible_model': 'Universal Type-C',
        'color_spec': 'Matte Black',
        'image_path': 'assets/images/products/charger_20w.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 45000,
        'wholesale_price_paisa': 65000,
        'min_selling_price_paisa': 58000,
        'tier_min_qty': 50,
        'tier_price_paisa': 60000,
        'reorder_level': 20,
      },
      {
        'sku': 'CHG-GAN-65W',
        'name': '65W GaN Dual Port Fast Adapter (PD+QC)',
        'category': 'Chargers',
        'brand': 'Baseus',
        'compatible_model': 'Laptops, MacBooks, Flagship Phones',
        'color_spec': 'Space Black',
        'image_path': 'assets/images/products/charger_65w_gan.png',
        'pieces_per_box': 20,
        'cost_price_paisa': 210000, // PKR 2,100
        'wholesale_price_paisa': 295000, // PKR 2,950
        'min_selling_price_paisa': 270000,
        'tier_min_qty': 20,
        'tier_price_paisa': 280000,
        'reorder_level': 10,
      },
      {
        'sku': 'CHG-QC3-18W',
        'name': '18W QC3.0 USB Quick Charger',
        'category': 'Chargers',
        'brand': 'Ronin',
        'compatible_model': 'Android / Redmi / Infinix',
        'color_spec': 'Pure White',
        'image_path': 'assets/images/products/charger_20w.png',
        'pieces_per_box': 60,
        'cost_price_paisa': 28000, // PKR 280
        'wholesale_price_paisa': 42000, // PKR 420
        'min_selling_price_paisa': 38000,
        'tier_min_qty': 60,
        'tier_price_paisa': 39000,
        'reorder_level': 25,
      },

      // Charging Cables (4 SKUs)
      {
        'sku': 'CBL-TC-TC-100W',
        'name': '100W PD Braided Type-C to Type-C Cable',
        'category': 'Charging Cables',
        'brand': 'Baseus',
        'compatible_model': 'MacBook, iPad Pro, Galaxy S24, Xiaomi',
        'color_spec': 'Gunmetal Grey / 1.2M',
        'image_path': 'assets/images/products/cable_type_c_100w.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 22000, // PKR 220
        'wholesale_price_paisa': 35000, // PKR 350
        'min_selling_price_paisa': 31000,
        'tier_min_qty': 50,
        'tier_price_paisa': 32000,
        'reorder_level': 30,
      },
      {
        'sku': 'CBL-TC-IP-20W',
        'name': '20W PD Type-C to Lightning Cable',
        'category': 'Charging Cables',
        'brand': 'Faster',
        'compatible_model': 'iPhone 11-14 Series',
        'color_spec': 'Braided Silver / 1M',
        'image_path': 'assets/images/products/cable_type_c_100w.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 18000, // PKR 180
        'wholesale_price_paisa': 29000, // PKR 290
        'min_selling_price_paisa': 26000,
        'tier_min_qty': 50,
        'tier_price_paisa': 27000,
        'reorder_level': 25,
      },
      {
        'sku': 'CBL-3IN1-FAST',
        'name': '3-in-1 Fast Charging Cable (IP/Type-C/Micro)',
        'category': 'Charging Cables',
        'brand': 'Remax',
        'compatible_model': 'Universal All Phones',
        'color_spec': 'Flame Red / Heavy Duty',
        'image_path': 'assets/images/products/cable_3in1_multi.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 25000, // PKR 250
        'wholesale_price_paisa': 42000, // PKR 420
        'min_selling_price_paisa': 38000,
        'tier_min_qty': 50,
        'tier_price_paisa': 39000,
        'reorder_level': 20,
      },
      {
        'sku': 'CBL-USB-MIC-2A',
        'name': 'Micro-USB Heavy Copper Sync Cable',
        'category': 'Charging Cables',
        'brand': 'Hoco',
        'compatible_model': 'Infinix, Tecno, Feature Phones',
        'color_spec': 'Classic White / 1M',
        'image_path': 'assets/images/products/cable_type_c_100w.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 9000, // PKR 90
        'wholesale_price_paisa': 16000, // PKR 160
        'min_selling_price_paisa': 14000,
        'tier_min_qty': 100,
        'tier_price_paisa': 14500,
        'reorder_level': 40,
      },

      // Power Banks (3 SKUs)
      {
        'sku': 'PB-10K-SLIM',
        'name': '10,000mAh Slim PD Power Bank with LED',
        'category': 'Power Banks',
        'brand': 'Faster',
        'compatible_model': 'Universal USB / Type-C',
        'color_spec': 'Titanium Grey',
        'image_path': 'assets/images/products/powerbank_10000mah.png',
        'pieces_per_box': 20,
        'cost_price_paisa': 185000, // PKR 1,850
        'wholesale_price_paisa': 260000, // PKR 2,600
        'min_selling_price_paisa': 240000,
        'tier_min_qty': 20,
        'tier_price_paisa': 248000,
        'reorder_level': 10,
      },
      {
        'sku': 'PB-20K-22W',
        'name': '20,000mAh 22.5W Fast Power Bank Digital Display',
        'category': 'Power Banks',
        'brand': 'Ronin',
        'compatible_model': 'Fast Charge All Phones',
        'color_spec': 'Midnight Blue',
        'image_path': 'assets/images/products/powerbank_20000mah.png',
        'pieces_per_box': 15,
        'cost_price_paisa': 285000, // PKR 2,850
        'wholesale_price_paisa': 390000, // PKR 3,900
        'min_selling_price_paisa': 360000,
        'tier_min_qty': 15,
        'tier_price_paisa': 370000,
        'reorder_level': 8,
      },
      {
        'sku': 'PB-30K-HD',
        'name': '30,000mAh Heavy Duty Emergency Power Bank',
        'category': 'Power Banks',
        'brand': 'Hoco',
        'compatible_model': 'High Capacity Tablets & Mobiles',
        'color_spec': 'Matte Black',
        'image_path': 'assets/images/products/powerbank_20000mah.png',
        'pieces_per_box': 10,
        'cost_price_paisa': 420000, // PKR 4,200
        'wholesale_price_paisa': 560000, // PKR 5,600
        'min_selling_price_paisa': 520000,
        'tier_min_qty': 10,
        'tier_price_paisa': 535000,
        'reorder_level': 5,
      },

      // Wireless Earbuds & Wired Earphones (4 SKUs)
      {
        'sku': 'TWS-ANC-PRO',
        'name': 'TWS Wireless Earbuds with ANC & ENC',
        'category': 'Wireless Earbuds',
        'brand': 'Faster',
        'compatible_model': 'Bluetooth 5.3 iOS & Android',
        'color_spec': 'Pearl White',
        'image_path': 'assets/images/products/tws_earbuds_anc.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 175000, // PKR 1,750
        'wholesale_price_paisa': 260000, // PKR 2,600
        'min_selling_price_paisa': 235000,
        'tier_min_qty': 30,
        'tier_price_paisa': 245000,
        'reorder_level': 15,
      },
      {
        'sku': 'TWS-GAME-RGB',
        'name': 'Low Latency Gaming TWS Earbuds RGB',
        'category': 'Wireless Earbuds',
        'brand': 'Audionic',
        'compatible_model': 'Gaming Mobile / PUBG',
        'color_spec': 'Carbon Black',
        'image_path': 'assets/images/products/tws_earbuds_anc.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 145000, // PKR 1,450
        'wholesale_price_paisa': 220000, // PKR 2,200
        'min_selling_price_paisa': 200000,
        'tier_min_qty': 30,
        'tier_price_paisa': 208000,
        'reorder_level': 12,
      },
      {
        'sku': 'EAR-BASS-35',
        'name': 'Deep Bass 3.5mm Metal Wired Earphones',
        'category': 'Wired Earphones',
        'brand': 'Ronin',
        'compatible_model': '3.5mm Jack Phones',
        'color_spec': 'Gunmetal & Black',
        'image_path': 'assets/images/products/wired_earphones_bass.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 16000, // PKR 160
        'wholesale_price_paisa': 28000, // PKR 280
        'min_selling_price_paisa': 24000,
        'tier_min_qty': 100,
        'tier_price_paisa': 25500,
        'reorder_level': 35,
      },
      {
        'sku': 'EAR-TC-DIGI',
        'name': 'Type-C DAC High-Res Stereo Earphones',
        'category': 'Wired Earphones',
        'brand': 'Faster',
        'compatible_model': 'Samsung S Series, OnePlus, iPad',
        'color_spec': 'Clean White',
        'image_path': 'assets/images/products/wired_earphones_bass.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 32000, // PKR 320
        'wholesale_price_paisa': 52000, // PKR 520
        'min_selling_price_paisa': 46000,
        'tier_min_qty': 50,
        'tier_price_paisa': 48000,
        'reorder_level': 20,
      },

      // Phone Covers (4 SKUs)
      {
        'sku': 'COV-MAG-IP15',
        'name': 'MagSafe Clear Anti-Yellow Case iPhone 15 Pro',
        'category': 'Phone Covers',
        'brand': 'ClearShield',
        'compatible_model': 'iPhone 15 Pro',
        'color_spec': 'Crystal Clear',
        'image_path': 'assets/images/products/case_magsafe_clear.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 18000, // PKR 180
        'wholesale_price_paisa': 34000, // PKR 340
        'min_selling_price_paisa': 29000,
        'tier_min_qty': 50,
        'tier_price_paisa': 30500,
        'reorder_level': 20,
      },
      {
        'sku': 'COV-MAG-IP14',
        'name': 'MagSafe Clear Case iPhone 14',
        'category': 'Phone Covers',
        'brand': 'ClearShield',
        'compatible_model': 'iPhone 14',
        'color_spec': 'Crystal Clear',
        'image_path': 'assets/images/products/case_magsafe_clear.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 16000,
        'wholesale_price_paisa': 30000,
        'min_selling_price_paisa': 26000,
        'tier_min_qty': 50,
        'tier_price_paisa': 27500,
        'reorder_level': 20,
      },
      {
        'sku': 'COV-ARM-S24',
        'name': 'Shockproof Armor Heavy Duty Case Galaxy S24',
        'category': 'Phone Covers',
        'brand': 'RuggedArmor',
        'compatible_model': 'Samsung Galaxy S24 Ultra',
        'color_spec': 'Matte Black Carbon',
        'image_path': 'assets/images/products/case_armor_rugged.png',
        'pieces_per_box': 40,
        'cost_price_paisa': 21000, // PKR 210
        'wholesale_price_paisa': 38000, // PKR 380
        'min_selling_price_paisa': 33000,
        'tier_min_qty': 40,
        'tier_price_paisa': 35000,
        'reorder_level': 15,
      },
      {
        'sku': 'COV-SIL-A54',
        'name': 'Liquid Silicone Velvet Case Galaxy A54',
        'category': 'Phone Covers',
        'brand': 'SoftTouch',
        'compatible_model': 'Samsung Galaxy A54 5G',
        'color_spec': 'Midnight Navy',
        'image_path': 'assets/images/products/case_armor_rugged.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 14000,
        'wholesale_price_paisa': 26000,
        'min_selling_price_paisa': 22000,
        'tier_min_qty': 50,
        'tier_price_paisa': 23500,
        'reorder_level': 20,
      },

      // Screen Protectors (4 SKUs)
      {
        'sku': 'GLS-9D-IP15P',
        'name': '9D Full Glue Curved Tempered Glass iPhone 15 Pro',
        'category': 'Screen Protectors',
        'brand': 'KingGlass',
        'compatible_model': 'iPhone 15 Pro',
        'color_spec': 'Black Edge HD',
        'image_path': 'assets/images/products/tempered_glass_9d.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 4500, // PKR 45
        'wholesale_price_paisa': 9500, // PKR 95
        'min_selling_price_paisa': 8000,
        'tier_min_qty': 100,
        'tier_price_paisa': 8500,
        'reorder_level': 50,
      },
      {
        'sku': 'GLS-9D-IP14',
        'name': '9D Full Glue Tempered Glass iPhone 14/13',
        'category': 'Screen Protectors',
        'brand': 'KingGlass',
        'compatible_model': 'iPhone 14 / iPhone 13',
        'color_spec': 'Black Edge HD',
        'image_path': 'assets/images/products/tempered_glass_9d.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 4200, // PKR 42
        'wholesale_price_paisa': 9000, // PKR 90
        'min_selling_price_paisa': 7500,
        'tier_min_qty': 100,
        'tier_price_paisa': 8000,
        'reorder_level': 50,
      },
      {
        'sku': 'GLS-PRV-IP15',
        'name': 'Privacy Anti-Spy Matte Glass iPhone 15',
        'category': 'Screen Protectors',
        'brand': 'KingGlass',
        'compatible_model': 'iPhone 15',
        'color_spec': 'Smoked Privacy Matte',
        'image_path': 'assets/images/products/tempered_glass_9d.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 8500, // PKR 85
        'wholesale_price_paisa': 16500, // PKR 165
        'min_selling_price_paisa': 14000,
        'tier_min_qty': 50,
        'tier_price_paisa': 15000,
        'reorder_level': 25,
      },
      {
        'sku': 'GLS-11D-A14',
        'name': '11D Super Hardness Glass Galaxy A14 / A15',
        'category': 'Screen Protectors',
        'brand': 'Crown',
        'compatible_model': 'Samsung Galaxy A14 / A15',
        'color_spec': 'Full Coverage Clear',
        'image_path': 'assets/images/products/tempered_glass_9d.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 3800, // PKR 38
        'wholesale_price_paisa': 8000, // PKR 80
        'min_selling_price_paisa': 7000,
        'tier_min_qty': 100,
        'tier_price_paisa': 7200,
        'reorder_level': 50,
      },

      // Car Chargers (3 SKUs)
      {
        'sku': 'CAR-36W-MTL',
        'name': '36W Dual Fast Car Charger (PD+QC3.0)',
        'category': 'Car Chargers',
        'brand': 'Baseus',
        'compatible_model': '12V-24V All Vehicles',
        'color_spec': 'Space Aluminum Alloy',
        'image_path': 'assets/images/products/car_charger_36w.png',
        'pieces_per_box': 40,
        'cost_price_paisa': 52000, // PKR 520
        'wholesale_price_paisa': 85000, // PKR 850
        'min_selling_price_paisa': 75000,
        'tier_min_qty': 40,
        'tier_price_paisa': 78000,
        'reorder_level': 15,
      },
      {
        'sku': 'CAR-45W-DISP',
        'name': '45W Metal Car Charger with Voltage Display',
        'category': 'Car Chargers',
        'brand': 'Faster',
        'compatible_model': 'Car / SUV / Truck',
        'color_spec': 'Gunmetal Dark',
        'image_path': 'assets/images/products/car_charger_36w.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 68000, // PKR 680
        'wholesale_price_paisa': 110000, // PKR 1,100
        'min_selling_price_paisa': 98000,
        'tier_min_qty': 30,
        'tier_price_paisa': 102000,
        'reorder_level': 10,
      },
      {
        'sku': 'CAR-BLU-FM',
        'name': 'Bluetooth 5.0 FM Transmitter & Car Charger',
        'category': 'Car Chargers',
        'brand': 'Remax',
        'compatible_model': 'Universal Car Audio & Phone',
        'color_spec': 'Carbon Black',
        'image_path': 'assets/images/products/car_charger_36w.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 62000,
        'wholesale_price_paisa': 98000,
        'min_selling_price_paisa': 88000,
        'tier_min_qty': 30,
        'tier_price_paisa': 92000,
        'reorder_level': 10,
      },

      // Mobile Holders (3 SKUs)
      {
        'sku': 'HLD-MAG-VENT',
        'name': '360° Magnetic Car Air Vent Mount Holder',
        'category': 'Mobile Holders',
        'brand': 'Baseus',
        'compatible_model': 'Universal Smartphones',
        'color_spec': 'Matte Black & Metal',
        'image_path': 'assets/images/products/holder_magnetic_car.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 28000, // PKR 280
        'wholesale_price_paisa': 48000, // PKR 480
        'min_selling_price_paisa': 42000,
        'tier_min_qty': 50,
        'tier_price_paisa': 44000,
        'reorder_level': 20,
      },
      {
        'sku': 'HLD-GRV-DASH',
        'name': 'Gravity Dashboard Suction Car Phone Mount',
        'category': 'Mobile Holders',
        'brand': 'Hoco',
        'compatible_model': '4.7 to 7.0 inch Phones',
        'color_spec': 'Piano Black',
        'image_path': 'assets/images/products/holder_magnetic_car.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 42000, // PKR 420
        'wholesale_price_paisa': 70000, // PKR 700
        'min_selling_price_paisa': 62000,
        'tier_min_qty': 30,
        'tier_price_paisa': 65000,
        'reorder_level': 15,
      },
      {
        'sku': 'HLD-DSK-MTL',
        'name': 'Foldable Aluminum Desktop Stand for Mobile/Tablet',
        'category': 'Mobile Holders',
        'brand': 'Faster',
        'compatible_model': 'Phones & Tablets up to 11 inch',
        'color_spec': 'Silver Aluminum',
        'image_path': 'assets/images/products/holder_magnetic_car.png',
        'pieces_per_box': 40,
        'cost_price_paisa': 35000,
        'wholesale_price_paisa': 58000,
        'min_selling_price_paisa': 52000,
        'tier_min_qty': 40,
        'tier_price_paisa': 54000,
        'reorder_level': 15,
      },

      // OTG Adapters (2 SKUs)
      {
        'sku': 'OTG-TC-USB3',
        'name': 'Metal Type-C to USB 3.0 High Speed OTG',
        'category': 'OTG Adapters',
        'brand': 'Baseus',
        'compatible_model': 'Android Type-C Phones, Laptops',
        'color_spec': 'Zinc Alloy Gunmetal',
        'image_path': 'assets/images/products/otg_type_c_usb3.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 8500, // PKR 85
        'wholesale_price_paisa': 16000, // PKR 160
        'min_selling_price_paisa': 13500,
        'tier_min_qty': 100,
        'tier_price_paisa': 14000,
        'reorder_level': 40,
      },
      {
        'sku': 'OTG-IP-USB',
        'name': 'Lightning to USB Camera Reader & OTG Adapter',
        'category': 'OTG Adapters',
        'brand': 'Faster',
        'compatible_model': 'iPhone & iPad',
        'color_spec': 'Glossy White',
        'image_path': 'assets/images/products/otg_type_c_usb3.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 14000,
        'wholesale_price_paisa': 26000,
        'min_selling_price_paisa': 22000,
        'tier_min_qty': 100,
        'tier_price_paisa': 23500,
        'reorder_level': 30,
      },

      // Memory Cards (3 SKUs)
      {
        'sku': 'MEM-SD-32G',
        'name': 'MicroSD Card 32GB Class 10 High Speed',
        'category': 'Memory Cards',
        'brand': 'Kingston',
        'compatible_model': 'Smartphones, Dash Cams, Security Cams',
        'color_spec': 'Black / Red 80MB/s',
        'image_path': 'assets/images/products/microsd_64gb_fast.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 58000, // PKR 580
        'wholesale_price_paisa': 82000, // PKR 820
        'min_selling_price_paisa': 75000,
        'tier_min_qty': 50,
        'tier_price_paisa': 78000,
        'reorder_level': 25,
      },
      {
        'sku': 'MEM-SD-64G',
        'name': 'MicroSD Card 64GB UHS-I 100MB/s 4K',
        'category': 'Memory Cards',
        'brand': 'SanDisk',
        'compatible_model': 'Smartphones & 4K Recording',
        'color_spec': 'Red & Gold Ultra',
        'image_path': 'assets/images/products/microsd_64gb_fast.png',
        'pieces_per_box': 50,
        'cost_price_paisa': 88000, // PKR 880
        'wholesale_price_paisa': 122000, // PKR 1,220
        'min_selling_price_paisa': 110000,
        'tier_min_qty': 50,
        'tier_price_paisa': 115000,
        'reorder_level': 20,
      },
      {
        'sku': 'MEM-SD-128G',
        'name': 'MicroSD Card 128GB Pro Plus Extreme 130MB/s',
        'category': 'Memory Cards',
        'brand': 'Samsung',
        'compatible_model': 'High Performance Mobiles & Cameras',
        'color_spec': 'Blue Evo Plus',
        'image_path': 'assets/images/products/microsd_64gb_fast.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 155000, // PKR 1,550
        'wholesale_price_paisa': 215000, // PKR 2,150
        'min_selling_price_paisa': 195000,
        'tier_min_qty': 30,
        'tier_price_paisa': 205000,
        'reorder_level': 15,
      },

      // USB Accessories (3 SKUs)
      {
        'sku': 'USB-HUB-4P',
        'name': '4-Port USB 3.0 / Type-C Multi Splitter Hub',
        'category': 'USB Accessories',
        'brand': 'Baseus',
        'compatible_model': 'PC, Mac, OTG Phones',
        'color_spec': 'Space Gray Aluminum',
        'image_path': 'assets/images/products/usb_hub_4port.png',
        'pieces_per_box': 30,
        'cost_price_paisa': 75000, // PKR 750
        'wholesale_price_paisa': 120000, // PKR 1,200
        'min_selling_price_paisa': 105000,
        'tier_min_qty': 30,
        'tier_price_paisa': 112000,
        'reorder_level': 12,
      },
      {
        'sku': 'USB-BT-53',
        'name': 'Bluetooth 5.3 Nano USB Wireless Dongle',
        'category': 'USB Accessories',
        'brand': 'Faster',
        'compatible_model': 'Desktop PC, Sound System',
        'color_spec': 'Nano Black Gold Pin',
        'image_path': 'assets/images/products/usb_hub_4port.png',
        'pieces_per_box': 100,
        'cost_price_paisa': 22000, // PKR 220
        'wholesale_price_paisa': 39000, // PKR 390
        'min_selling_price_paisa': 34000,
        'tier_min_qty': 50,
        'tier_price_paisa': 36000,
        'reorder_level': 25,
      },
      {
        'sku': 'USB-LIGHT-LED',
        'name': 'Flexible USB Mini LED Light for Keyboard/PowerBank',
        'category': 'USB Accessories',
        'brand': 'OEM',
        'compatible_model': 'USB 5V Port',
        'color_spec': 'Assorted Colors',
        'image_path': 'assets/images/products/usb_hub_4port.png',
        'pieces_per_box': 200,
        'cost_price_paisa': 3500, // PKR 35
        'wholesale_price_paisa': 7500, // PKR 75
        'min_selling_price_paisa': 6000,
        'tier_min_qty': 100,
        'tier_price_paisa': 6500,
        'reorder_level': 50,
      },
    ];

    final Map<String, Product> productMap = {};
    for (final pData in rawProducts) {
      final pMap = {
        ...pData,
        'current_stock_pieces': 0, // Starts at 0, filled by Purchases & Opening movements
        'damaged_stock_pieces': 0,
        'is_active': 1,
        'created_at': dateOffset(30),
        'updated_at': dateOffset(30),
      };
      final id = await db.insert('products', pMap);
      productMap[pData['sku'] as String] = Product.fromMap({...pMap, 'id': id});
    }

    // 5. Seed 8 Posted Purchases via AccountingService
    final acc = AccountingService.instance;

    // Purchase 1: Chargers from Baseus (28 days ago)
    final p1Items = [
      PurchaseItem(
        productId: productMap['CHG-PD-20W-WHT']!.id!,
        sku: 'CHG-PD-20W-WHT',
        productName: productMap['CHG-PD-20W-WHT']!.name,
        packUnit: PackUnit.box,
        packQty: 4, // 4 boxes * 50 = 200 pcs
        piecesPerPack: 50,
        totalPieces: 200,
        unitRatePaisa: 45000,
        netTotalPaisa: 200 * 45000, // PKR 90,000
      ),
      PurchaseItem(
        productId: productMap['CHG-GAN-65W']!.id!,
        sku: 'CHG-GAN-65W',
        productName: productMap['CHG-GAN-65W']!.name,
        packUnit: PackUnit.box,
        packQty: 3, // 3 * 20 = 60 pcs
        piecesPerPack: 20,
        totalPieces: 60,
        unitRatePaisa: 210000,
        netTotalPaisa: 60 * 210000, // PKR 126,000
      ),
    ];
    final p1Subtotal = p1Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-001',
      date: dateOffset(28),
      supplierId: supplierIds[2]!, // Baseus
      supplierName: 'Baseus Official Distributor PK',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: p1Subtotal,
      grandTotalPaisa: p1Subtotal,
      paidPaisa: p1Subtotal,
      duePaisa: 0,
      paymentMethod: 'bank',
      createdAt: dateOffset(28),
      items: p1Items,
    ));

    // Purchase 2: Cables from Shenzhen Direct (26 days ago)
    final p2Items = [
      PurchaseItem(
        productId: productMap['CBL-TC-TC-100W']!.id!,
        sku: 'CBL-TC-TC-100W',
        productName: productMap['CBL-TC-TC-100W']!.name,
        packUnit: PackUnit.box,
        packQty: 3, // 300 pcs
        piecesPerPack: 100,
        totalPieces: 300,
        unitRatePaisa: 22000,
        netTotalPaisa: 300 * 22000, // PKR 66,000
      ),
      PurchaseItem(
        productId: productMap['CBL-3IN1-FAST']!.id!,
        sku: 'CBL-3IN1-FAST',
        productName: productMap['CBL-3IN1-FAST']!.name,
        packUnit: PackUnit.box,
        packQty: 4, // 200 pcs
        piecesPerPack: 50,
        totalPieces: 200,
        unitRatePaisa: 25000,
        netTotalPaisa: 200 * 25000, // PKR 50,000
      ),
      PurchaseItem(
        productId: productMap['CBL-USB-MIC-2A']!.id!,
        sku: 'CBL-USB-MIC-2A',
        productName: productMap['CBL-USB-MIC-2A']!.name,
        packUnit: PackUnit.box,
        packQty: 4, // 400 pcs
        piecesPerPack: 100,
        totalPieces: 400,
        unitRatePaisa: 9000,
        netTotalPaisa: 400 * 9000, // PKR 36,000
      ),
    ];
    final p2Subtotal = p2Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-002',
      date: dateOffset(26),
      supplierId: supplierIds[1]!, // Shenzhen
      supplierName: 'Shenzhen Direct Importers Karachi',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.partial,
      subtotalPaisa: p2Subtotal,
      grandTotalPaisa: p2Subtotal,
      paidPaisa: 10000000, // PKR 100,000 paid
      duePaisa: p2Subtotal - 10000000,
      paymentMethod: 'bank',
      createdAt: dateOffset(26),
      items: p2Items,
    ));

    // Purchase 3: Power Banks from Hoco (24 days ago)
    final p3Items = [
      PurchaseItem(
        productId: productMap['PB-10K-SLIM']!.id!,
        sku: 'PB-10K-SLIM',
        productName: productMap['PB-10K-SLIM']!.name,
        packUnit: PackUnit.box,
        packQty: 5, // 100 pcs
        piecesPerPack: 20,
        totalPieces: 100,
        unitRatePaisa: 185000,
        netTotalPaisa: 100 * 185000, // PKR 185,000
      ),
      PurchaseItem(
        productId: productMap['PB-20K-22W']!.id!,
        sku: 'PB-20K-22W',
        productName: productMap['PB-20K-22W']!.name,
        packUnit: PackUnit.box,
        packQty: 4, // 60 pcs
        piecesPerPack: 15,
        totalPieces: 60,
        unitRatePaisa: 285000,
        netTotalPaisa: 60 * 285000, // PKR 171,000
      ),
    ];
    final p3Subtotal = p3Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-003',
      date: dateOffset(24),
      supplierId: supplierIds[3]!,
      supplierName: 'Hoco & Remax Agency Lahore',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.unpaid,
      subtotalPaisa: p3Subtotal,
      grandTotalPaisa: p3Subtotal,
      paidPaisa: 0,
      duePaisa: p3Subtotal,
      paymentMethod: 'credit',
      createdAt: dateOffset(24),
      items: p3Items,
    ));

    // Purchase 4: Earbuds & Earphones from Baseus (22 days ago)
    final p4Items = [
      PurchaseItem(
        productId: productMap['TWS-ANC-PRO']!.id!,
        sku: 'TWS-ANC-PRO',
        productName: productMap['TWS-ANC-PRO']!.name,
        packUnit: PackUnit.box,
        packQty: 4, // 120 pcs
        piecesPerPack: 30,
        totalPieces: 120,
        unitRatePaisa: 175000,
        netTotalPaisa: 120 * 175000, // PKR 210,000
      ),
      PurchaseItem(
        productId: productMap['EAR-BASS-35']!.id!,
        sku: 'EAR-BASS-35',
        productName: productMap['EAR-BASS-35']!.name,
        packUnit: PackUnit.box,
        packQty: 3, // 300 pcs
        piecesPerPack: 100,
        totalPieces: 300,
        unitRatePaisa: 16000,
        netTotalPaisa: 300 * 16000, // PKR 48,000
      ),
    ];
    final p4Subtotal = p4Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-004',
      date: dateOffset(22),
      supplierId: supplierIds[2]!,
      supplierName: 'Baseus Official Distributor PK',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: p4Subtotal,
      grandTotalPaisa: p4Subtotal,
      paidPaisa: p4Subtotal,
      duePaisa: 0,
      paymentMethod: 'bank',
      createdAt: dateOffset(22),
      items: p4Items,
    ));

    // Purchase 5: Covers & Glass from Crown Glass (20 days ago)
    final p5Items = [
      PurchaseItem(
        productId: productMap['COV-MAG-IP15']!.id!,
        sku: 'COV-MAG-IP15',
        productName: productMap['COV-MAG-IP15']!.name,
        packUnit: PackUnit.box,
        packQty: 5, // 250 pcs
        piecesPerPack: 50,
        totalPieces: 250,
        unitRatePaisa: 18000,
        netTotalPaisa: 250 * 18000, // PKR 45,000
      ),
      PurchaseItem(
        productId: productMap['COV-ARM-S24']!.id!,
        sku: 'COV-ARM-S24',
        productName: productMap['COV-ARM-S24']!.name,
        packUnit: PackUnit.box,
        packQty: 4, // 160 pcs
        piecesPerPack: 40,
        totalPieces: 160,
        unitRatePaisa: 21000,
        netTotalPaisa: 160 * 21000, // PKR 33,600
      ),
      PurchaseItem(
        productId: productMap['GLS-9D-IP15P']!.id!,
        sku: 'GLS-9D-IP15P',
        productName: productMap['GLS-9D-IP15P']!.name,
        packUnit: PackUnit.box,
        packQty: 5, // 500 pcs
        piecesPerPack: 100,
        totalPieces: 500,
        unitRatePaisa: 4500,
        netTotalPaisa: 500 * 4500, // PKR 22,500
      ),
    ];
    final p5Subtotal = p5Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-005',
      date: dateOffset(20),
      supplierId: supplierIds[5]!,
      supplierName: 'Crown Glass & Covers Wholesale',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: p5Subtotal,
      grandTotalPaisa: p5Subtotal,
      paidPaisa: p5Subtotal,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(20),
      items: p5Items,
    ));

    // Purchase 6: Memory Cards from Kingston & Sandisk Hub (18 days ago)
    final p6Items = [
      PurchaseItem(
        productId: productMap['MEM-SD-32G']!.id!,
        sku: 'MEM-SD-32G',
        productName: productMap['MEM-SD-32G']!.name,
        packUnit: PackUnit.box,
        packQty: 2, // 100 pcs
        piecesPerPack: 50,
        totalPieces: 100,
        unitRatePaisa: 58000,
        netTotalPaisa: 100 * 58000, // PKR 58,000
      ),
      PurchaseItem(
        productId: productMap['MEM-SD-64G']!.id!,
        sku: 'MEM-SD-64G',
        productName: productMap['MEM-SD-64G']!.name,
        packUnit: PackUnit.box,
        packQty: 2, // 100 pcs
        piecesPerPack: 50,
        totalPieces: 100,
        unitRatePaisa: 88000,
        netTotalPaisa: 100 * 88000, // PKR 88,000
      ),
    ];
    final p6Subtotal = p6Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-006',
      date: dateOffset(18),
      supplierId: supplierIds[4]!,
      supplierName: 'Kingston & Sandisk Memory Hub',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.partial,
      subtotalPaisa: p6Subtotal,
      grandTotalPaisa: p6Subtotal,
      paidPaisa: 8000000, // PKR 80,000 paid
      duePaisa: p6Subtotal - 8000000,
      paymentMethod: 'bank',
      createdAt: dateOffset(18),
      items: p6Items,
    ));

    // Purchase 7: Car Chargers & Mounts (14 days ago)
    final p7Items = [
      PurchaseItem(
        productId: productMap['CAR-36W-MTL']!.id!,
        sku: 'CAR-36W-MTL',
        productName: productMap['CAR-36W-MTL']!.name,
        packUnit: PackUnit.box,
        packQty: 3, // 120 pcs
        piecesPerPack: 40,
        totalPieces: 120,
        unitRatePaisa: 52000,
        netTotalPaisa: 120 * 52000, // PKR 62,400
      ),
      PurchaseItem(
        productId: productMap['HLD-MAG-VENT']!.id!,
        sku: 'HLD-MAG-VENT',
        productName: productMap['HLD-MAG-VENT']!.name,
        packUnit: PackUnit.box,
        packQty: 3, // 150 pcs
        piecesPerPack: 50,
        totalPieces: 150,
        unitRatePaisa: 28000,
        netTotalPaisa: 150 * 28000, // PKR 42,000
      ),
    ];
    final p7Subtotal = p7Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-007',
      date: dateOffset(14),
      supplierId: supplierIds[1]!,
      supplierName: 'Shenzhen Direct Importers Karachi',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: p7Subtotal,
      grandTotalPaisa: p7Subtotal,
      paidPaisa: p7Subtotal,
      duePaisa: 0,
      paymentMethod: 'bank',
      createdAt: dateOffset(14),
      items: p7Items,
    ));

    // Purchase 8: OTG & USB Hubs (8 days ago)
    final p8Items = [
      PurchaseItem(
        productId: productMap['OTG-TC-USB3']!.id!,
        sku: 'OTG-TC-USB3',
        productName: productMap['OTG-TC-USB3']!.name,
        packUnit: PackUnit.box,
        packQty: 2, // 200 pcs
        piecesPerPack: 100,
        totalPieces: 200,
        unitRatePaisa: 8500,
        netTotalPaisa: 200 * 8500, // PKR 17,000
      ),
      PurchaseItem(
        productId: productMap['USB-HUB-4P']!.id!,
        sku: 'USB-HUB-4P',
        productName: productMap['USB-HUB-4P']!.name,
        packUnit: PackUnit.box,
        packQty: 3, // 90 pcs
        piecesPerPack: 30,
        totalPieces: 90,
        unitRatePaisa: 75000,
        netTotalPaisa: 90 * 75000, // PKR 67,500
      ),
    ];
    final p8Subtotal = p8Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postPurchase(Purchase(
      refNumber: 'PUR-202610-008',
      date: dateOffset(8),
      supplierId: supplierIds[2]!,
      supplierName: 'Baseus Official Distributor PK',
      status: PurchaseStatus.received,
      paymentStatus: PaymentStatus.unpaid,
      subtotalPaisa: p8Subtotal,
      grandTotalPaisa: p8Subtotal,
      paidPaisa: 0,
      duePaisa: p8Subtotal,
      paymentMethod: 'credit',
      createdAt: dateOffset(8),
      items: p8Items,
    ));

    // 6. Seed 12 Posted Wholesale Sales via AccountingService across 25 days
    // Sale 1: Al-Rehman Mobile (25 days ago)
    final s1Items = [
      InvoiceItem(
        productId: productMap['CHG-PD-20W-WHT']!.id!,
        sku: 'CHG-PD-20W-WHT',
        productName: productMap['CHG-PD-20W-WHT']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 65000,
        netTotalPaisa: 24 * 65000, // PKR 15,600
        costPerPiecePaisa: 45000,
        totalCostPaisa: 24 * 45000,
      ),
      InvoiceItem(
        productId: productMap['CBL-TC-TC-100W']!.id!,
        sku: 'CBL-TC-TC-100W',
        productName: productMap['CBL-TC-TC-100W']!.name,
        packUnit: PackUnit.dozen,
        packQty: 3, // 36 pcs
        piecesPerPack: 12,
        totalPieces: 36,
        unitPricePaisa: 35000,
        netTotalPaisa: 36 * 35000, // PKR 12,600
        costPerPiecePaisa: 22000,
        totalCostPaisa: 36 * 22000,
      ),
    ];
    final s1Total = s1Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0001',
      date: dateOffset(25),
      customerId: customerIds[1]!, // Al-Rehman
      customerName: 'Al-Rehman Mobile Saddar',
      customerPhone: '0301-2345678',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: s1Total,
      grandTotalPaisa: s1Total,
      paidPaisa: s1Total,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(25),
      items: s1Items,
    ));

    // Sale 2: Bilal Telecom (23 days ago)
    final s2Items = [
      InvoiceItem(
        productId: productMap['PB-10K-SLIM']!.id!,
        sku: 'PB-10K-SLIM',
        productName: productMap['PB-10K-SLIM']!.name,
        packUnit: PackUnit.piece,
        packQty: 10,
        piecesPerPack: 1,
        totalPieces: 10,
        unitPricePaisa: 260000,
        netTotalPaisa: 10 * 260000, // PKR 26,000
        costPerPiecePaisa: 185000,
        totalCostPaisa: 10 * 185000,
      ),
      InvoiceItem(
        productId: productMap['TWS-ANC-PRO']!.id!,
        sku: 'TWS-ANC-PRO',
        productName: productMap['TWS-ANC-PRO']!.name,
        packUnit: PackUnit.piece,
        packQty: 15,
        piecesPerPack: 1,
        totalPieces: 15,
        unitPricePaisa: 260000,
        netTotalPaisa: 15 * 260000, // PKR 39,000
        costPerPiecePaisa: 175000,
        totalCostPaisa: 15 * 175000,
      ),
    ];
    final s2Total = s2Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0002',
      date: dateOffset(23),
      customerId: customerIds[2]!, // Bilal
      customerName: 'Bilal Telecom Hafeez Centre',
      customerPhone: '0322-3456789',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.partial,
      subtotalPaisa: s2Total,
      grandTotalPaisa: s2Total,
      paidPaisa: 3000000, // PKR 30,000 paid
      duePaisa: s2Total - 3000000,
      paymentMethod: 'bank',
      createdAt: dateOffset(23),
      items: s2Items,
    ));

    // Sale 3: Usman Cellular (21 days ago) - Full Box of Cases & Glass
    final s3Items = [
      InvoiceItem(
        productId: productMap['COV-MAG-IP15']!.id!,
        sku: 'COV-MAG-IP15',
        productName: productMap['COV-MAG-IP15']!.name,
        packUnit: PackUnit.box,
        packQty: 1, // 50 pcs (tier price applies: 305 PKR)
        piecesPerPack: 50,
        totalPieces: 50,
        unitPricePaisa: 30500,
        netTotalPaisa: 50 * 30500, // PKR 15,250
        costPerPiecePaisa: 18000,
        totalCostPaisa: 50 * 18000,
      ),
      InvoiceItem(
        productId: productMap['GLS-9D-IP15P']!.id!,
        sku: 'GLS-9D-IP15P',
        productName: productMap['GLS-9D-IP15P']!.name,
        packUnit: PackUnit.box,
        packQty: 1, // 100 pcs (tier rate 85 PKR)
        piecesPerPack: 100,
        totalPieces: 100,
        unitPricePaisa: 8500,
        netTotalPaisa: 100 * 8500, // PKR 8,500
        costPerPiecePaisa: 4500,
        totalCostPaisa: 100 * 4500,
      ),
    ];
    final s3Total = s3Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0003',
      date: dateOffset(21),
      customerId: customerIds[3]!,
      customerName: 'Usman Cellular Rawalpindi',
      customerPhone: '0334-4567890',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.unpaid,
      subtotalPaisa: s3Total,
      grandTotalPaisa: s3Total,
      paidPaisa: 0,
      duePaisa: s3Total,
      paymentMethod: 'credit',
      createdAt: dateOffset(21),
      items: s3Items,
    ));

    // Sale 4: Khan Mobiles Peshawar (19 days ago)
    final s4Items = [
      InvoiceItem(
        productId: productMap['CBL-3IN1-FAST']!.id!,
        sku: 'CBL-3IN1-FAST',
        productName: productMap['CBL-3IN1-FAST']!.name,
        packUnit: PackUnit.dozen,
        packQty: 3, // 36 pcs
        piecesPerPack: 12,
        totalPieces: 36,
        unitPricePaisa: 42000,
        netTotalPaisa: 36 * 42000, // PKR 15,120
        costPerPiecePaisa: 25000,
        totalCostPaisa: 36 * 25000,
      ),
      InvoiceItem(
        productId: productMap['CBL-USB-MIC-2A']!.id!,
        sku: 'CBL-USB-MIC-2A',
        productName: productMap['CBL-USB-MIC-2A']!.name,
        packUnit: PackUnit.box,
        packQty: 1, // 100 pcs
        piecesPerPack: 100,
        totalPieces: 100,
        unitPricePaisa: 14500,
        netTotalPaisa: 100 * 14500, // PKR 14,500
        costPerPiecePaisa: 9000,
        totalCostPaisa: 100 * 9000,
      ),
    ];
    final s4Total = s4Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0004',
      date: dateOffset(19),
      customerId: customerIds[4]!,
      customerName: 'Khan Mobiles Karkhano',
      customerPhone: '0315-5678901',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: s4Total,
      grandTotalPaisa: s4Total,
      paidPaisa: s4Total,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(19),
      items: s4Items,
    ));

    // Sale 5: Walk-in Cash Customer (17 days ago)
    final s5Items = [
      InvoiceItem(
        productId: productMap['CHG-GAN-65W']!.id!,
        sku: 'CHG-GAN-65W',
        productName: productMap['CHG-GAN-65W']!.name,
        packUnit: PackUnit.piece,
        packQty: 2,
        piecesPerPack: 1,
        totalPieces: 2,
        unitPricePaisa: 295000,
        netTotalPaisa: 2 * 295000, // PKR 5,900
        costPerPiecePaisa: 210000,
        totalCostPaisa: 2 * 210000,
      ),
      InvoiceItem(
        productId: productMap['EAR-BASS-35']!.id!,
        sku: 'EAR-BASS-35',
        productName: productMap['EAR-BASS-35']!.name,
        packUnit: PackUnit.dozen,
        packQty: 1, // 12 pcs
        piecesPerPack: 12,
        totalPieces: 12,
        unitPricePaisa: 28000,
        netTotalPaisa: 12 * 28000, // PKR 3,360
        costPerPiecePaisa: 16000,
        totalCostPaisa: 12 * 16000,
      ),
    ];
    final s5Total = s5Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0005',
      date: dateOffset(17),
      customerId: null,
      customerName: 'Cash Counter Dealer',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: s5Total,
      grandTotalPaisa: s5Total,
      paidPaisa: s5Total,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(17),
      items: s5Items,
    ));

    // Sale 6: Madina Cellular Faisalabad (15 days ago)
    final s6Items = [
      InvoiceItem(
        productId: productMap['MEM-SD-32G']!.id!,
        sku: 'MEM-SD-32G',
        productName: productMap['MEM-SD-32G']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 82000,
        netTotalPaisa: 24 * 82000, // PKR 19,680
        costPerPiecePaisa: 58000,
        totalCostPaisa: 24 * 58000,
      ),
      InvoiceItem(
        productId: productMap['MEM-SD-64G']!.id!,
        sku: 'MEM-SD-64G',
        productName: productMap['MEM-SD-64G']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 122000,
        netTotalPaisa: 24 * 122000, // PKR 29,280
        costPerPiecePaisa: 88000,
        totalCostPaisa: 24 * 88000,
      ),
    ];
    final s6Total = s6Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0006',
      date: dateOffset(15),
      customerId: customerIds[5]!,
      customerName: 'Madina Cellular Kutchery Road',
      customerPhone: '0346-6789012',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.partial,
      subtotalPaisa: s6Total,
      grandTotalPaisa: s6Total,
      paidPaisa: 2500000, // PKR 25,000 paid
      duePaisa: s6Total - 2500000,
      paymentMethod: 'bank',
      createdAt: dateOffset(15),
      items: s6Items,
    ));

    // Sale 7: Khyber Accessories Quetta (13 days ago)
    final s7Items = [
      InvoiceItem(
        productId: productMap['CAR-36W-MTL']!.id!,
        sku: 'CAR-36W-MTL',
        productName: productMap['CAR-36W-MTL']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 85000,
        netTotalPaisa: 24 * 85000, // PKR 20,400
        costPerPiecePaisa: 52000,
        totalCostPaisa: 24 * 52000,
      ),
      InvoiceItem(
        productId: productMap['HLD-MAG-VENT']!.id!,
        sku: 'HLD-MAG-VENT',
        productName: productMap['HLD-MAG-VENT']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 48000,
        netTotalPaisa: 24 * 48000, // PKR 11,520
        costPerPiecePaisa: 28000,
        totalCostPaisa: 24 * 28000,
      ),
    ];
    final s7Total = s7Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0007',
      date: dateOffset(13),
      customerId: customerIds[6]!,
      customerName: 'Khyber Accessories Quetta',
      customerPhone: '0308-7890123',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: s7Total,
      grandTotalPaisa: s7Total,
      paidPaisa: s7Total,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(13),
      items: s7Items,
    ));

    // Sale 8: Gujranwala Telecom Centre (10 days ago)
    final s8Items = [
      InvoiceItem(
        productId: productMap['PB-20K-22W']!.id!,
        sku: 'PB-20K-22W',
        productName: productMap['PB-20K-22W']!.name,
        packUnit: PackUnit.piece,
        packQty: 8,
        piecesPerPack: 1,
        totalPieces: 8,
        unitPricePaisa: 390000,
        netTotalPaisa: 8 * 390000, // PKR 31,200
        costPerPiecePaisa: 285000,
        totalCostPaisa: 8 * 285000,
      ),
      InvoiceItem(
        productId: productMap['CHG-PD-20W-WHT']!.id!,
        sku: 'CHG-PD-20W-WHT',
        productName: productMap['CHG-PD-20W-WHT']!.name,
        packUnit: PackUnit.dozen,
        packQty: 3, // 36 pcs
        piecesPerPack: 12,
        totalPieces: 36,
        unitPricePaisa: 65000,
        netTotalPaisa: 36 * 65000, // PKR 23,400
        costPerPiecePaisa: 45000,
        totalCostPaisa: 36 * 45000,
      ),
    ];
    final s8Total = s8Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0008',
      date: dateOffset(10),
      customerId: customerIds[7]!,
      customerName: 'Gujranwala Telecom Centre',
      customerPhone: '0323-8901234',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.partial,
      subtotalPaisa: s8Total,
      grandTotalPaisa: s8Total,
      paidPaisa: 2000000, // PKR 20,000 paid
      duePaisa: s8Total - 2000000,
      paymentMethod: 'bank',
      createdAt: dateOffset(10),
      items: s8Items,
    ));

    // Sale 9: Multan Mobile Zone (7 days ago)
    final s9Items = [
      InvoiceItem(
        productId: productMap['OTG-TC-USB3']!.id!,
        sku: 'OTG-TC-USB3',
        productName: productMap['OTG-TC-USB3']!.name,
        packUnit: PackUnit.box,
        packQty: 1, // 100 pcs (tier 140 PKR)
        piecesPerPack: 100,
        totalPieces: 100,
        unitPricePaisa: 14000,
        netTotalPaisa: 100 * 14000, // PKR 14,000
        costPerPiecePaisa: 8500,
        totalCostPaisa: 100 * 8500,
      ),
      InvoiceItem(
        productId: productMap['USB-HUB-4P']!.id!,
        sku: 'USB-HUB-4P',
        productName: productMap['USB-HUB-4P']!.name,
        packUnit: PackUnit.piece,
        packQty: 15,
        piecesPerPack: 1,
        totalPieces: 15,
        unitPricePaisa: 120000,
        netTotalPaisa: 15 * 120000, // PKR 18,000
        costPerPiecePaisa: 75000,
        totalCostPaisa: 15 * 75000,
      ),
    ];
    final s9Total = s9Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202610-0009',
      date: dateOffset(7),
      customerId: customerIds[8]!,
      customerName: 'Multan Mobile Zone',
      customerPhone: '0336-9012345',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.unpaid,
      subtotalPaisa: s9Total,
      grandTotalPaisa: s9Total,
      paidPaisa: 0,
      duePaisa: s9Total,
      paymentMethod: 'credit',
      createdAt: dateOffset(7),
      items: s9Items,
    ));

    // Sale 10: Al-Rehman Mobile (4 days ago)
    final s10Items = [
      InvoiceItem(
        productId: productMap['TWS-ANC-PRO']!.id!,
        sku: 'TWS-ANC-PRO',
        productName: productMap['TWS-ANC-PRO']!.name,
        packUnit: PackUnit.piece,
        packQty: 10,
        piecesPerPack: 1,
        totalPieces: 10,
        unitPricePaisa: 260000,
        netTotalPaisa: 10 * 260000, // PKR 26,000
        costPerPiecePaisa: 175000,
        totalCostPaisa: 10 * 175000,
      ),
    ];
    final s10Total = s10Items.fold(0, (s, i) => s + i.netTotalPaisa);
    final s10InvoiceId = await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202611-0010',
      date: dateOffset(4),
      customerId: customerIds[1]!,
      customerName: 'Al-Rehman Mobile Saddar',
      customerPhone: '0301-2345678',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: s10Total,
      grandTotalPaisa: s10Total,
      paidPaisa: s10Total,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(4),
      items: s10Items,
    ));

    // Sale 11: Bilal Telecom (2 days ago)
    final s11Items = [
      InvoiceItem(
        productId: productMap['CBL-TC-TC-100W']!.id!,
        sku: 'CBL-TC-TC-100W',
        productName: productMap['CBL-TC-TC-100W']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 35000,
        netTotalPaisa: 24 * 35000, // PKR 8,400
        costPerPiecePaisa: 22000,
        totalCostPaisa: 24 * 22000,
      ),
      InvoiceItem(
        productId: productMap['CHG-PD-20W-WHT']!.id!,
        sku: 'CHG-PD-20W-WHT',
        productName: productMap['CHG-PD-20W-WHT']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 65000,
        netTotalPaisa: 24 * 65000, // PKR 15,600
        costPerPiecePaisa: 45000,
        totalCostPaisa: 24 * 45000,
      ),
    ];
    final s11Total = s11Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202611-0011',
      date: dateOffset(2),
      customerId: customerIds[2]!,
      customerName: 'Bilal Telecom Hafeez Centre',
      customerPhone: '0322-3456789',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.unpaid,
      subtotalPaisa: s11Total,
      grandTotalPaisa: s11Total,
      paidPaisa: 0,
      duePaisa: s11Total,
      paymentMethod: 'credit',
      createdAt: dateOffset(2),
      items: s11Items,
    ));

    // Sale 12: Today's Net Sale
    final s12Items = [
      InvoiceItem(
        productId: productMap['COV-MAG-IP15']!.id!,
        sku: 'COV-MAG-IP15',
        productName: productMap['COV-MAG-IP15']!.name,
        packUnit: PackUnit.dozen,
        packQty: 2, // 24 pcs
        piecesPerPack: 12,
        totalPieces: 24,
        unitPricePaisa: 34000,
        netTotalPaisa: 24 * 34000, // PKR 8,160
        costPerPiecePaisa: 18000,
        totalCostPaisa: 24 * 18000,
      ),
      InvoiceItem(
        productId: productMap['GLS-9D-IP15P']!.id!,
        sku: 'GLS-9D-IP15P',
        productName: productMap['GLS-9D-IP15P']!.name,
        packUnit: PackUnit.dozen,
        packQty: 3, // 36 pcs
        piecesPerPack: 12,
        totalPieces: 36,
        unitPricePaisa: 9500,
        netTotalPaisa: 36 * 9500, // PKR 3,420
        costPerPiecePaisa: 4500,
        totalCostPaisa: 36 * 4500,
      ),
    ];
    final s12Total = s12Items.fold(0, (s, i) => s + i.netTotalPaisa);
    await acc.postSaleInvoice(Invoice(
      invoiceNumber: 'INV-202611-0012',
      date: dateOffset(0),
      customerId: customerIds[1]!,
      customerName: 'Al-Rehman Mobile Saddar',
      customerPhone: '0301-2345678',
      status: InvoiceStatus.posted,
      paymentStatus: PaymentStatus.paid,
      subtotalPaisa: s12Total,
      grandTotalPaisa: s12Total,
      paidPaisa: s12Total,
      duePaisa: 0,
      paymentMethod: 'cash',
      createdAt: dateOffset(0),
      items: s12Items,
    ));

    // 7. Seed Customer Receipts
    // Bilal Telecom pays PKR 20,000 against balance (12 days ago)
    await acc.receiveCustomerPayment(
      customerId: customerIds[2]!,
      customerName: 'Bilal Telecom Hafeez Centre',
      amountPaisa: 2000000,
      accountType: 'bank',
      date: dateOffset(12),
      refNumber: 'MEEZAN-982173',
      notes: 'Online bank transfer from Bilal Telecom',
    );

    // Madina Cellular pays PKR 15,000 against balance (5 days ago)
    await acc.receiveCustomerPayment(
      customerId: customerIds[5]!,
      customerName: 'Madina Cellular Kutchery Road',
      amountPaisa: 1500000,
      accountType: 'cash',
      date: dateOffset(5),
      notes: 'Cash collected by staff from Faisalabad market',
    );

    // 8. Seed Supplier Payments
    // Paid Hoco PKR 100,000 (16 days ago)
    await acc.paySupplier(
      supplierId: supplierIds[3]!,
      supplierName: 'Hoco & Remax Agency Lahore',
      amountPaisa: 10000000,
      accountType: 'bank',
      date: dateOffset(16),
      refNumber: 'TRF-HOCO-449',
      notes: 'Bank transfer for power banks shipment',
    );

    // 9. Seed Realistic Shop Expenses
    final expenses = [
      Expense(
        category: 'Shop Rent',
        amountPaisa: 4500000, // PKR 45,000
        accountId: 'bank',
        date: dateOffset(25),
        notes: 'Monthly plaza shop rent Star City Saddar',
        createdAt: dateOffset(25),
      ),
      Expense(
        category: 'Electricity & Bills',
        amountPaisa: 1450000, // PKR 14,500
        accountId: 'bank',
        date: dateOffset(18),
        notes: 'K-Electric commercial shop bill',
        createdAt: dateOffset(18),
      ),
      Expense(
        category: 'Transport & Freight',
        amountPaisa: 380000, // PKR 3,800
        accountId: 'cash',
        date: dateOffset(14),
        notes: 'Cargo bilty charges Bolton Market to Saddar',
        createdAt: dateOffset(14),
      ),
      Expense(
        category: 'Staff Salary',
        amountPaisa: 3000000, // PKR 30,000
        accountId: 'cash',
        date: dateOffset(10),
        notes: 'Sales counter staff salary (Bilal)',
        createdAt: dateOffset(10),
      ),
      Expense(
        category: 'Refreshment & Tea',
        amountPaisa: 185000, // PKR 1,850
        accountId: 'cash',
        date: dateOffset(3),
        notes: 'Weekly tea & dealer refreshments',
        createdAt: dateOffset(3),
      ),
    ];
    for (final exp in expenses) {
      await acc.recordExpense(exp);
    }

    // 10. Seed 1 Sales Return (Al-Rehman returns 2 pcs TWS Earbuds, 1 saleable, 1 damaged)
    await acc.processSalesReturn(ReturnOrder(
      returnType: ReturnType.salesReturn,
      returnNumber: 'SRTN-202611-0001',
      originalDocumentId: s10InvoiceId,
      originalDocumentNumber: 'INV-202611-0010',
      partyId: customerIds[1]!,
      partyName: 'Al-Rehman Mobile Saddar',
      date: dateOffset(1),
      totalCreditPaisa: 2 * 260000, // PKR 5,200 credit
      refundedCashPaisa: 0,
      notes: 'Customer returned 2 pcs: 1 sealed saleable, 1 mic issue damaged',
      createdAt: dateOffset(1),
      items: [
        ReturnItem(
          productId: productMap['TWS-ANC-PRO']!.id!,
          sku: 'TWS-ANC-PRO',
          productName: productMap['TWS-ANC-PRO']!.name,
          packUnit: PackUnit.piece,
          packQty: 1,
          piecesPerPack: 1,
          totalPieces: 1,
          isSaleable: true,
          unitCreditRatePaisa: 260000,
          netCreditPaisa: 260000,
          costPerPiecePaisa: 175000,
        ),
        ReturnItem(
          productId: productMap['TWS-ANC-PRO']!.id!,
          sku: 'TWS-ANC-PRO',
          productName: productMap['TWS-ANC-PRO']!.name,
          packUnit: PackUnit.piece,
          packQty: 1,
          piecesPerPack: 1,
          totalPieces: 1,
          isSaleable: false,
          unitCreditRatePaisa: 260000,
          netCreditPaisa: 260000,
          costPerPiecePaisa: 175000,
        ),
      ],
    ));

    debugPrint('Offline Demo Data successfully seeded and 100% reconciled!');
  }
}
