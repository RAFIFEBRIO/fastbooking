import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?['full_name'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kenneth Resto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RegisterPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(child: Text('Halo, $name!\n(Beranda menyusul)', textAlign: TextAlign.center)),
    );
  }
}