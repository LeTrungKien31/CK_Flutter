// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:house_rent/screens/auth/login_screen.dart';
import 'package:house_rent/screens/home/home.dart';
import 'package:house_rent/screens/admin/admin_dashboard.dart';
import 'package:house_rent/services/auth_service.dart';
import 'package:house_rent/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo database
  try {
    await DatabaseHelper().initDatabase();
    await DatabaseHelper().checkData();
  } catch (e) {
    // ignore: avoid_print
    print('Database initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F6F6),
        primaryColor: const Color(0xFF811B83),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFFA5019),
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            color: Color(0xFF100E34),
          ),
          bodyLarge: TextStyle(
            // ignore: deprecated_member_use
            color: const Color(0xFF100E34).withOpacity(0.5),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Delay 2s để hiện splash
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final isAdmin = await _authService.isAdmin();

      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isAdmin ? const AdminDashboard() : const Home(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_rounded,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'House Rent',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Find Your Sweet Home',
              style: TextStyle(
                fontSize: 14,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
