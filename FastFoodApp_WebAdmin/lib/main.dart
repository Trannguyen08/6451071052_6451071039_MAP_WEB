import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final hasAdminToken = (storage.read<String>('adminToken') ?? '').isNotEmpty;

    return GetMaterialApp(
      title: 'Fast Food Admin',
      debugShowCheckedModeBanner: false,
      initialRoute: hasAdminToken
          ? AppRoutes.adminDashboard
          : AppRoutes.adminLogin,
      getPages: AppPages.pages,
    );
  }
}
