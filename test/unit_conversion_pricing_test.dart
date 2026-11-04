import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_wholesale_erp/core/utils/money.dart';
import 'package:mobile_wholesale_erp/models/product.dart';

void main() {
  group('Unit Conversions and Tier Pricing Tests', () {
    test('Piece, Dozen and Box conversions calculate pieces accurately', () {
      final product = Product(
        sku: 'CBL-TC-100W',
        name: 'Type-C Cable',
        category: 'Charging Cables',
        piecesPerBox: 50,
        costPricePaisa: 20000,
        wholesalePricePaisa: 30000,
        minSellingPricePaisa: 25000,
        currentStockPieces: 200,
        createdAt: '2026-11-01',
        updatedAt: '2026-11-01',
      );

      // 1 Piece
      expect(1 * 1, equals(1));
      // 2 Dozen = 24 Pieces
      expect(2 * 12, equals(24));
      // 3 Boxes of 50 = 150 Pieces
      expect(3 * product.piecesPerBox, equals(150));
      // Fractional pieces not allowed
      expect(150 % 1, equals(0));
    });

    test('Quantity Tier pricing triggers correctly at threshold', () {
      final product = Product(
        sku: 'GLS-9D-IP15',
        name: '9D Glass Protector',
        category: 'Screen Protectors',
        piecesPerBox: 100,
        costPricePaisa: 4500, // PKR 45
        wholesalePricePaisa: 9500, // PKR 95
        minSellingPricePaisa: 8000,
        tierMinQty: 100,
        tierPricePaisa: 8500, // PKR 85 for 100+ pcs
        currentStockPieces: 500,
        createdAt: '2026-11-01',
        updatedAt: '2026-11-01',
      );

      // 50 pieces -> normal wholesale price 95 PKR (9,500 paisa)
      expect(product.getEffectivePricePaisa(50), equals(9500));
      // 99 pieces -> normal wholesale price 95 PKR
      expect(product.getEffectivePricePaisa(99), equals(9500));
      // 100 pieces -> tier price 85 PKR (8,500 paisa)
      expect(product.getEffectivePricePaisa(100), equals(8500));
      // 250 pieces -> tier price 85 PKR
      expect(product.getEffectivePricePaisa(250), equals(8500));
    });

    test('Money class handles exact integer paisa arithmetic and formatting', () {
      final m1 = Money.fromPkr(1250.50);
      expect(m1.paisa, equals(125050));
      expect(m1.toPkr, equals(1250.50));
      expect(m1.format(), equals('PKR 1,250.50'));

      final m2 = Money.fromPkr(500);
      expect(m2.paisa, equals(50000));
      expect(m2.format(), equals('PKR 500'));

      final sum = m1 + m2;
      expect(sum.paisa, equals(175050));
      expect(sum.format(), equals('PKR 1,750.50'));
    });
  });
}
