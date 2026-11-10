import 'package:flutter/foundation.dart';

/// Satu baris pesanan di keranjang
class CartLine {
  final Map<String, dynamic> item;
  int qty;
  final String note;
  CartLine({required this.item, required this.qty, this.note = ''});

  int get id => (item['id'] as num).toInt();
  double get unitPrice => double.tryParse('${item['price']}') ?? 0;
  double get subtotal => unitPrice * qty;
}

/// Keranjang pesanan (dipantau oleh tampilan lewat ListenableBuilder)
class CartController extends ChangeNotifier {
  final List<CartLine> lines = [];

  bool get isEmpty => lines.isEmpty;
  int get count => lines.fold<int>(0, (a, l) => a + l.qty);
  double get total => lines.fold<double>(0, (a, l) => a + l.subtotal);

  int qtyOf(int menuId) =>
      lines.where((l) => l.id == menuId).fold<int>(0, (a, l) => a + l.qty);

  void add(Map<String, dynamic> item, int qty, {String note = ''}) {
    final id = (item['id'] as num).toInt();
    final i = lines.indexWhere((l) => l.id == id && l.note == note);
    if (i >= 0) {
      lines[i].qty += qty;
    } else {
      lines.add(CartLine(item: item, qty: qty, note: note));
    }
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }
}