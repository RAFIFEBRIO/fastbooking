import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_page.dart';
import 'register_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;

  late final Animation<double> _hello;
  late final Animation<double> _selamat;
  late final Animation<double> _di;
  late final Animation<double> _kenneth;

  int _stage = 0; // 0 = logo, 1 = sambutan

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    Animation<double> line(double from, double to) => CurvedAnimation(
          parent: _textCtrl,
          curve: Interval(from, to, curve: Curves.easeInOut),
        );

    _hello = line(0.00, 0.20);
    _selamat = line(0.20, 0.52);
    _di = line(0.52, 0.62);
    _kenneth = line(0.62, 0.94);

    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    final loading = auth.load();

    await _logoCtrl.forward();
    if (!mounted) return;
    setState(() => _stage = 1);

    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await loading;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) =>
            auth.isLoggedIn ? const HomePage() : const RegisterPage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoCtrl,
      builder: (context, child) {
        final t = _logoCtrl.value;
        // Muncul: 0 - 0.45, tahan, lalu memudar: 0.85 - 1.0
        final fadeIn = Curves.easeOut.transform((t / 0.45).clamp(0.0, 1.0));
        final fadeOut = 1 - ((t - 0.85) / 0.15).clamp(0.0, 1.0);
        final scale = 0.8 + 0.2 * Curves.easeOutBack.transform((t / 0.55).clamp(0.0, 1.0));
        return Opacity(
          opacity: fadeIn * fadeOut,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: const AppLogo(width: 260),
    );
  }

  Widget _buildWelcome() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WriteOn(animation: _hello, child: Text('hello', style: script(40))),
        _WriteOn(animation: _selamat, child: Text('Selamat datang', style: script(50))),
        _WriteOn(animation: _di, child: Text('di', style: script(40))),
        _WriteOn(animation: _kenneth, child: Text('Kenneth Resto', style: script(50))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _stage == 0 ? _buildLogo() : _buildWelcome(),
      ),
    );
  }
}

/// Efek "ditulis": teks terungkap dari kiri ke kanan dengan tepi yang lembut.
class _WriteOn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _WriteOn({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, c) {
        final t = animation.value;
        if (t <= 0) return Opacity(opacity: 0, child: c);
        final a = (t * 1.25 - 0.25).clamp(0.0, 1.0);
        final b = (t * 1.25).clamp(0.0, 1.0);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, a, b],
          ).createShader(rect),
          child: c,
        );
      },
    );
  }
}