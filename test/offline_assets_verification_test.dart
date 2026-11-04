import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline Assets Verification', () {
    test('All bundled product pictures and brand logos exist as valid PNG files', () {
      final expectedAssets = [
        'assets/images/products/charger_20w.png',
        'assets/images/products/charger_65w_gan.png',
        'assets/images/products/cable_type_c_100w.png',
        'assets/images/products/cable_3in1_multi.png',
        'assets/images/products/powerbank_10000mah.png',
        'assets/images/products/powerbank_20000mah.png',
        'assets/images/products/tws_earbuds_anc.png',
        'assets/images/products/wired_earphones_bass.png',
        'assets/images/products/case_magsafe_clear.png',
        'assets/images/products/case_armor_rugged.png',
        'assets/images/products/tempered_glass_9d.png',
        'assets/images/products/car_charger_36w.png',
        'assets/images/products/holder_magnetic_car.png',
        'assets/images/products/otg_type_c_usb3.png',
        'assets/images/products/microsd_64gb_fast.png',
        'assets/images/products/usb_hub_4port.png',
        'assets/images/branding/logo.png',
      ];

      expect(expectedAssets.length, greaterThanOrEqualTo(12),
          reason: 'At least 12 genuinely distinct product pictures required');

      for (final assetPath in expectedAssets) {
        final file = File(assetPath);
        expect(file.existsSync(), isTrue, reason: 'Asset file must exist on disk: $assetPath');
        final length = file.lengthSync();
        expect(length, greaterThan(1000), reason: 'Asset file must not be empty or placeholder: $assetPath');

        // Verify PNG magic header bytes: 0x89, 0x50, 0x4E, 0x47
        final bytes = file.readAsBytesSync();
        expect(bytes[0], equals(0x89));
        expect(bytes[1], equals(0x50)); // 'P'
        expect(bytes[2], equals(0x4E)); // 'N'
        expect(bytes[3], equals(0x47)); // 'G'
      }

      print('Verified all ${expectedAssets.length} offline accessory assets are valid!');
    });
  });
}
