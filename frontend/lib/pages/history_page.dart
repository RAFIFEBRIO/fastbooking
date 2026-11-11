import 'package:flutter/material.dart';
import '../models/booking_draft.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'success_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _filters = <String, String?>{
    'Semua': null,
    'Lunas': 'paid',
    'Menunggu': 'pending',
    'Dibatalkan': 'cancelled',
  };

  late Future<List<dynamic>> _future;
  String _filter = 'Semua';

  @override
  void initState() {
    super.initState();
    _future = ApiService.getReservations();
  }

  void _reload() => setState(() => _future = ApiService.getReservations());

  ({String label, Color color}) _status(String s) {
    switch (s) {
      case 'paid':
        return (label: 'Lunas', color: AppColors.green);
      case 'pending':
        return (label: 'Menunggu pembayaran', color: const Color(0xFFB7791F));
      case 'cancelled':
        return (label: 'Dibatalkan', color: AppColors.red);
      default:
        return (label: 'Selesai', color: AppColors.textMuted);
    }
  }

  Widget _chip(String label) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brown : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? AppColors.brown : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.brownDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final st = _status('${r['status']}');
    final d = DateTime.tryParse('${r['reservation_date']}') ?? DateTime.now();
    final time = '${r['reservation_time']}'.replaceAll(':', '.');
    final paid = r['status'] == 'paid';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (paid) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SuccessPage(reservationId: (r['id'] as num).toInt()),
            ));
          } else {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('QR hanya tersedia untuk reservasi yang sudah lunas')),
              );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${r['table_name']} · ${r['area']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: st.color.withAlpha(28),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(st.label,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: st.color)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${dayShort(d)}, ${d.day} ${monthShort(d)} ${d.year} · $time · ${r['guest_count']} tamu',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const Divider(height: 22, color: AppColors.border),
              Row(
                children: [
                  Expanded(
                    child: Text('Kode ${r['booking_code']}',
                        style: const TextStyle(
                            color: AppColors.textMuted, letterSpacing: 0.8, fontSize: 13)),
                  ),
                  Text(rupiah(r['total_amount']),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  if (paid) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.qr_code_2, size: 20, color: AppColors.brown),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text('Riwayat Pemesanan',
                            textAlign: TextAlign.center, style: heading(22)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
                  child: Row(children: [for (final f in _filters.keys) _chip(f)]),
                ),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${snap.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.red)),
                              TextButton(onPressed: _reload, child: const Text('Coba lagi')),
                            ],
                          ),
                        );
                      }
                      final wanted = _filters[_filter];
                      final all = snap.data!
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList();
                      final list =
                          wanted == null ? all : all.where((r) => r['status'] == wanted).toList();

                      if (list.isEmpty) {
                        return ListView(
                          children: const [
                            SizedBox(height: 90),
                            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.border),
                            SizedBox(height: 12),
                            Text('Belum ada pemesanan',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                          ],
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          _reload();
                          await _future;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (_, i) => _card(list[i]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}