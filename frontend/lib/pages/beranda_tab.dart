import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

class BerandaTab extends StatefulWidget {
  final VoidCallback? onOpenNotifications;
  const BerandaTab({super.key, this.onOpenNotifications});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const _areas = ['Semua', 'Indoor', 'Outdoor', 'VIP'];

  late Future<List<dynamic>> _paketFuture;
  late Future<List<dynamic>> _tablesFuture;
  String _area = 'Semua';

  @override
  void initState() {
    super.initState();
    _paketFuture = ApiService.getMenu(category: 'Paket');
    _loadTables();
  }

  void _loadTables() {
    _tablesFuture = ApiService.getTables(area: _area == 'Semua' ? null : _area);
  }

  Future<void> _refresh() async {
    setState(() {
      _paketFuture = ApiService.getMenu(category: 'Paket');
      _loadTables();
    });
    await Future.wait([_paketFuture, _tablesFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?['full_name'] ?? '';
    final firstName = name.toString().trim().split(' ').first;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 700;
          final hPad = wide ? 40.0 : 24.0;
          final contentW = math.min(c.maxWidth, Responsive.maxContent);
          // Bantalan samping supaya isi tetap di tengah dan tidak terlalu lebar
          final sidePad = (c.maxWidth - contentW) / 2 + hPad;
          final innerW = c.maxWidth - sidePad * 2;
          final cols = innerW >= 760 ? 2 : 1;

          // Membungkus bagian yang memakai bantalan samping (slider tidak dibungkus)
          Widget pad(Widget child) => Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: child,
              );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 28),
              children: [
                // Sapaan dan lonceng
                pad(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Halo, $firstName',
                          style: const TextStyle(
                            color: AppColors.brownDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onOpenNotifications,
                        icon: const Icon(Icons.notifications_none, size: 30),
                        color: AppColors.brownDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Slider paket: full dari tepi kiri sampai tepi kanan
                FutureBuilder<List<dynamic>>(
                  future: _paketFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return pad(_ErrorBox(message: '${snap.error}', onRetry: _refresh));
                    }
                    return PaketSlider(items: snap.data!, wide: wide);
                  },
                ),
                const SizedBox(height: 28),

                // Judul meja
                pad(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text('Meja Tersedia', style: heading(wide ? 30 : 26))),
                      const Text('Hari ini · 2 tamu',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab area
                pad(
                  Row(
                    children: _areas.map((a) {
                      final selected = a == _area;
                      return Padding(
                        padding: const EdgeInsets.only(right: 26),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _area = a;
                            _loadTables();
                          }),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: selected ? AppColors.brown : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                a,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                  color: selected ? AppColors.brownDark : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                pad(const Divider(height: 1, color: AppColors.border)),

                // Daftar meja
                FutureBuilder<List<dynamic>>(
                  future: _tablesFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return pad(_ErrorBox(message: '${snap.error}', onRetry: _refresh));
                    }
                    final tables = snap.data!;
                    if (tables.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('Belum ada meja')),
                      );
                    }

                    void book() => showComingSoon(context, 'Halaman reservasi meja');

                    // Desktop: grid 2 kolom dengan kartu berbingkai
                    if (cols == 2) {
                      const gap = 20.0;
                      final cardW = (innerW - gap) / 2;
                      return pad(
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final t in tables)
                                SizedBox(
                                  width: cardW,
                                  child: TableCard(table: t, boxed: true, onBook: book),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Layar sempit: daftar satu kolom dengan garis pemisah
                    return pad(
                      Column(
                        children: [
                          for (var i = 0; i < tables.length; i++) ...[
                            TableCard(table: tables[i], onBook: book),
                            if (i < tables.length - 1)
                              const Divider(height: 1, color: AppColors.border),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PaketSlider extends StatefulWidget {
  final List<dynamic> items;
  final bool wide;
  const PaketSlider({super.key, required this.items, this.wide = false});

  @override
  State<PaketSlider> createState() => _PaketSliderState();
}

class _PaketSliderState extends State<PaketSlider> {
  // Rasio gambar paket (1264 x 842)
  static const _ratio = 1264 / 842;
  // Lebar banner utama di desktop
  static const _desktopItemWidth = 760.0;

  PageController _controller = PageController();
  double _fraction = 1.0;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || widget.items.length < 2) return;
      _goTo((_index + 1) % widget.items.length, restart: false);
    });
  }

  void _goTo(int i, {bool restart = true}) {
    final n = widget.items.length;
    final target = (i + n) % n;
    if (_controller.hasClients) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
    if (restart) _startTimer();
  }

  // Ukuran tampilan berubah (misalnya jendela ditarik): buat ulang controller
  void _syncController(double fraction) {
    if ((fraction - _fraction).abs() < 0.001) return;
    final old = _controller;
    _fraction = fraction;
    _controller = PageController(viewportFraction: fraction, initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withAlpha(225),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 24, color: AppColors.brownDark),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final wide = widget.wide;

    return LayoutBuilder(
      builder: (context, c) {
        final areaW = c.maxWidth;
        final fraction = wide ? (_desktopItemWidth / areaW).clamp(0.3, 0.92) : 1.0;
        _syncController(fraction);
        final itemH = (areaW * fraction) / _ratio;
        final radius = wide ? 20.0 : 0.0;
        final gap = wide ? 8.0 : 0.0;

        return SizedBox(
          height: itemH,
          child: Stack(
            children: [
              PageView.builder(
                key: ValueKey(fraction),
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final item = widget.items[i];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: gap),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Image.asset(
                        AppConfig.paketImage(item['image_url']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  );
                },
              ),

              // Titik penanda di dalam gambar, bagian bawah
              if (widget.items.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.items.length,
                      (i) => GestureDetector(
                        onTap: () => _goTo(i),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: i == _index ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == _index ? Colors.white : Colors.white.withAlpha(120),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(60),
                                    blurRadius: 4,
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

              // Tombol panah hanya di desktop
              if (wide && widget.items.length > 1) ...[
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _arrow(Icons.chevron_left, () => _goTo(_index - 1))),
                ),
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(child: _arrow(Icons.chevron_right, () => _goTo(_index + 1))),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class TableCard extends StatelessWidget {
  final Map<String, dynamic> table;
  final VoidCallback onBook;
  final bool boxed;
  const TableCard({
    super.key,
    required this.table,
    required this.onBook,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            AppConfig.mejaImage(table['image_url']),
            width: 108,
            height: 108,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${table['name']} · ${table['area']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.circle, size: 8, color: AppColors.green),
                  const SizedBox(width: 4),
                  const Text('Tersedia',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (table['description'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppColors.brownDark),
                  const SizedBox(width: 4),
                  Text('Kapasitas ${table['capacity']} orang',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onBook,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: AppColors.border, width: 1.4),
                  foregroundColor: AppColors.brownDark,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: const Text('Booking Meja',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ],
    );

    if (boxed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: content,
      );
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: content);
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}