import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final String category;
  final String productName;
  final double width;
  final double height;
  final double borderRadius;

  const ProductImageWidget({
    super.key,
    this.imagePath,
    required this.category,
    required this.productName,
    this.width = 60,
    this.height = 60,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildCategoryFallback();
    }

    if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCategoryFallback(),
      );
    }

    // Local user uploaded photo
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildCategoryFallback();
        }
        final fullPath = p.join(snapshot.data!.path, imagePath!);
        final file = File(fullPath);
        if (!file.existsSync()) {
          return _buildCategoryFallback();
        }
        return Image.file(
          file,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildCategoryFallback(),
        );
      },
    );
  }

  Widget _buildCategoryFallback() {
    final IconData icon;
    final Color color;

    switch (category.toLowerCase()) {
      case 'chargers':
        icon = Icons.electrical_services;
        color = AppColors.primaryTeal;
        break;
      case 'charging cables':
        icon = Icons.cable;
        color = AppColors.info;
        break;
      case 'power banks':
        icon = Icons.battery_charging_full;
        color = AppColors.highlightAmber;
        break;
      case 'wireless earbuds':
      case 'wired earphones':
        icon = Icons.headphones;
        color = const Color(0xFF8B5CF6);
        break;
      case 'phone covers':
        icon = Icons.phone_android;
        color = const Color(0xFFEC4899);
        break;
      case 'screen protectors':
        icon = Icons.shield_outlined;
        color = const Color(0xFF06B6D4);
        break;
      case 'car chargers':
        icon = Icons.directions_car;
        color = const Color(0xFFF97316);
        break;
      case 'mobile holders':
        icon = Icons.pan_tool_alt;
        color = const Color(0xFF14B8A6);
        break;
      case 'otg adapters':
      case 'usb accessories':
        icon = Icons.usb;
        color = const Color(0xFF64748B);
        break;
      case 'memory cards':
        icon = Icons.sd_card;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.devices_other;
        color = AppColors.primaryTeal;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: width * 0.45),
        ],
      ),
    );
  }
}

