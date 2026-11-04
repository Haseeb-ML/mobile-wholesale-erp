class ShopSettings {
  final String shopName;
  final String address;
  final String phone;
  final String? logoPath;
  final String invoiceFooter;
  final double defaultTaxPercent;
  final String currency;
  final String language; // 'en' or 'ur'
  final String ownerPinHash;
  final String ownerPinSalt;
  final String activeRole; // 'owner', 'sales', 'accountant'
  final String? lastBackupDate;

  ShopSettings({
    required this.shopName,
    required this.address,
    required this.phone,
    this.logoPath,
    required this.invoiceFooter,
    this.defaultTaxPercent = 0.0,
    this.currency = 'PKR',
    this.language = 'en',
    this.ownerPinHash = '',
    this.ownerPinSalt = '',
    this.activeRole = 'owner',
    this.lastBackupDate,
  });

  factory ShopSettings.defaultSettings() {
    return ShopSettings(
      shopName: 'Al-Madina Mobile Accessories Wholesale',
      address: 'Shop # 14-16, 2nd Floor, Star City Mall, Saddar, Karachi',
      phone: '+92 300 1234567',
      logoPath: 'assets/images/branding/logo.png',
      invoiceFooter: 'Goods once sold can only be returned within 3 days in saleable condition. All claims subject to Karachi jurisdiction. Thank you for your business!',
      defaultTaxPercent: 0.0,
      currency: 'PKR',
      language: 'en',
      activeRole: 'owner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_name': shopName,
      'address': address,
      'phone': phone,
      'logo_path': logoPath,
      'invoice_footer': invoiceFooter,
      'default_tax_percent': defaultTaxPercent,
      'currency': currency,
      'language': language,
      'owner_pin_hash': ownerPinHash,
      'owner_pin_salt': ownerPinSalt,
      'active_role': activeRole,
      'last_backup_date': lastBackupDate,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      shopName: map['shop_name'] ?? 'Mobile Wholesale ERP',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      logoPath: map['logo_path'],
      invoiceFooter: map['invoice_footer'] ?? '',
      defaultTaxPercent: (map['default_tax_percent'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'PKR',
      language: map['language'] ?? 'en',
      ownerPinHash: map['owner_pin_hash'] ?? '',
      ownerPinSalt: map['owner_pin_salt'] ?? '',
      activeRole: map['active_role'] ?? 'owner',
      lastBackupDate: map['last_backup_date'],
    );
  }

  ShopSettings copyWith({
    String? shopName,
    String? address,
    String? phone,
    String? logoPath,
    String? invoiceFooter,
    double? defaultTaxPercent,
    String? currency,
    String? language,
    String? ownerPinHash,
    String? ownerPinSalt,
    String? activeRole,
    String? lastBackupDate,
  }) {
    return ShopSettings(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      ownerPinHash: ownerPinHash ?? this.ownerPinHash,
      ownerPinSalt: ownerPinSalt ?? this.ownerPinSalt,
      activeRole: activeRole ?? this.activeRole,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }
}

