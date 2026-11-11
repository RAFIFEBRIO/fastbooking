import 'dart:async';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/booking_draft.dart';
import '../models/cart.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'flow_helpers.dart';
import 'payment_page.dart';

class _Method {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  const _Method(this.key, this.title, this.subtitle, this.icon);
}

const _methods = [
  _Method('transfer', 'Transfer', 'Transfer bank', Icons.account_balance_outlined),
  _Method('ovo', 'OVO', 'Bayar dengan OVO', Icons.account_balance_wallet_outlined),
  _Method('gopay', 'GoPay', 'Bayar dengan GoPay', Icons.smartphone),
  _Method('qris', 'QRIS', 'Semua e-wallet & m-banking', Icons.qr_code_2),
];

class CheckoutPage extends StatefulWidget {
  /// Data reservasi. Kosong (null) berarti pesanan datang langsung.
  final BookingDraft? draft;
  final CartController cart;
  const CheckoutPage({super.key, required this.draft, required this.cart});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const double _feeRate = 0.15; // pajak 10% + layanan 5%
  static const double _vipMinOrder = 500000;
  static const int _holdSeconds = 15 * 60;

  // Reservasi atau pesanan di server, baru dibuat saat tombol bayar ditekan
  Map<String, dynamic>? _res;
  bool _busy = false;
  bool _leaving = false;
  String _method = 'qris';
  late DateTime _deadline;
  int _left = _holdSeconds;
  Timer? _timer;
  final _tableCtl = TextEditingController();

  BookingDraft? get _d => widget.draft;
  bool get _walkIn => _d == null;
  CartController get _cart => widget.cart;
  bool get _isVip => !_walkIn && '${_d!.table['area']}' == 'VIP';
  bool get _noOrder => _cart.isEmpty;
  double get _subtotal => _cart.total;
  double get _fee => (_subtotal * _feeRate).roundToDouble();
  double get _total => _subtotal + _fee;
  bool get _belowMin => _isVip && !_noOrder && _subtotal < _vipMinOrder;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(const Duration(seconds: _holdSeconds));
    _cart.addListener(_onCartChanged);
    _startTimer();
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _timer?.cancel();
    _tableCtl.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _deadline.difference(DateTime.now()).inSeconds;
      setState(() => _left = left < 0 ? 0 : left);
      if (left <= 0) {
        _timer?.cancel();
        // Kalau halaman bayar sedang di atas, ia yang menangani waktu habis
        if (ModalRoute.of(context)?.isCurrent ?? false) _expire();
      }
    });
  }

  Future<void> _expire() async {
    await _cancelOnServer();
    if (!mounted) return;
    await showExpiredAndGoHome(
      context,
      message: _walkIn
          ? 'Pesanan dibatalkan. Silakan buat pesanan baru.'
          : 'Reservasi dibatalkan. Silakan pilih meja dan reservasi ulang.',
    );
  }

  Future<void> _cancelOnServer() async {
    final id = _res?['id'];
    _res = null;
    if (id != null) {
      try {
        final n = (id as num).toInt();
        if (_walkIn) {
          await ApiService.cancelOrder(n);
        } else {
          await ApiService.cancelReservation(n);
        }
      } catch (_) {}
    }
  }

  /// Ubah isi pesanan. Data yang sudah terlanjur dibuat di server dibatalkan
  /// dan akan dibuat ulang saat tombol bayar ditekan lagi.
  void _edit(VoidCallback change) {
    if (_res != null) {
      _cancelOnServer();
      _deadline = DateTime.now().add(const Duration(seconds: _holdSeconds));
      _left = _holdSeconds;
    }
    change();
  }

  /// Keluar dari checkout: batalkan yang belum dibayar
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _cancelOnServer();
    if (mounted) Navigator.of(context).pop();
  }

  Future<Map<String, dynamic>> _createOnServer() {
    final d = _d;
    if (d == null) {
      return ApiService.createOrder(
        tableLabel: _tableCtl.text.trim(),
        items: _cart.toApiItems(),
      );
    }
    return ApiService.createReservation(
      tableId: (d.table['id'] as num).toInt(),
      date: d.dateKey,
      time: d.time,
      guests: d.guests,
      notes: d.notes,
      items: _cart.toApiItems(),
    );
  }

  Future<void> _pay() async {
    // Wajib ada pesanan menu: kembali ke halaman menu
    if (_noOrder) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_busy || _belowMin) return;
    setState(() => _busy = true);
    try {
      Map<String, dynamic> res;
      if (_res != null) {
        res = _res!;
      } else {
        res = await _createOnServer();
        if (!mounted) {
          try {
            final n = (res['id'] as num).toInt();
            if (_walkIn) {
              await ApiService.cancelOrder(n);
            } else {
              await ApiService.cancelReservation(n);
            }
          } catch (_) {}
          return;
        }
        final secs = toNum(res['expires_in']).toInt();
        setState(() {
          _res = res;
          _deadline = DateTime.now().add(Duration(seconds: secs));
          _left = secs;
        });
      }

      final id = (res['id'] as num).toInt();
      final payment = await ApiService.createPayment(
        reservationId: _walkIn ? null : id,
        orderId: _walkIn ? id : null,
        method: _method,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            target: res,
            payment: payment,
            deadline: _deadline,
            isOrder: _walkIn,
            onPaid: () => _cart.clear(),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Tampilan ----------

  String get _headLabel => _noOrder
      ? (_walkIn ? 'Pesanan makan di tempat' : 'Reservasi meja')
      : 'Total pembayaran';

  String get _headTitle => _walkIn ? 'Datang langsung' : '${_d!.table['name']}';

  String get _headSub {
    if (_walkIn) {
      final l = _tableCtl.text.trim();
      return l.isEmpty ? 'Makan di tempat' : 'Meja $l';
    }
    final d = _d!;
    return _noOrder ? '${d.table['area']} · ${d.label}' : '${d.table['name']} · ${d.label}';
  }

  Widget _headerBg() {
    Widget ring(double s) => Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(32), width: 1.5),
          ),
        );
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
      child: Container(
        color: AppColors.brown,
        child: Stack(
          children: [
            Positioned(right: -90, top: -60, child: ring(300)),
            Positioned(right: -40, top: -10, child: ring(200)),
            Positioned(
              right: 30,
              top: 50,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashed() {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => Container(width: 4, height: 1.2, color: AppColors.border),
          ),
        );
      },
    );
  }

  Widget _amountRow(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(left,
                style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
          ),
          Text(right,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.border, width: 1.4),
          ),
          child: Icon(icon, size: 18, color: AppColors.brownDark),
        ),
      ),
    );
  }

  Widget _itemRow(CartLine l) {
    final note = l.note.trim();
    final path = AppConfig.menuItemImage('${l.item['category_name']}', '${l.item['image_url']}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              path,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppColors.cream,
                child: const Icon(Icons.restaurant, color: AppColors.brown),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l.item['name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _stepBtn(Icons.remove, () => _edit(() => _cart.decrement(l))),
                    SizedBox(
                      width: 34,
                      child: Text('${l.qty}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    _stepBtn(Icons.add, () => _edit(() => _cart.increment(l))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rupiah(l.subtotal),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _edit(() => _cart.remove(l)),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 24, color: AppColors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Kenneth Resto', style: heading(24))),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text('Ubah',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brown)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_noOrder)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _walkIn
                    ? 'Belum ada menu di pesanan. Tekan Pesan Makanan untuk memilih menu.'
                    : 'Reservasi meja wajib disertai pesanan menu. '
                        'Tekan Pesan Makanan untuk memilih menu.',
                style: const TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            )
          else ...[
            for (final l in List<CartLine>.of(_cart.lines)) _itemRow(l),
            const SizedBox(height: 8),
            _dashed(),
            const SizedBox(height: 10),
            _amountRow('Subtotal', rupiah(_subtotal)),
            _amountRow('Pajak 10% & layanan 5%', rupiah(_fee)),
          ],
        ],
      ),
    );
  }

  Widget _vipWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 22, color: AppColors.brown),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Meja VIP minimal order ${rupiah(_vipMinOrder)}. '
              'Kurang ${rupiah(_vipMinOrder - _subtotal)}, tekan Ubah untuk menambah menu.',
              style: const TextStyle(
                  color: AppColors.brown, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Nomor meja', style: heading(24)),
              const SizedBox(width: 10),
              const Text('Opsional', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tableCtl,
            maxLength: 20,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {
              if (_res != null) _edit(() {});
              setState(() {});
            },
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Contoh: I4 (boleh dikosongkan)',
              hintStyle: const TextStyle(color: Color(0xFF9C8F84)),
              contentPadding: const EdgeInsets.all(18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppColors.brown),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodCard(_Method m) {
    final sel = _method == m.key;
    return GestureDetector(
      onTap: () => setState(() => _method = m.key),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sel ? AppColors.creamSoft : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: sel ? AppColors.brown : AppColors.border,
              width: sel ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(m.icon, size: 26, color: AppColors.brownDark),
                  ),
                  const Spacer(),
                  if (sel)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.brown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 18, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(m.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(m.subtitle,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodGrid() {
    Widget pair(_Method a, _Method b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _methodCard(a)),
              const SizedBox(width: 14),
              Expanded(child: _methodCard(b)),
            ],
          ),
        );
    return Column(
      children: [
        pair(_methods[0], _methods[1]),
        const SizedBox(height: 14),
        pair(_methods[2], _methods[3]),
      ],
    );
  }

  Widget _content() {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, height: 296 + top, child: _headerBg()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text('Checkout',
                        textAlign: TextAlign.center,
                        style: heading(24, color: Colors.white)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_headLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (_noOrder)
                    Text(_headTitle,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800))
                  else
                    Text.rich(
                      TextSpan(
                        text: 'Rp ',
                        style: const TextStyle(color: Colors.white70, fontSize: 24),
                        children: [
                          TextSpan(
                            text: numberId(_total),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 50,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(_headSub,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  if (!_noOrder) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Selesaikan dalam ${mmss(_left)}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _itemsCard(),
            ),
            if (_belowMin) _vipWarning(),
            if (_walkIn && !_noOrder) _tableField(),
            if (!_noOrder) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
                child: Text('Metode Pembayaran', style: heading(24)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _methodGrid(),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ],
    );
  }

  Widget _payBar() {
    final disabled = _busy || _belowMin;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.brown.withAlpha(70),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: FilledButton(
            onPressed: disabled ? null : _pay,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brown,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.brown.withAlpha(140),
              disabledForegroundColor: Colors.white70,
              minimumSize: const Size.fromHeight(60),
              shape: const StadiumBorder(),
            ),
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_noOrder ? Icons.restaurant_menu : Icons.lock_outline, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        _noOrder ? 'Pesan Makanan' : 'Bayar Sekarang',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _res == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(child: SingleChildScrollView(child: _content())),
                _payBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}