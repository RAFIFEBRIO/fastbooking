import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/format.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const _areas = ['Semua', 'Indoor', 'Outdoor', 'VIP'];

  late Future<List<dynamic>> _paketFuture;
  late Future<List<dynamic>> _tablesFuture;
  String _area = 'Semua';

  @override
  void initState() {
    super.initState();
    _paketFuture = ApiService.getMenu(category: 'Paket');
    _loadTables();
  }

  void _loadTables() {
    _tablesFuture = ApiService.getTables(area: _area == 'Semua' ? null : _area);
  }

  Future<void> _refresh() async {
    setState(() {
      _paketFuture = ApiService.getMenu(category: 'Paket');
      _loadTables();
    });
    await Future.wait([_paketFuture, _tablesFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?['full_name'] ?? '';
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hai, $name', style: const TextStyle(color: Colors.black54)),
            const Text('Kenneth Resto',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.brown)),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: _paketFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                      height: 170, child: Center(child: CircularProgressIndicator()));
                }
                if (snap.hasError) return _ErrorBox(message: '${snap.error}', onRetry: _refresh);
                return PaketSlider(items: snap.data!);
              },
            ),
            const SizedBox(height: 20),
            const Text('Meja Tersedia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _areas
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(a),
                            selected: _area == a,
                            selectedColor: AppColors.brown,
                            labelStyle: TextStyle(color: _area == a ? Colors.white : Colors.black87),
                            showCheckmark: false,
                            onSelected: (_) => setState(() {
                              _area = a;
                              _loadTables();
                            }),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _tablesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) return _ErrorBox(message: '${snap.error}', onRetry: _refresh);
                final tables = snap.data!;
                if (tables.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada meja')),
                  );
                }
                return Column(children: tables.map((t) => TableCard(table: t)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PaketSlider extends StatefulWidget {
  final List<dynamic> items;
  const PaketSlider({super.key, required this.items});

  @override
  State<PaketSlider> createState() => _PaketSliderState();
}

class _PaketSliderState extends State<PaketSlider> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || widget.items.isEmpty) return;
      final next = (_index + 1) % widget.items.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(AppConfig.paketImage(item['image_url']), fit: BoxFit.cover),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(rupiah(item['price']),
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _index ? AppColors.brown : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TableCard extends StatelessWidget {
  final Map<String, dynamic> table;
  const TableCard({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                AppConfig.mejaImage(table['image_url']),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(table['name'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(table['area'], style: const TextStyle(color: AppColors.brown)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text('${table['capacity']} orang',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}