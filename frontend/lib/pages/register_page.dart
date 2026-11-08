import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_page.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _agree = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final phone = toPhone62(_phone.text);
    if (name.isEmpty) {
      setState(() => _error = 'Nama wajib diisi');
      return;
    }
    if (phone == null) {
      setState(() => _error = 'Nomor telepon tidak valid');
      return;
    }
    if (!_agree) {
      setState(() => _error = 'Setujui Syarat & Ketentuan dan Kebijakan Privasi dulu');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.register(name, phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpPage(
          phone: phone,
          devOtp: data['otp_dev']?.toString(),
          onResend: () => ApiService.register(name, phone),
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
    const bold = TextStyle(fontWeight: FontWeight.w800, color: AppColors.brown);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageWidth(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      else
                        const SizedBox(height: 48),
                      const SizedBox(height: 8),
                      Text('Buat Akun', style: heading(36)),
                      const SizedBox(height: 8),
                      const Text(
                        'Daftar dengan nama dan nomor telepon Anda untuk mulai reservasi.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 26),
                      const FieldLabel('Nama lengkap'),
                      AppField(
                        controller: _name,
                        hint: 'Masukkan nama Anda',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 18),
                      const FieldLabel('Nomor telepon'),
                      PhoneField(controller: _phone),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _agree = !_agree),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _agree ? AppColors.brown : Colors.white,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                    color: _agree ? AppColors.brown : AppColors.border, width: 1.5),
                              ),
                              child: _agree
                                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Saya setuju dengan ',
                                style: TextStyle(fontSize: 15, height: 1.4),
                                children: [
                                  TextSpan(text: 'Syarat & Ketentuan', style: bold),
                                  TextSpan(text: ' dan '),
                                  TextSpan(text: 'Kebijakan Privasi', style: bold),
                                  TextSpan(text: ' Kenneth Resto.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                        ),
                      const SizedBox(height: 22),
                      PrimaryButton(label: 'Daftar', loading: _loading, onPressed: _submit),
                      const SizedBox(height: 18),
                      const OrDivider('atau daftar dengan'),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SocialButton(
                              letter: 'G',
                              label: 'Google',
                              onPressed: () => showComingSoon(context, 'Daftar dengan Google'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SocialButton(
                              letter: 'f',
                              label: 'Facebook',
                              onPressed: () => showComingSoon(context, 'Daftar dengan Facebook'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: const Text('Masuk',
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