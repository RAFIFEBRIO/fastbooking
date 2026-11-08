import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_page.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String? devOtp;
  final Future<Map<String, dynamic>> Function()? onResend;
  const OtpPage({super.key, required this.phone, this.devOtp, this.onResend});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  String? _devOtp;
  int _seconds = 45;
  Timer? _timer;
  bool _loading = false;
  String? _error;

  String get _code => _input.text;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _startTimer();
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      if (_devOtp != null) showOtpBanner(context, _devOtp!);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_seconds > 0) _seconds--;
      });
      if (_seconds == 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      setState(() => _error = 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.verifyOtp(widget.phone, _code);
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

  Future<void> _doResend() async {
    try {
      final data = await widget.onResend!();
      if (!mounted) return;
      setState(() {
        _devOtp = data['otp_dev']?.toString();
        _input.clear();
        _error = null;
        _startTimer();
      });
      _focus.requestFocus();
      if (_devOtp != null) showOtpBanner(context, _devOtp!);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Widget _resendInfo() {
    if (_seconds > 0) {
      final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
      final ss = (_seconds % 60).toString().padLeft(2, '0');
      return Text.rich(
        TextSpan(
          text: 'Kirim ulang kode dalam ',
          style: const TextStyle(color: AppColors.textMuted),
          children: [
            TextSpan(
              text: '$mm:$ss',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brownDark),
            ),
          ],
        ),
      );
    }
    if (widget.onResend == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _doResend,
      child: const Text('Kirim ulang kode',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brown)),
    );
  }

  Widget _otpBoxes() {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Row(
            children: List.generate(6, (i) {
              final active = _focus.hasFocus && i == _code.length && _code.length < 6;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.creamSoft : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active ? AppColors.brownDark : AppColors.border,
                      width: active ? 1.6 : 1,
                    ),
                  ),
                  child: Text(
                    i < _code.length ? _code[i] : '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }),
          ),
          // Kolom input tak terlihat: menerima ketikan dan memunculkan keyboard angka
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _input,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                maxLength: 6,
                showCursor: false,
                enableInteractiveSelection: false,
                autocorrect: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _verify(),
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              ),
            ),
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
        child: PageWidth(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  padding: const EdgeInsets.all(18),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.cream,
                        child: Icon(Icons.sms_outlined, size: 40, color: AppColors.brown),
                      ),
                      const SizedBox(height: 20),
                      Text('Verifikasi Nomor', style: heading(32)),
                      const SizedBox(height: 10),
                      const Text(
                        'Masukkan 6 digit kode yang kami kirim lewat SMS',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'ke ',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                          children: [
                            TextSpan(
                              text: formatPhone(widget.phone),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, color: AppColors.brownDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text('Ubah nomor',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brown)),
                      ),
                      const SizedBox(height: 28),
                      _otpBoxes(),
                      const SizedBox(height: 16),
                      _resendInfo(),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.red)),
                        ),
                      const SizedBox(height: 28),
                      PrimaryButton(label: 'Verifikasi', loading: _loading, onPressed: _verify),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}