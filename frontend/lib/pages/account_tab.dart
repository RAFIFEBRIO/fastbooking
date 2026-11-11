import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'history_page.dart';
import 'register_page.dart';
import 'support_page.dart';

class AccountTab extends StatelessWidget {
  final bool active;
  const AccountTab({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user ?? const <String, dynamic>{};
    final name = '${user['full_name'] ?? ''}'.trim();
    final phone = '${user['phone'] ?? ''}';
    final email = '${user['email'] ?? ''}'.trim();
    final address = '${user['address'] ?? ''}'.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              Center(child: Text('Akun', style: heading(32))),
              const SizedBox(height: 22),

              // Avatar dan nama
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.brown,
                          shape: BoxShape.circle,
                        ),
                        child: Text(initial,
                            style: heading(40, color: Colors.white)),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => showComingSoon(context, 'Ubah foto profil'),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.photo_camera_outlined,
                                size: 18, color: AppColors.brownDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(phone.isEmpty ? '' : formatPhone(phone),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              const Text('DATA DIRI',
                  style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Nama lengkap',
                      value: name,
                      onEdit: () => _editField(context, 'Nama lengkap', name, 'name'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Nomor telepon',
                      value: phone.isEmpty ? '' : formatPhone(phone),
                      onEdit: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            content: Text(
                                'Nomor telepon dipakai untuk masuk, jadi tidak bisa diubah'))),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Email',
                      value: email,
                      placeholder: 'Belum diisi',
                      onEdit: () => _editField(context, 'Email', email, 'email'),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _InfoRow(
                      label: 'Alamat',
                      value: address,
                      placeholder: 'Belum diisi',
                      onEdit: () => _editField(context, 'Alamat', address, 'address'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _MenuCard(
                icon: Icons.history,
                title: 'Riwayat Pemesanan',
                subtitle: 'Lihat semua reservasi dan pesanan',
                highlighted: true,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const HistoryPage())),
              ),
              const SizedBox(height: 14),
              _MenuCard(
                icon: Icons.headset_mic_outlined,
                title: 'Customer Service',
                subtitle: 'Bantuan reservasi, pesanan, dan pembayaran',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SupportPage())),
              ),
              const SizedBox(height: 28),

              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: AppColors.red),
                label: const Text('Keluar',
                    style: TextStyle(
                        color: AppColors.red, fontSize: 17, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  shape: const StadiumBorder(),
                  side: BorderSide(color: AppColors.red.withAlpha(80), width: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi dengan kode OTP untuk memakai aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
      (route) => false,
    );
  }

  /// Ubah satu kolom profil lewat pop up dari bawah
  Future<void> _editField(
    BuildContext context,
    String label,
    String current,
    String field,
  ) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user ?? const <String, dynamic>{};
    final controller = TextEditingController(text: current);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (ctx) {
        String? error;
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> save() async {
              final value = controller.text.trim();
              if (field == 'name' && value.isEmpty) {
                setSheet(() => error = 'Nama wajib diisi');
                return;
              }
              if (field == 'email' &&
                  value.isNotEmpty &&
                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                setSheet(() => error = 'Format email tidak valid');
                return;
              }
              setSheet(() {
                saving = true;
                error = null;
              });
              try {
                final updated = await ApiService.updateProfile(
                  fullName: field == 'name' ? value : '${user['full_name'] ?? ''}',
                  email: field == 'email' ? value : '${user['email'] ?? ''}',
                  address: field == 'address' ? value : '${user['address'] ?? ''}',
                );
                await auth.updateUser(updated);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } on ApiException catch (e) {
                setSheet(() {
                  error = e.message;
                  saving = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ubah $label', style: heading(24)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: field == 'address' ? 3 : 1,
                      keyboardType:
                          field == 'email' ? TextInputType.emailAddress : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: label,
                        filled: true,
                        fillColor: AppColors.creamSoft,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.brown),
                        ),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(error!, style: const TextStyle(color: AppColors.red)),
                      ),
                    const SizedBox(height: 18),
                    PrimaryButton(label: 'Simpan', loading: saving, onPressed: save),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onEdit;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.placeholder = '-',
  });

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  empty ? placeholder : value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: empty ? AppColors.textMuted : AppColors.brownDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 22, color: AppColors.brownDark),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.creamSoft : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.brown : AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon,
                    size: 26, color: highlighted ? Colors.white : AppColors.brownDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.brownDark),
            ],
          ),
        ),
      ),
    );
  }
}