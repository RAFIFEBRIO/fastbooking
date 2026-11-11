import 'package:flutter/material.dart';
import '../models/booking_draft.dart';
import '../models/cart.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/menu_browser.dart';
import 'checkout_page.dart';

class MenuPage extends StatefulWidget {
  final BookingDraft draft;
  const MenuPage({super.key, required this.draft});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // Minimal order khusus meja VIP
  static const double _vipMinOrder = 500000;

  final _cart = CartController();

  bool get _isVip => '${widget.draft.table['area']}' == 'VIP';

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  void _viewOrder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(draft: widget.draft, cart: _cart),
      ),
    );
  }

  Widget _reservationCard() {
    final t = widget.draft.table;
    final short = '${t['name']}'.replaceFirst('Meja ', '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              short,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.brown),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t['name']} · ${t['area']}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 2),
                Text('Reservasi ${widget.draft.label}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              side: const BorderSide(color: AppColors.border, width: 1.4),
              foregroundColor: AppColors.brownDark,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Ubah meja', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vip = _isVip;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text('Menu', textAlign: TextAlign.center, style: heading(24)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                _reservationCard(),
                const SizedBox(height: 14),
                Expanded(
                  child: MenuBrowser(
                    cart: _cart,
                    foodNote: 'Pra-pesan: makanan disiapkan saat Anda tiba',
                    vipNote: vip ? 'Meja VIP: minimal order ${rupiah(_vipMinOrder)}' : null,
                  ),
                ),
                // Bar muncul setelah ada menu di keranjang
                CartBar(
                  cart: _cart,
                  minOrder: vip ? _vipMinOrder : 0,
                  onTap: _viewOrder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}