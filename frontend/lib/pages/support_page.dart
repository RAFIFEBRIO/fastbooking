import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const _whatsapp = '+62 812 3456 7890';
  static const _email = 'cs@kennethresto.id';

  static const _faq = <(String, String)>[
    (
      'Bagaimana cara membatalkan reservasi?',
      'Reservasi yang belum dibayar akan batal otomatis setelah 15 menit. '
          'Untuk reservasi yang sudah lunas, hubungi Customer Service.'
    ),
    (
      'Kenapa saya harus memesan makanan?',
      'Setiap reservasi meja disertai pra-pesan makanan, supaya hidangan siap saat Anda tiba. '
          'Meja VIP memiliki minimal order Rp 500.000.'
    ),
    (
      'Apa itu pajak dan layanan?',
      'Setiap pesanan dikenai pajak 10% dan biaya layanan 5% dari subtotal.'
    ),
    (
      'QR di halaman pembayaran berhasil untuk apa?',
      'Tunjukkan QR itu kepada pelayan saat tiba untuk memverifikasi reservasi Anda.'
    ),
  ];

  Widget _contact(BuildContext context, IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.brownDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Salin',
            icon: const Icon(Icons.copy_rounded, color: AppColors.brown),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('$title disalin')));
            },
          ),
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
                        child: Text('Customer Service',
                            textAlign: TextAlign.center, style: heading(22)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                    children: [
                      const Text(
                        'Ada kendala dengan reservasi, pesanan, atau pembayaran? Hubungi kami.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      _contact(context, Icons.chat_outlined, 'WhatsApp', _whatsapp),
                      const SizedBox(height: 12),
                      _contact(context, Icons.mail_outline, 'Email', _email),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.creamSoft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.schedule, color: AppColors.brown),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Jam layanan: setiap hari, 10.00 - 22.00 WIB',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text('Pertanyaan Umum', style: heading(22)),
                      const SizedBox(height: 8),
                      for (final f in _faq)
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 14),
                            expandedAlignment: Alignment.centerLeft,
                            iconColor: AppColors.brown,
                            collapsedIconColor: AppColors.brownDark,
                            title: Text(f.$1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            children: [
                              Text(f.$2,
                                  style: const TextStyle(
                                      color: AppColors.textMuted, height: 1.45)),
                            ],
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
    );
  }
}