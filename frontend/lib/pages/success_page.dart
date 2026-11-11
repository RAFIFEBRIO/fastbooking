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
  /// Isi salah satu: reservationId (reservasi meja) atau orderId (datang langsung)
  final int? reservationId;
  final int? orderId;
  final String method; // kosong jika tanpa pembayaran
  const SuccessPage({super.key, this.reservationId, this.orderId, this.method = ''})
      : assert(reservationId != null || orderId != null);

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  late Future<Map<String, dynamic>> _future;

  bool get _isOrder => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() => _isOrder
      ? ApiService.getOrder(widget.orderId!)
      : ApiService.getReservation(widget.reservationId!);

  void _retry() => setState(() => _future = _load());

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

  Widget _body(Map<String, dynamic> res) {
    final paid = toNum(res['total_amount']) > 0;
    final items = List<dynamic>.from(res['items'] as List);

    late final String place;
    late final String detail;
    late final String code;
    late final String hint;
    late final String codeLabel;

    if (_isOrder) {
      final label = '${res['table_label'] ?? ''}'.trim();
      final c = (DateTime.tryParse('${res['created_at']}') ?? DateTime.now()).toLocal();
      place = label.isEmpty ? 'Datang langsung' : 'Meja $label';
      detail = 'Makan di tempat · ${dayShort(c)}, ${c.day} ${monthShort(c)} · ${_hm(c)}';
      code = '${res['order_code']}';
      hint = 'Tunjukkan QR ini kepada pelayan untuk memproses pesanan Anda.';
      codeLabel = 'KODE PESANAN';
    } else {
      final d = DateTime.tryParse('${res['reservation_date']}') ?? DateTime.now();
      final time = '${res['reservation_time']}'.replaceAll(':', '.');
      place = '${res['table_name']}';
      detail =
          '${res['area']} · ${dayShort(d)}, ${d.day} ${monthShort(d)} · $time · ${res['guest_count']} tamu';
      code = '${res['booking_code']}';
      hint = 'Tunjukkan QR ini kepada pelayan saat tiba.';
      codeLabel = 'KODE BOOKING';
    }

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
                Text(hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted)),
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
                      Text(place, textAlign: TextAlign.center, style: heading(34)),
                      const SizedBox(height: 4),
                      Text(detail,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      Text('$codeLabel · $code',
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
                  for (final raw in items) _itemRow(Map<String, dynamic>.from(raw as Map)),
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