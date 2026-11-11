import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'flow_helpers.dart';
import 'success_page.dart';

class PaymentPage extends StatefulWidget {
  /// Data reservasi atau pesanan dari server
  final Map<String, dynamic> target;
  final Map<String, dynamic> payment;
  final DateTime deadline;
  final bool isOrder;
  final VoidCallback? onPaid;
  const PaymentPage({
    super.key,
    required this.target,
    required this.payment,
    required this.deadline,
    this.isOrder = false,
    this.onPaid,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _bankNumber = '1234567890';

  Timer? _timer;
  int _left = 0;
  bool _busy = false;

  String get _method => '${widget.payment['method']}';
  double get _amount => toNum(widget.payment['amount']);
  String get _code =>
      '${widget.payment['code'] ?? widget.payment['booking_code'] ?? ''}';

  String get _place {
    if (widget.isOrder) {
      final l = '${widget.target['table_label'] ?? ''}'.trim();
      return l.isEmpty ? 'Datang langsung' : 'Meja $l';
    }
    return '${widget.target['table_name']}';
  }

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final left = widget.deadline.difference(DateTime.now()).inSeconds;
    setState(() => _left = left < 0 ? 0 : left);
    if (left <= 0) {
      _timer?.cancel();
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        showExpiredAndGoHome(
          context,
          message: widget.isOrder
              ? 'Pesanan dibatalkan. Silakan buat pesanan baru.'
              : 'Reservasi dibatalkan. Silakan pilih meja dan reservasi ulang.',
        );
      }
    }
  }

  Future<void> _paid() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ApiService.confirmPayment((widget.payment['id'] as num).toInt());
      widget.onPaid?.call();
      if (!mounted) return;
      final id = (widget.target['id'] as num).toInt();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SuccessPage(
            reservationId: widget.isOrder ? null : id,
            orderId: widget.isOrder ? id : null,
            method: methodLabel(_method),
          ),
        ),
        (r) => r.isFirst,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _qrBox() {
    final payload = '${widget.payment['qr_payload'] ?? 'FASTBOOKING|$_code|$_amount'}';
    return _card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: payload,
              size: 240,
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
          const Text(
            'Buka aplikasi e-wallet atau m-banking, lalu scan kode QR ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _transferBox() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transfer ke rekening',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          const Text('Bank BCA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '1234 5678 90',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                ),
              ),
              IconButton(
                tooltip: 'Salin',
                icon: const Icon(Icons.copy_rounded, color: AppColors.brown),
                onPressed: () async {
                  await Clipboard.setData(const ClipboardData(text: _bankNumber));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Nomor rekening disalin')));
                },
              ),
            ],
          ),
          const Text('a.n. Kenneth Resto', style: TextStyle(color: AppColors.textMuted)),
          const Divider(height: 28, color: AppColors.border),
          Text('Transfer tepat ${rupiah(_amount)} dan cantumkan berita $_code.',
              style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _walletBox(String name) {
    Widget step(int n, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Text('$n',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.brown)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
            ],
          ),
        );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bayar lewat $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          step(1, 'Buka aplikasi $name di ponsel Anda.'),
          step(2, 'Pilih menu Bayar, lalu masukkan kode pesanan $_code.'),
          step(3, 'Konfirmasi nominal ${rupiah(_amount)}, lalu selesaikan pembayaran.'),
        ],
      ),
    );
  }

  Widget _methodBox() {
    switch (_method) {
      case 'transfer':
        return _transferBox();
      case 'ovo':
        return _walletBox('OVO');
      case 'gopay':
        return _walletBox('GoPay');
      default:
        return _qrBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _method == 'qris' ? 'Bayar dengan QRIS' : 'Bayar dengan ${methodLabel(_method)}';

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
                        child: Text('Pembayaran',
                            textAlign: TextAlign.center, style: heading(22)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                    child: Column(
                      children: [
                        Text(title, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            text: 'Rp ',
                            style: const TextStyle(
                                fontSize: 22, color: AppColors.textMuted),
                            children: [
                              TextSpan(
                                text: numberId(_amount),
                                style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brownDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kenneth Resto · $_place · No. pesanan $_code',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 22),
                        _methodBox(),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule, size: 18, color: AppColors.brown),
                              const SizedBox(width: 8),
                              Text('Selesaikan dalam ${mmss(_left)} menit',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: AppColors.brown)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Pembayaran disimulasikan untuk keperluan tugas.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
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
                        label: 'Saya Sudah Bayar',
                        loading: _busy,
                        onPressed: _paid,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Ganti metode pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: AppColors.brown)),
                      ),
                    ],
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