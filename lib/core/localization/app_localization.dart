import 'package:flutter/material.dart';
import 'package:mobile_wholesale_erp/core/localization/app_strings.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static const LocalizationsDelegate<AppLocalization> delegate = AppLocalizationsDelegate();

  static AppLocalization? of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  String translate(String key) {
    return AppStrings.get(key, locale: locale.languageCode);
  }

  bool get isRtl => locale.languageCode == 'ur';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    return AppLocalization(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalization.of(this)?.translate(key) ?? AppStrings.get(key);
  }

  bool get isRtl {
    return AppLocalization.of(this)?.isRtl ?? false;
  }
}

