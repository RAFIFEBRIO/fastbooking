import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import 'home_page.dart';
import 'register_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      auth.load(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomePage() : const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant, size: 72, color: AppColors.brown),
            const SizedBox(height: 12),
            const Text('FastBooking',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brown)),
            const Text('Restaurant & Food Ordering App',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 40),
            const Text('Selamat datang di', style: TextStyle(color: Colors.black54)),
            const Text('Kenneth Resto',
                style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic, color: AppColors.brown)),
          ],
        ),
      ),
    );
  }
}