import 'package:intl/intl.dart';

/// Ubah angka atau teks ("28000.00") menjadi double
double toNum(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String rupiah(dynamic value) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(toNum(value));

/// 180550 menjadi "180.550"
String numberId(dynamic value) =>
    NumberFormat.decimalPattern('id_ID').format(toNum(value));

/// 899 detik menjadi "14:59"
String mmss(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}