import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationService {
  final _box = GetStorage();
  final _key = 'isArabic';
  final fallbackLocale = const Locale('en', 'US');

  // قراءة اللغة المحفوظة أو استخدام الإنجليزية كافتراضية
  Locale get locale => _loadLocale() ? const Locale('ar') : const Locale('en');

  bool _loadLocale() => _box.read(_key) ?? false;

  void saveLocale(bool isArabic) => _box.write(_key, isArabic);

  // دالة لتغيير اللغة
  void changeLocale() {
    bool isCurrentlyArabic = _loadLocale();
    Get.updateLocale(isCurrentlyArabic ? const Locale('en') : const Locale('ar'));
    saveLocale(!isCurrentlyArabic);
  }
}