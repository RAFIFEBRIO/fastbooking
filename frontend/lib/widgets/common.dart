import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Membatasi lebar halaman (supaya rapi di Chrome) dan menengahkannya.
class PageWidth extends StatelessWidget {
  final Widget child;
  const PageWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: child,
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double width;
  const AppLogo({super.key, this.width = 240});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo/logo.png',
      width: width,
      errorBuilder: (_, __, ___) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant, size: 64, color: AppColors.brown),
          const SizedBox(height: 8),
          Text('fastbooking', style: heading(28, color: AppColors.brown)),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.brown.withAlpha(70),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brown,
          disabledBackgroundColor: AppColors.brown.withAlpha(140),
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String letter;
  final String label;
  final VoidCallback onPressed;
  const SocialButton({
    super.key,
    required this.letter,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.brownDark,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.cream,
            child: Text(letter,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brown)),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.brown)),
    );
  }
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final Widget? prefix;
  final TextInputType? keyboardType;
  const AppField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.prefix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.brownDark),
            const SizedBox(width: 12),
          ],
          if (prefix != null) prefix!,
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9C8F84)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 19),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const PhoneField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppField(
      controller: controller,
      hint: '812 3456 7890',
      keyboardType: TextInputType.phone,
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('+62', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(width: 12),
          Container(width: 1, height: 26, color: AppColors.border),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// Ubah input pengguna (0812..., 812..., 62812...) menjadi 62812...
String? toPhone62(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  d = d.replaceFirst(RegExp(r'^(62|0)+'), '');
  if (d.length < 9 || d.length > 13) return null;
  return '62$d';
}

/// 6281234567890 menjadi +62 812 3456 7890
String formatPhone(String p) {
  final l = p.startsWith('62') ? p.substring(2) : p;
  if (l.length <= 3) return '+62 $l';
  final a = l.substring(0, 3);
  final rest = l.substring(3);
  if (rest.length <= 4) return '+62 $a $rest';
  return '+62 $a ${rest.substring(0, 4)} ${rest.substring(4)}';
}

void showComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$what belum tersedia')),
  );
}
/// Menampilkan pesan mengambang di atas layar (simulasi notifikasi SMS)
void showOtpBanner(BuildContext context, String code) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _OtpBanner(
      code: code,
      onClose: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _OtpBanner extends StatefulWidget {
  final String code;
  final VoidCallback onClose;
  const _OtpBanner({required this.code, required this.onClose});

  @override
  State<_OtpBanner> createState() => _OtpBannerState();
}

class _OtpBannerState extends State<_OtpBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _slide = Tween<Offset>(begin: const Offset(0, -1.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    // Muncul setelah jeda singkat, seperti SMS yang baru masuk
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _ctrl.forward();
      _timer = Timer(const Duration(seconds: 7), _close);
    });
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _ctrl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: _close,
                      onVerticalDragEnd: (d) {
                        if ((d.primaryVelocity ?? 0) < 0) _close();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(45),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.brown,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.sms, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'PESAN',
                                          style: TextStyle(
                                            fontSize: 11,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      Text('sekarang',
                                          style: TextStyle(
                                              fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Kenneth Resto',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.brownDark)),
                                  const SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      text: 'Kode verifikasi FastBooking Anda: ',
                                      style: const TextStyle(
                                          fontSize: 14, color: AppColors.brownDark),
                                      children: [
                                        TextSpan(
                                          text: widget.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2,
                                            color: AppColors.brown,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '. Jangan bagikan kode ini kepada siapa pun.',
                                        ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
