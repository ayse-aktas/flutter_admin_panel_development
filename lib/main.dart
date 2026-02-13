import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_panel_development/screens/auth/auth_wrapper.dart';
import 'package:flutter_admin_panel_development/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_admin_panel_development/services/auth_service.dart';
import 'package:flutter_admin_panel_development/services/cart_service.dart';
import 'package:flutter_admin_panel_development/services/database_service.dart';
import 'package:flutter_admin_panel_development/services/storage_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('FIREBASE INIT ERROR: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<CartService>(create: (_) => CartService()),
      ],
      child: MaterialApp(
        title: 'Admin Panel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // home: const AdminDashboard(),
        home: const AuthWrapper(),
      ),
    );
  }
}
