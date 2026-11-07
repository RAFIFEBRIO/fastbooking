import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'home_page.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String? devOtp;
  const OtpPage({super.key, required this.phone, this.devOtp});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.verifyOtp(widget.phone, _code.text);
      if (!mounted) return;
      await context.read<AuthProvider>().setSession(
            data['token'] as String,
            Map<String, dynamic>.from(data['user'] as Map),
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
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
                children: [
                  const Icon(Icons.sms_outlined, size: 56, color: AppColors.brown),
                  const SizedBox(height: 12),
                  const Text('Verifikasi Nomor',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.brown)),
                  const SizedBox(height: 8),
                  Text('Masukkan kode 6 digit yang dikirim ke +${widget.phone}',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 28, letterSpacing: 12),
                    decoration: const InputDecoration(counterText: '', hintText: '------'),
                  ),
                  if (widget.devOtp != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Mode pengembangan, kode OTP: ${widget.devOtp}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verifikasi'),
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