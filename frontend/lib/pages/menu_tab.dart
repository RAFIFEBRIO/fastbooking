import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/menu_browser.dart';
import 'checkout_page.dart';

class MenuTab extends StatefulWidget {
  final VoidCallback onGoHome;
  const MenuTab({super.key, required this.onGoHome});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final _cart = CartController();
  bool _walkIn = true; // true = Datang langsung

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  void _viewOrder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(draft: null, cart: _cart),
      ),
    );
  }

  Widget _seg(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.brown : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmented() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 14),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _seg('Reservasi saya', !_walkIn, () => setState(() => _walkIn = false)),
          _seg('Datang langsung', _walkIn, () => setState(() => _walkIn = true)),
        ],
      ),
    );
  }

  Widget _reservationInfo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.cream,
              child: Icon(Icons.event_seat_outlined, size: 38, color: AppColors.brown),
            ),
            const SizedBox(height: 18),
            Text('Belum ada reservasi', style: heading(24)),
            const SizedBox(height: 8),
            const Text(
              'Pilih meja, tanggal, dan jam di Beranda, lalu pilih menu setelahnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 260,
              child: PrimaryButton(label: 'Pilih meja', onPressed: widget.onGoHome),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Menu', style: heading(30)),
                ),
              ),
              _segmented(),
              if (_walkIn) ...[
                Expanded(child: MenuBrowser(cart: _cart)),
                CartBar(cart: _cart, onTap: _viewOrder),
              ] else
                Expanded(child: _reservationInfo()),
            ],
          ),
        ),
      ),
    );
  }
}