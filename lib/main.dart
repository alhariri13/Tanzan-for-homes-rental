import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tanzan/login_screen.dart';
import 'localization_service.dart';
import 'translations.dart';

void main() async {
  // ضروري جداً لتهيئة فلاتر و GetStorage قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تعريف خدمة اللغة
    final localizationService = LocalizationService();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tanzan App',

      // 1. إعدادات اللغة والترجمة
      translations: MyMessages(),
      locale: localizationService.locale,
      fallbackLocale: localizationService.fallbackLocale,

      // 2. إعدادات الثيم (الوضع الفاتح والداكن)
      // الثيم الفاتح (Light Mode)
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),

      // الثيم الداكن (Dark Mode)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        // لون الخلفية الداكن المناسب لتصميمك
        scaffoldBackgroundColor: const Color(0xFF1B1C27),
      ),

      // يجعل التطبيق يبدأ بوضع النظام (تلقائي) أو يمكنكِ تحديد أحدهما
      themeMode: ThemeMode.system,

      // 3. واجهة البداية
      home: const LoginScreen(),
    );
  }
}
