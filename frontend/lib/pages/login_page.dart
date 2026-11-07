import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.length < 9) {
      setState(() => _error = 'Nomor telepon tidak valid');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = '62$digits';
      final data = await ApiService.login(phone);
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
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Icon(Icons.restaurant, size: 56, color: AppColors.brown)),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Kenneth Resto',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brown)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Masuk',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.brown)),
                  const SizedBox(height: 6),
                  const Text('Masukkan nomor telepon, kode OTP akan dikirim.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  const Text('Nomor telepon'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(prefixText: '+62  ', hintText: '812 3456 7890'),
                  ),
                  const SizedBox(height: 12),
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
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text('Daftar',
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