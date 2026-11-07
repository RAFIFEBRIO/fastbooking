import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Nama wajib diisi');
      return;
    }
    if (digits.length < 9) {
      setState(() => _error = 'Nomor telepon tidak valid');
      return;
    }
    if (!_agree) {
      setState(() => _error = 'Setujui syarat dan ketentuan dulu');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = '62$digits';
      final data = await ApiService.register(_name.text.trim(), phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpPage(phone: phone, devOtp: data['otp_dev']?.toString()),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buat Akun',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.brown)),
                  const SizedBox(height: 6),
                  const Text('Daftar dengan nomor telepon Anda untuk mulai reservasi.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  const Text('Nama lengkap'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(hintText: 'Masukkan nama Anda'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nomor telepon'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(prefixText: '+62  ', hintText: '812 3456 7890'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _agree,
                    onChanged: (v) => setState(() => _agree = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Saya setuju dengan Syarat & Ketentuan dan Kebijakan Privasi',
                        style: TextStyle(fontSize: 13)),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Daftar'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? '),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: const Text('Masuk',
                            style: TextStyle(color: AppColors.brown, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}