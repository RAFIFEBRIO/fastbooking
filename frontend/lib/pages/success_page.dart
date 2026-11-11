import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config.dart';
import '../models/booking_draft.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'flow_helpers.dart';
import 'history_page.dart';

class SuccessPage extends StatefulWidget {
  final int reservationId;
  final String method; // kosong jika tanpa pembayaran
  const SuccessPage({super.key, required this.reservationId, this.method = ''});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getReservation(widget.reservationId);
  }

  void _retry() => setState(() => _future = ApiService.getReservation(widget.reservationId));

  Widget _body(Map<String, dynamic> res) {
    final paid = toNum(res['total_amount']) > 0;
    final d = DateTime.tryParse('${res['reservation_date']}') ?? DateTime.now();
    final time = '${res['reservation_time']}'.replaceAll(':', '.');
    final detail =
        '${res['area']} · ${dayShort(d)}, ${d.day} ${monthShort(d)} · $time · ${res['guest_count']} tamu';
    final items = List<dynamic>.from(res['items'] as List);
    final code = '${res['booking_code']}';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.brown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 38, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(paid ? 'Pembayaran Berhasil' : 'Reservasi Berhasil',
                    textAlign: TextAlign.center, style: heading(30)),
                const SizedBox(height: 6),
                const Text('Tunjukkan QR ini kepada pelayan saat tiba.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(24),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: QrImageView(
                          data: 'FASTBOOKING|$code',
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.brownDark,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('${res['table_name']}', style: heading(34)),
                      const SizedBox(height: 4),
                      Text(detail,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      Text('KODE BOOKING · $code',
                          style: const TextStyle(
                              letterSpacing: 1.4,
                              fontSize: 13,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('Pesanan Anda', style: heading(22))),
                      Text(rupiah(res['total_amount']),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final raw in items)
                    _itemRow(Map<String, dynamic>.from(raw as Map)),
                  if (widget.method.isNotEmpty) ...[
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Metode pembayaran',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                        Text(widget.method,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: 'Lihat Pesanan',
                               onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                ),
              ),
              TextButton(
                onPressed: () => goHome(context),
                child: const Text('Kembali ke Beranda',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brownDark)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemRow(Map<String, dynamic> i) {
    final path = AppConfig.menuItemImage('${i['category_name']}', '${i['image_url']}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              path,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppColors.cream,
                child: const Icon(Icons.restaurant, size: 20, color: AppColors.brown),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${i['name']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          Text('${toNum(i['quantity']).toInt()}×',
              style: const TextStyle(color: AppColors.textMuted)),
        ],
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
            child: FutureBuilder<Map<String, dynamic>>(
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
                        TextButton(onPressed: _retry, child: const Text('Coba lagi')),
                        TextButton(
                          onPressed: () => goHome(context),
                          child: const Text('Kembali ke Beranda'),
                        ),
                      ],
                    ),
                  );
                }
                return _body(snap.data!);
              },
            ),
          ),
        ),
      ),
    );
  }
}