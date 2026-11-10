import 'package:flutter/material.dart';
import '../config.dart';
import '../models/cart.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Daftar menu: tab kategori dan grid. Ketuk menu untuk membuka pop up.
class MenuBrowser extends StatefulWidget {
  final CartController cart;
  final String? foodNote;
  final String? vipNote;
  final double hPad;
  const MenuBrowser({
    super.key,
    required this.cart,
    this.foodNote,
    this.vipNote,
    this.hPad = 24,
  });

  @override
  State<MenuBrowser> createState() => _MenuBrowserState();
}

class _MenuBrowserState extends State<MenuBrowser> {
  static const _cats = ['Makanan', 'Minuman', 'Dessert', 'Paket'];

  late Future<List<dynamic>> _future;
  String _cat = 'Makanan';

  @override
  void initState() {
    super.initState();
    _future = ApiService.getMenu();
  }

  void _retry() => setState(() => _future = ApiService.getMenu());

  Widget _tabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: widget.hPad),
        child: Row(
          children: _cats.map((c) {
            final selected = c == _cat;
            return GestureDetector(
              onTap: () => setState(() => _cat = c),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  margin: const EdgeInsets.only(right: 26),
                  padding: const EdgeInsets.only(bottom: 10, top: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? AppColors.brown : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? AppColors.brownDark : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _card(Map item, double itemW) {
    final id = (item['id'] as num).toInt();
    final qty = widget.cart.qtyOf(id);
    final path = AppConfig.menuItemImage('${item['category_name']}', '${item['image_url']}');

    return GestureDetector(
      onTap: () => showMenuItemSheet(
        context,
        Map<String, dynamic>.from(item),
        widget.cart,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    path,
                    width: itemW,
                    height: itemW,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: itemW,
                      height: itemW,
                      color: AppColors.cream,
                      child: const Icon(Icons.restaurant, color: AppColors.brown),
                    ),
                  ),
                ),
                if (qty > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.brown,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Text(
                        '$qty',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${item['name']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
            ),
            const SizedBox(height: 4),
            Text(
              rupiah(item['price']),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tabs(),
        if (widget.vipNote != null)
          Padding(
            padding: EdgeInsets.fromLTRB(widget.hPad, 12, widget.hPad, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined,
                      size: 20, color: AppColors.brown),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.vipNote!,
                      style: const TextStyle(
                        color: AppColors.brown,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.foodNote != null && _cat == 'Makanan')
          Padding(
            padding: EdgeInsets.fromLTRB(widget.hPad, 12, widget.hPad, 0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.foodNote!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
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
                      TextButton(onPressed: _retry, child: const Text('Coba lagi')),
                    ],
                  ),
                );
              }
              final items = snap.data!.where((m) => m['category_name'] == _cat).toList();
              if (items.isEmpty) {
                return const Center(child: Text('Belum ada menu'));
              }

              return LayoutBuilder(
                builder: (context, c) {
                  const gap = 16.0;
                  final w = c.maxWidth - widget.hPad * 2;
                  final cols = (w / 190).floor().clamp(2, 5);
                  final itemW = (w - gap * (cols - 1)) / cols;

                  return ListenableBuilder(
                    listenable: widget.cart,
                    builder: (context, _) => GridView.builder(
                      padding: EdgeInsets.fromLTRB(widget.hPad, 16, widget.hPad, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: gap,
                        mainAxisSpacing: 18,
                        mainAxisExtent: itemW + 84,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _card(items[i] as Map, itemW),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bar cokelat di bawah: "2 item · Rp ... | Lihat Pesanan".
/// - Keranjang kosong: tersembunyi, kecuali [emptyAction] diisi (tombol "Lewati")
///   atau [minOrder] > 0 (bar redup berisi [emptyLabel]).
/// - [minOrder] > 0: pesanan baru bisa dilanjutkan setelah total mencapai minimal order.
class CartBar extends StatelessWidget {
  final CartController cart;
  final String emptyLabel;
  final String emptyAction;
  final double minOrder;
  final VoidCallback onTap;
  const CartBar({
    super.key,
    required this.cart,
    required this.onTap,
    this.emptyLabel = '',
    this.emptyAction = '',
    this.minOrder = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final empty = cart.isEmpty;
        final total = cart.total;
        final blocked = minOrder > 0 && total < minOrder;
                final show = !empty || emptyAction.isNotEmpty;

        String label;
        String action;
        if (empty) {
          label = emptyLabel;
          action = emptyAction;
        } else if (blocked) {
          label = '${cart.count} item · ${rupiah(total)}';
          action = 'Kurang ${rupiah(minOrder - total)}';
        } else {
          label = '${cart.count} item · ${rupiah(total)}';
          action = 'Lihat Pesanan';
        }

        final disabled = empty && emptyAction.isEmpty;
        final dim = disabled || blocked;

        void handleTap() {
          if (disabled) return;
          if (blocked) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Minimal order meja VIP ${rupiah(minOrder)}'),
                ),
              );
            return;
          }
          onTap();
        }

        const textStyleLabel = TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        );
        const textStyleAction = TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        );

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: !show
              ? const SizedBox(width: double.infinity)
              : Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brown.withAlpha(dim ? 25 : 70),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: dim ? AppColors.brown.withAlpha(150) : AppColors.brown,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: disabled ? null : handleTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 19),
                          child: label.isEmpty
                              ? Center(child: Text(action, style: textStyleAction))
                              : Row(
                                  children: [
                                    Expanded(child: Text(label, style: textStyleLabel)),
                                    if (action.isNotEmpty)
                                      Text(action, style: textStyleAction),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Pop up dari bawah saat menu diketuk
Future<void> showMenuItemSheet(
  BuildContext context,
  Map<String, dynamic> item,
  CartController cart,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _ItemSheet(item: item, cart: cart),
  );
}

class _ItemSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final CartController cart;
  const _ItemSheet({required this.item, required this.cart});

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  static const _iceOptions = ['Normal Ice', 'Less Ice', 'No Ice'];
  static const _sugarOptions = ['Normal Sugar', 'Less Sugar', 'No Sugar'];

  int _qty = 1;
  String _ice = _iceOptions.first;
  String _sugar = _sugarOptions.first;
  final _note = TextEditingController();

  bool get _isDrink => widget.item['category_name'] == 'Minuman';
  double get _price => double.tryParse('${widget.item['price']}') ?? 0;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _add() {
    final parts = <String>[];
    if (_isDrink) {
      parts.add(_ice);
      parts.add(_sugar);
    }
    final n = _note.text.trim();
    if (n.isNotEmpty) parts.add(n);
    widget.cart.add(widget.item, _qty, note: parts.join(' · '));
    Navigator.of(context).pop();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brown : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.brown : AppColors.brownDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(String title, List<String> options, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in options) _chip(o, o == value, () => setState(() => onChanged(o))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _round(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: enabled ? AppColors.brown : AppColors.border, width: 1.4),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.brown : const Color(0xFFC9BFB5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final path = AppConfig.menuItemImage('${item['category_name']}', '${item['image_url']}');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tombol tutup
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 12),
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.close, size: 22, color: AppColors.brownDark),
                ),
              ),
            ),
          ),
          Flexible(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    path,
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 92,
                                      height: 92,
                                      color: AppColors.cream,
                                      child: const Icon(Icons.restaurant, color: AppColors.brown),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${item['name']}',
                                          style: const TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 4),
                                      Text(rupiah(item['price']),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.brown)),
                                      const SizedBox(height: 6),
                                      Text('${item['description'] ?? ''}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textMuted,
                                              height: 1.35)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_isDrink) ...[
                              _group('Es', _iceOptions, _ice, (v) => _ice = v),
                              _group('Gula', _sugarOptions, _sugar, (v) => _sugar = v),
                            ],
                            const Text('Catatan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _note,
                              maxLength: 100,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Contoh: jangan terlalu pedas',
                                hintStyle: const TextStyle(color: Color(0xFF9C8F84)),
                                filled: true,
                                fillColor: AppColors.creamSoft,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.brown),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    // Jumlah dan tombol tambah
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                      child: Row(
                        children: [
                          _round(Icons.remove, _qty > 1, () => setState(() => _qty--)),
                          SizedBox(
                            width: 40,
                            child: Text('$_qty',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                          _round(Icons.add, true, () => setState(() => _qty++)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Tambah - ${rupiah(_price * _qty)}',
                              onPressed: _add,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}