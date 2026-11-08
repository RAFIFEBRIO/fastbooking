import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = toPhone62(_phone.text);
    if (phone == null) {
      setState(() => _error = 'Nomor telepon tidak valid');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.login(phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpPage(
          phone: phone,
          devOtp: data['otp_dev']?.toString(),
          onResend: () => ApiService.login(phone),
        ),
      ));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageWidth(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
                        decoration: const BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(14),
                            bottomLeft: Radius.circular(44),
                            bottomRight: Radius.circular(44),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 112,
                              height: 112,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset('assets/images/menu/steak.jpg',
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Kenneth Resto', style: heading(32)),
                            const SizedBox(height: 6),
                            const Text(
                              'Reservasi meja dan pesan makanan tanpa antre',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Masuk', style: heading(36)),
                            const SizedBox(height: 8),
                            const Text(
                              'Masukkan nomor telepon Anda, kami kirim kode verifikasi lewat SMS.',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 16, height: 1.4),
                            ),
                            const SizedBox(height: 22),
                            const FieldLabel('Nomor telepon'),
                            PhoneField(controller: _phone),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(_error!,
                                    style: const TextStyle(color: AppColors.red)),
                              ),
                            const SizedBox(height: 20),
                            PrimaryButton(label: 'Masuk', loading: _loading, onPressed: _submit),
                            const SizedBox(height: 18),
                            const OrDivider('atau masuk dengan'),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SocialButton(
                                    letter: 'G',
                                    label: 'Google',
                                    onPressed: () =>
                                        showComingSoon(context, 'Masuk dengan Google'),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: SocialButton(
                                    letter: 'f',
                                    label: 'Facebook',
                                    onPressed: () =>
                                        showComingSoon(context, 'Masuk dengan Facebook'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? ',
                        style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Daftar',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}