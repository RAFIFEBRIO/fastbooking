import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/splash_page.dart';
import 'providers/auth_provider.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const FastBookingApp(),
    ),
  );
}

class FastBookingApp extends StatelessWidget {
  const FastBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastBooking',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashPage(),
    );
  }
}