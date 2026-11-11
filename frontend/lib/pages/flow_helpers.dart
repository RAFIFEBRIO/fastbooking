import 'package:flutter/material.dart';

String methodLabel(String key) {
  switch (key) {
    case 'transfer':
      return 'Transfer';
    case 'ovo':
      return 'OVO';
    case 'gopay':
      return 'GoPay';
    default:
      return 'QRIS';
  }
}

/// Kembali ke halaman paling awal (Beranda)
void goHome(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
}

Future<void> showExpiredAndGoHome(
  BuildContext context, {
  String message = 'Reservasi dibatalkan. Silakan pilih meja dan reservasi ulang.',
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Waktu pembayaran habis'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  if (context.mounted) goHome(context);
}