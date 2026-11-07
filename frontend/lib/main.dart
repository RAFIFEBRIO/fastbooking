import 'package:flutter/material.dart';
import 'config.dart';
import 'services/api_service.dart';

void main() => runApp(const FastBookingApp());

class FastBookingApp extends StatelessWidget {
  const FastBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastBooking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C3D2E)),
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tes Koneksi: Daftar Meja')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getTables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final tables = snapshot.data!;
          return ListView.builder(
            itemCount: tables.length,
            itemBuilder: (context, i) {
              final t = tables[i];
              return ListTile(
                leading: Image.asset(
                  AppConfig.mejaImage(t['image_url']),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
                title: Text(t['name']),
                subtitle: Text('${t['area']} • ${t['capacity']} orang'),
              );
            },
          );
        },
      ),
    );
  }
}