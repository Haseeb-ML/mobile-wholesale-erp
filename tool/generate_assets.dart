import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final productsDir = Directory('assets/images/products');
  if (!productsDir.existsSync()) {
    productsDir.createSync(recursive: true);
  }
  final brandingDir = Directory('assets/images/branding');
  if (!brandingDir.existsSync()) {
    brandingDir.createSync(recursive: true);
  }

  print('Generating product pictures...');

  // 1. Charger 20W PD Fast Charger (White sleek adapter with USB-C port)
  saveImage(generateCharger20W(), 'assets/images/products/charger_20w.png');

  // 2. Charger 65W GaN Dual Port Charger (Black premium GaN adapter)
  saveImage(generateCharger65W(), 'assets/images/products/charger_65w_gan.png');

  // 3. Braided Type-C to Type-C 100W Cable (Braided texture with metal alloy plugs)
  saveImage(generateCableTypeC(), 'assets/images/products/cable_type_c_100w.png');

  // 4. 3-in-1 Multi Fast Charging Cable (Red braided cable with 3 split heads)
  saveImage(generateCable3in1(), 'assets/images/products/cable_3in1_multi.png');

  // 5. 10000mAh Slim Power Bank (Titanium grey with LED battery display)
  saveImage(generatePowerBank10000(), 'assets/images/products/powerbank_10000mah.png');

  // 6. 20000mAh 22.5W Heavy Duty Power Bank (Midnight blue with dual ports & screen)
  saveImage(generatePowerBank20000(), 'assets/images/products/powerbank_20000mah.png');

  // 7. TWS Wireless Earbuds with ANC (White pebble case with earbuds)
  saveImage(generateTwsEarbuds(), 'assets/images/products/tws_earbuds_anc.png');

  // 8. In-Ear Wired Earphones with Mic (Gunmetal aluminum chamber & cable)
  saveImage(generateWiredEarphones(), 'assets/images/products/wired_earphones_bass.png');

  // 9. Magnetic MagSafe Clear Phone Case (Clear protective shell with white MagSafe ring)
  saveImage(generatePhoneCaseClear(), 'assets/images/products/case_magsafe_clear.png');

  // 10. Heavy Duty Shockproof Armor Case (Rugged matte carbon textured case)
  saveImage(generatePhoneCaseArmor(), 'assets/images/products/case_armor_rugged.png');

  // 11. 9D Full Glue Curved Tempered Glass (Glass protector with glossy sheen & black border)
  saveImage(generateTemperedGlass(), 'assets/images/products/tempered_glass_9d.png');

  // 12. 36W Metal Dual Port Car Charger (Aluminum alloy bullet with blue LED glow)
  saveImage(generateCarCharger(), 'assets/images/products/car_charger_36w.png');

  // 13. 360 Degree Magnetic Car Mount Holder (Air vent / dash mount with magnetic disc)
  saveImage(generateMobileHolder(), 'assets/images/products/holder_magnetic_car.png');

  // 14. Zinc-Alloy Type-C to USB 3.0 OTG Adapter (Mini metallic dongle)
  saveImage(generateOtgAdapter(), 'assets/images/products/otg_type_c_usb3.png');

  // 15. High Speed MicroSD Card 64GB UHS-I (MicroSD card with red/gold branding & gold pins)
  saveImage(generateMicroSdCard(), 'assets/images/products/microsd_64gb_fast.png');

  // 16. 4-Port USB 3.0 / Type-C Multi Hub (Space gray sleek aluminum hub)
  saveImage(generateUsbHub(), 'assets/images/products/usb_hub_4port.png');

  // Brand Logo
  saveImage(generateBrandLogo(), 'assets/images/branding/logo.png');

  print('Successfully generated 16 accessory renders and brand logo!');
}

void saveImage(img.Image image, String path) {
  final bytes = img.encodePng(image);
  File(path).writeAsBytesSync(bytes);
  print('Saved: $path (${bytes.length} bytes)');
}

img.Image createStudioCanvas() {
  const w = 400;
  const h = 400;
  final image = img.Image(width: w, height: h);
  // Render smooth gradient studio background (soft clean grey to white gradient)
  for (int y = 0; y < h; y++) {
    final t = y / h;
    final r = (248 - 18 * t).round();
    final g = (250 - 16 * t).round();
    final b = (252 - 14 * t).round();
    final col = img.ColorRgba8(r, g, b, 255);
    for (int x = 0; x < w; x++) {
      image.setPixel(x, y, col);
    }
  }

  // Soft studio pedestal shadow under product
  for (int y = 320; y < 370; y++) {
    for (int x = 80; x < 320; x++) {
      final dx = (x - 200) / 120.0;
      final dy = (y - 345) / 25.0;
      final dist2 = dx * dx + dy * dy;
      if (dist2 <= 1.0) {
        final shadowAlpha = ((1.0 - sqrt(dist2)) * 40).round();
        blendPixel(image, x, y, 100, 116, 139, shadowAlpha);
      }
    }
  }
  return image;
}

void blendPixel(img.Image im, int x, int y, int r, int g, int b, int a) {
  if (x < 0 || x >= im.width || y < 0 || y >= im.height) return;
  final cur = im.getPixel(x, y);
  final curR = cur.r.toInt();
  final curG = cur.g.toInt();
  final curB = cur.b.toInt();
  final invA = 255 - a;
  final outR = ((r * a + curR * invA) / 255).round();
  final outG = ((g * a + curG * invA) / 255).round();
  final outB = ((b * a + curB * invA) / 255).round();
  im.setPixel(x, y, img.ColorRgba8(outR, outG, outB, 255));
}

// 1. 20W PD Charger
img.Image generateCharger20W() {
  final im = createStudioCanvas();
  // Body: glossy white rectangle with rounded edges
  img.fillRect(im, x1: 130, y1: 100, x2: 270, y2: 280, color: img.ColorRgba8(240, 242, 245, 255));
  img.drawRect(im, x1: 130, y1: 100, x2: 270, y2: 280, color: img.ColorRgba8(200, 205, 215, 255));
  // Bevel / face
  img.fillRect(im, x1: 145, y1: 115, x2: 255, y2: 265, color: img.ColorRgba8(255, 255, 255, 255));
  // Prongs on top
  img.fillRect(im, x1: 165, y1: 60, x2: 180, y2: 100, color: img.ColorRgba8(180, 185, 195, 255));
  img.fillRect(im, x1: 220, y1: 60, x2: 235, y2: 100, color: img.ColorRgba8(180, 185, 195, 255));
  // Type-C Port
  img.fillRect(im, x1: 175, y1: 190, x2: 225, y2: 210, color: img.ColorRgba8(40, 45, 55, 255));
  img.fillRect(im, x1: 185, y1: 197, x2: 215, y2: 203, color: img.ColorRgba8(218, 165, 32, 255));
  // 20W PD Text / Logo
  img.drawString(im, '20W PD', font: img.arial14, x: 175, y: 150, color: img.ColorRgba8(100, 116, 139, 255));
  return im;
}

// 2. 65W GaN Charger
img.Image generateCharger65W() {
  final im = createStudioCanvas();
  // Body: dark matte black/graphite
  img.fillRect(im, x1: 120, y1: 110, x2: 280, y2: 290, color: img.ColorRgba8(30, 35, 45, 255));
  img.drawRect(im, x1: 120, y1: 110, x2: 280, y2: 290, color: img.ColorRgba8(55, 65, 81, 255));
  // Prongs
  img.fillRect(im, x1: 160, y1: 70, x2: 178, y2: 110, color: img.ColorRgba8(190, 195, 205, 255));
  img.fillRect(im, x1: 222, y1: 70, x2: 240, y2: 110, color: img.ColorRgba8(190, 195, 205, 255));
  // Ports: USB-C1, USB-C2, USB-A
  img.fillRect(im, x1: 175, y1: 155, x2: 225, y2: 175, color: img.ColorRgba8(13, 148, 136, 255));
  img.fillRect(im, x1: 175, y1: 195, x2: 225, y2: 215, color: img.ColorRgba8(13, 148, 136, 255));
  img.fillRect(im, x1: 170, y1: 235, x2: 230, y2: 255, color: img.ColorRgba8(245, 158, 11, 255));
  img.drawString(im, 'GaN 65W', font: img.arial14, x: 170, y: 130, color: img.ColorRgba8(203, 213, 225, 255));
  return im;
}

// 3. Braided Type-C Cable
img.Image generateCableTypeC() {
  final im = createStudioCanvas();
  // Braided cable loops
  for (int r = 80; r <= 130; r += 16) {
    img.drawCircle(im, x: 200, y: 220, radius: r, color: img.ColorRgba8(71, 85, 105, 255));
    img.drawCircle(im, x: 200, y: 220, radius: r + 1, color: img.ColorRgba8(148, 163, 184, 255));
  }
  // Metallic connector heads
  img.fillRect(im, x1: 165, y1: 80, x2: 195, y2: 140, color: img.ColorRgba8(15, 23, 42, 255));
  img.fillRect(im, x1: 172, y1: 50, x2: 188, y2: 80, color: img.ColorRgba8(203, 213, 225, 255));
  // Second head
  img.fillRect(im, x1: 215, y1: 90, x2: 245, y2: 150, color: img.ColorRgba8(15, 23, 42, 255));
  img.fillRect(im, x1: 222, y1: 60, x2: 238, y2: 90, color: img.ColorRgba8(203, 213, 225, 255));
  img.drawString(im, '100W PD', font: img.arial14, x: 170, y: 215, color: img.ColorRgba8(13, 148, 136, 255));
  return im;
}

// 4. 3-in-1 Cable
img.Image generateCable3in1() {
  final im = createStudioCanvas();
  // Red braided loops
  for (int r = 70; r <= 120; r += 15) {
    img.drawCircle(im, x: 200, y: 230, radius: r, color: img.ColorRgba8(220, 38, 38, 255));
    img.drawCircle(im, x: 200, y: 230, radius: r + 1, color: img.ColorRgba8(248, 113, 113, 255));
  }
  // 3 Output heads (Lightning, Type-C, Micro-USB)
  final headsX = [140, 200, 260];
  for (final hx in headsX) {
    img.fillRect(im, x1: hx - 12, y1: 90, x2: hx + 12, y2: 140, color: img.ColorRgba8(30, 41, 59, 255));
    img.fillRect(im, x1: hx - 7, y1: 65, x2: hx + 7, y2: 90, color: img.ColorRgba8(210, 215, 225, 255));
  }
  img.drawString(im, '3-IN-1 FAST', font: img.arial14, x: 160, y: 225, color: img.ColorRgba8(220, 38, 38, 255));
  return im;
}

// 5. 10000mAh Power Bank
img.Image generatePowerBank10000() {
  final im = createStudioCanvas();
  // Slim rounded aluminum body
  img.fillRect(im, x1: 140, y1: 80, x2: 260, y2: 290, color: img.ColorRgba8(100, 116, 139, 255));
  img.drawRect(im, x1: 140, y1: 80, x2: 260, y2: 290, color: img.ColorRgba8(71, 85, 105, 255));
  // Glossy bezel top
  img.fillRect(im, x1: 145, y1: 85, x2: 255, y2: 130, color: img.ColorRgba8(15, 23, 42, 255));
  // LED percentage display
  img.drawString(im, '88%', font: img.arial14, x: 185, y: 100, color: img.ColorRgba8(13, 148, 136, 255));
  // Ports on top edge
  img.fillRect(im, x1: 160, y1: 76, x2: 185, y2: 80, color: img.ColorRgba8(245, 158, 11, 255));
  img.fillRect(im, x1: 215, y1: 76, x2: 240, y2: 80, color: img.ColorRgba8(245, 158, 11, 255));
  // 10000mAh text
  img.drawString(im, '10,000 mAh', font: img.arial14, x: 160, y: 240, color: img.ColorRgba8(226, 232, 240, 255));
  return im;
}

// 6. 20000mAh Power Bank
img.Image generatePowerBank20000() {
  final im = createStudioCanvas();
  // Thicker midnight blue body
  img.fillRect(im, x1: 130, y1: 70, x2: 270, y2: 300, color: img.ColorRgba8(15, 23, 42, 255));
  img.drawRect(im, x1: 130, y1: 70, x2: 270, y2: 300, color: img.ColorRgba8(30, 41, 59, 255));
  // Digital LCD mirror screen
  img.fillRect(im, x1: 155, y1: 95, x2: 245, y2: 155, color: img.ColorRgba8(2, 6, 23, 255));
  img.drawRect(im, x1: 155, y1: 95, x2: 245, y2: 155, color: img.ColorRgba8(51, 65, 85, 255));
  img.drawString(im, '100%', font: img.arial24, x: 175, y: 110, color: img.ColorRgba8(56, 189, 248, 255));
  // Subtle grip stripes
  for (int y = 180; y <= 240; y += 12) {
    img.drawLine(im, x1: 150, y1: y, x2: 250, y2: y, color: img.ColorRgba8(30, 41, 59, 255));
  }
  img.drawString(im, '22.5W FAST 20000', font: img.arial14, x: 145, y: 265, color: img.ColorRgba8(148, 163, 184, 255));
  return im;
}

// 7. TWS Wireless Earbuds
img.Image generateTwsEarbuds() {
  final im = createStudioCanvas();
  // Pebble charging case (White smooth oval)
  img.fillCircle(im, x: 200, y: 200, radius: 85, color: img.ColorRgba8(241, 245, 249, 255));
  img.drawCircle(im, x: 200, y: 200, radius: 85, color: img.ColorRgba8(203, 213, 225, 255));
  // Lid seam
  img.drawLine(im, x1: 120, y1: 195, x2: 280, y2: 195, color: img.ColorRgba8(203, 213, 225, 255));
  // LED indicator dot
  img.fillCircle(im, x: 200, y: 220, radius: 4, color: img.ColorRgba8(16, 185, 129, 255));
  // Earbud 1 (placed next to case)
  img.fillCircle(im, x: 110, y: 130, radius: 18, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillRect(im, x1: 104, y1: 130, x2: 116, y2: 180, color: img.ColorRgba8(240, 240, 245, 255));
  // Earbud 2
  img.fillCircle(im, x: 290, y: 130, radius: 18, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillRect(im, x1: 284, y1: 130, x2: 296, y2: 180, color: img.ColorRgba8(240, 240, 245, 255));
  img.drawString(im, 'TWS ANC PRO', font: img.arial14, x: 155, y: 250, color: img.ColorRgba8(100, 116, 139, 255));
  return im;
}

// 8. Wired Earphones
img.Image generateWiredEarphones() {
  final im = createStudioCanvas();
  // Metallic bullet earbud chambers
  img.fillRect(im, x1: 120, y1: 110, x2: 160, y2: 140, color: img.ColorRgba8(71, 85, 105, 255));
  img.fillCircle(im, x: 120, y: 125, radius: 14, color: img.ColorRgba8(15, 23, 42, 255)); // rubber tip
  img.fillRect(im, x1: 240, y1: 110, x2: 280, y2: 140, color: img.ColorRgba8(71, 85, 105, 255));
  img.fillCircle(im, x: 280, y: 125, radius: 14, color: img.ColorRgba8(15, 23, 42, 255)); // rubber tip
  // Cable flowing down to mic controller
  img.drawLine(im, x1: 150, y1: 140, x2: 180, y2: 210, color: img.ColorRgba8(51, 65, 85, 255));
  img.drawLine(im, x1: 250, y1: 140, x2: 220, y2: 210, color: img.ColorRgba8(51, 65, 85, 255));
  // Mic remote
  img.fillRect(im, x1: 190, y1: 200, x2: 210, y2: 240, color: img.ColorRgba8(15, 23, 42, 255));
  img.fillCircle(im, x: 200, y: 220, radius: 3, color: img.ColorRgba8(203, 213, 225, 255));
  // 3.5mm Gold Plug
  img.fillRect(im, x1: 193, y1: 280, x2: 207, y2: 320, color: img.ColorRgba8(234, 179, 8, 255));
  img.drawString(im, 'DEEP BASS HD', font: img.arial14, x: 155, y: 70, color: img.ColorRgba8(15, 23, 42, 255));
  return im;
}

// 9. Clear MagSafe Case
img.Image generatePhoneCaseClear() {
  final im = createStudioCanvas();
  // Phone outline
  img.fillRect(im, x1: 130, y1: 70, x2: 270, y2: 310, color: img.ColorRgba8(241, 245, 249, 180));
  img.drawRect(im, x1: 130, y1: 70, x2: 270, y2: 310, color: img.ColorRgba8(148, 163, 184, 255));
  // Camera bump island
  img.fillRect(im, x1: 145, y1: 85, x2: 200, y2: 145, color: img.ColorRgba8(226, 232, 240, 255));
  img.drawCircle(im, x: 165, y: 105, radius: 10, color: img.ColorRgba8(71, 85, 105, 255));
  img.drawCircle(im, x: 165, y: 130, radius: 10, color: img.ColorRgba8(71, 85, 105, 255));
  img.drawCircle(im, x: 185, y: 118, radius: 10, color: img.ColorRgba8(71, 85, 105, 255));
  // White MagSafe ring
  img.drawCircle(im, x: 200, y: 205, radius: 40, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawCircle(im, x: 200, y: 205, radius: 39, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillRect(im, x1: 198, y1: 250, x2: 202, y2: 270, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawString(im, 'MAGSAFE CLEAR', font: img.arial14, x: 148, y: 285, color: img.ColorRgba8(100, 116, 139, 255));
  return im;
}

// 10. Armor Phone Case
img.Image generatePhoneCaseArmor() {
  final im = createStudioCanvas();
  // Rugged dark body
  img.fillRect(im, x1: 125, y1: 65, x2: 275, y2: 315, color: img.ColorRgba8(30, 41, 59, 255));
  img.drawRect(im, x1: 125, y1: 65, x2: 275, y2: 315, color: img.ColorRgba8(15, 23, 42, 255));
  // Carbon texture insert
  img.fillRect(im, x1: 140, y1: 140, x2: 260, y2: 260, color: img.ColorRgba8(15, 23, 42, 255));
  for (int y = 145; y < 255; y += 8) {
    img.drawLine(im, x1: 145, y1: y, x2: 255, y2: y, color: img.ColorRgba8(51, 65, 85, 255));
  }
  // Metallic kickstand ring
  img.drawCircle(im, x: 200, y: 200, radius: 24, color: img.ColorRgba8(203, 213, 225, 255));
  img.drawString(im, 'SHOCKPROOF 360', font: img.arial14, x: 142, y: 285, color: img.ColorRgba8(245, 158, 11, 255));
  return im;
}

// 11. 9D Tempered Glass
img.Image generateTemperedGlass() {
  final im = createStudioCanvas();
  // Glass protector with dark border
  img.fillRect(im, x1: 130, y1: 60, x2: 270, y2: 320, color: img.ColorRgba8(248, 250, 252, 220));
  img.drawRect(im, x1: 130, y1: 60, x2: 270, y2: 320, color: img.ColorRgba8(15, 23, 42, 255));
  // Gloss glare reflection line across glass
  img.drawLine(im, x1: 140, y1: 80, x2: 260, y2: 280, color: img.ColorRgba8(255, 255, 255, 200));
  img.drawLine(im, x1: 145, y1: 80, x2: 265, y2: 280, color: img.ColorRgba8(255, 255, 255, 200));
  // Speaker cutout
  img.fillRect(im, x1: 185, y1: 68, x2: 215, y2: 73, color: img.ColorRgba8(15, 23, 42, 255));
  img.drawString(im, '9D PRIVACY / HD', font: img.arial14, x: 145, y: 180, color: img.ColorRgba8(71, 85, 105, 255));
  return im;
}

// 12. 36W Metal Car Charger
img.Image generateCarCharger() {
  final im = createStudioCanvas();
  // Metallic cylinder body
  img.fillRect(im, x1: 160, y1: 120, x2: 240, y2: 250, color: img.ColorRgba8(51, 65, 85, 255));
  // Contact spring tip
  img.fillRect(im, x1: 190, y1: 250, x2: 210, y2: 280, color: img.ColorRgba8(203, 213, 225, 255));
  // Side grounding contacts
  img.fillRect(im, x1: 152, y1: 170, x2: 160, y2: 200, color: img.ColorRgba8(203, 213, 225, 255));
  img.fillRect(im, x1: 240, y1: 170, x2: 248, y2: 200, color: img.ColorRgba8(203, 213, 225, 255));
  // Head with blue ambient ring & dual ports
  img.fillCircle(im, x: 200, y: 120, radius: 45, color: img.ColorRgba8(15, 23, 42, 255));
  img.drawCircle(im, x: 200, y: 120, radius: 40, color: img.ColorRgba8(56, 189, 248, 255));
  // Ports
  img.fillRect(im, x1: 185, y1: 100, x2: 215, y2: 112, color: img.ColorRgba8(13, 148, 136, 255));
  img.fillRect(im, x1: 185, y1: 125, x2: 215, y2: 137, color: img.ColorRgba8(245, 158, 11, 255));
  img.drawString(im, '36W PD+QC', font: img.arial14, x: 165, y: 65, color: img.ColorRgba8(15, 23, 42, 255));
  return im;
}

// 13. Mobile Car Mount
img.Image generateMobileHolder() {
  final im = createStudioCanvas();
  // Magnetic circular disc face
  img.fillCircle(im, x: 200, y: 160, radius: 70, color: img.ColorRgba8(15, 23, 42, 255));
  img.drawCircle(im, x: 200, y: 160, radius: 68, color: img.ColorRgba8(13, 148, 136, 255));
  img.drawCircle(im, x: 200, y: 160, radius: 50, color: img.ColorRgba8(71, 85, 105, 255));
  // Air vent clamp base
  img.fillRect(im, x1: 180, y1: 230, x2: 220, y2: 290, color: img.ColorRgba8(51, 65, 85, 255));
  img.fillRect(im, x1: 170, y1: 285, x2: 230, y2: 305, color: img.ColorRgba8(30, 41, 59, 255));
  img.drawString(im, '360 ROTATE', font: img.arial14, x: 160, y: 153, color: img.ColorRgba8(255, 255, 255, 255));
  return im;
}

// 14. OTG Adapter
img.Image generateOtgAdapter() {
  final im = createStudioCanvas();
  // Small zinc alloy dongle body
  img.fillRect(im, x1: 150, y1: 140, x2: 250, y2: 240, color: img.ColorRgba8(100, 116, 139, 255));
  img.drawRect(im, x1: 150, y1: 140, x2: 250, y2: 240, color: img.ColorRgba8(71, 85, 105, 255));
  // Type C plug at top
  img.fillRect(im, x1: 180, y1: 95, x2: 220, y2: 140, color: img.ColorRgba8(203, 213, 225, 255));
  // USB 3.0 female blue port at bottom
  img.fillRect(im, x1: 165, y1: 240, x2: 235, y2: 265, color: img.ColorRgba8(2, 132, 199, 255));
  img.drawString(im, 'OTG 3.0', font: img.arial14, x: 175, y: 185, color: img.ColorRgba8(241, 245, 249, 255));
  return im;
}

// 15. MicroSD 64GB
img.Image generateMicroSdCard() {
  final im = createStudioCanvas();
  // MicroSD silhouette shape
  img.fillRect(im, x1: 140, y1: 100, x2: 260, y2: 270, color: img.ColorRgba8(220, 38, 38, 255));
  img.fillRect(im, x1: 140, y1: 185, x2: 260, y2: 270, color: img.ColorRgba8(245, 158, 11, 255));
  // Gold connector pins at top
  for (int x = 155; x < 245; x += 12) {
    img.fillRect(im, x1: x, y1: 105, x2: x + 7, y2: 125, color: img.ColorRgba8(234, 179, 8, 255));
  }
  img.drawString(im, '64 GB', font: img.arial24, x: 170, y: 145, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawString(im, 'UHS-I A1 V30', font: img.arial14, x: 155, y: 220, color: img.ColorRgba8(15, 23, 42, 255));
  return im;
}

// 16. USB Hub
img.Image generateUsbHub() {
  final im = createStudioCanvas();
  // Aluminum rectangular body
  img.fillRect(im, x1: 110, y1: 140, x2: 290, y2: 230, color: img.ColorRgba8(71, 85, 105, 255));
  img.drawRect(im, x1: 110, y1: 140, x2: 290, y2: 230, color: img.ColorRgba8(51, 65, 85, 255));
  // 4 USB 3.0 ports
  for (int x = 130; x <= 250; x += 40) {
    img.fillRect(im, x1: x, y1: 170, x2: x + 28, y2: 195, color: img.ColorRgba8(2, 132, 199, 255));
    img.fillRect(im, x1: x + 4, y1: 185, x2: x + 24, y2: 192, color: img.ColorRgba8(255, 255, 255, 255));
  }
  // Cable lead
  img.fillRect(im, x1: 90, y1: 178, x2: 110, y2: 188, color: img.ColorRgba8(30, 41, 59, 255));
  img.drawString(im, '4-IN-1 TYPE-C HUB', font: img.arial14, x: 140, y: 115, color: img.ColorRgba8(15, 23, 42, 255));
  return im;
}

// Brand Logo
img.Image generateBrandLogo() {
  const w = 400;
  const h = 400;
  final im = img.Image(width: w, height: h);
  // Deep Navy background
  img.fill(im, color: img.ColorRgba8(15, 23, 42, 255));
  // Outer circle in Teal
  img.drawCircle(im, x: 200, y: 170, radius: 100, color: img.ColorRgba8(13, 148, 136, 255));
  img.drawCircle(im, x: 200, y: 170, radius: 98, color: img.ColorRgba8(13, 148, 136, 255));
  // Inner phone + box symbol
  img.fillRect(im, x1: 160, y1: 110, x2: 240, y2: 230, color: img.ColorRgba8(13, 148, 136, 255));
  img.fillRect(im, x1: 170, y1: 125, x2: 230, y2: 215, color: img.ColorRgba8(15, 23, 42, 255));
  // Amber accent box
  img.fillRect(im, x1: 185, y1: 150, x2: 215, y2: 185, color: img.ColorRgba8(245, 158, 11, 255));
  // App Title
  img.drawString(im, 'MOBILE WHOLESALE', font: img.arial24, x: 80, y: 300, color: img.ColorRgba8(255, 255, 255, 255));
  img.drawString(im, 'ERP PAKISTAN', font: img.arial14, x: 150, y: 340, color: img.ColorRgba8(245, 158, 11, 255));
  return im;
}
