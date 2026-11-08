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