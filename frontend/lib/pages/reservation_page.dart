import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/booking_draft.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'menu_page.dart';

class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> table;
  const ReservationPage({super.key, required this.table});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  static const _times = ['11:00', '12:00', '13:00', '18:00', '19:00', '20:00'];
  static const _daysCount = 14;

  late final List<DateTime> _dates;
  int _dateIndex = 0;
  String? _time;
  late int _guests;
  final _notes = TextEditingController();

  Map<String, bool> _available = {};
  bool _loadingSlots = true;
  String? _error;
  int _loadToken = 0;

  int get _capacity => (widget.table['capacity'] as num).toInt();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(
      _daysCount,
      (i) => DateTime(now.year, now.month, now.day + i),
    );
    _guests = math.min(2, _capacity);
    _loadSlots();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool _isPast(DateTime date, String time) {
    final parts = time.split(':');
    final at = DateTime(
      date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]),
    );
    return at.isBefore(DateTime.now());
  }

  Future<void> _loadSlots() async {
    final token = ++_loadToken;
    setState(() {
      _loadingSlots = true;
      _error = null;
      _time = null;
    });
    final date = _dates[_dateIndex];
    final tableId = widget.table['id'];
    try {
      final results = await Future.wait(
        _times.map((t) => ApiService.getAvailability(dateKeyOf(date), t)),
      );
      if (!mounted || token != _loadToken) return;
      final map = <String, bool>{};
      for (var i = 0; i < _times.length; i++) {
        dynamic row;
        for (final x in results[i]) {
          if (x['id'] == tableId) {
            row = x;
            break;
          }
        }
        map[_times[i]] =
            row != null && row['is_available'] == true && !_isPast(date, _times[i]);
      }
      setState(() {
        _available = map;
        _loadingSlots = false;
      });
    } on ApiException catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _error = e.message;
        _loadingSlots = false;
      });
    }
  }

  String get _monthLabel {
    final a = _dates.first;
    final b = _dates.last;
    if (a.month == b.month) return '${monthShort(a)} ${a.year}';
    if (a.year == b.year) return '${monthShort(a)} – ${monthShort(b)} ${a.year}';
    return '${monthShort(a)} ${a.year} – ${monthShort(b)} ${b.year}';
  }

  void _continue() {
    if (_time == null) return;
    final draft = BookingDraft(
      table: widget.table,
      date: _dates[_dateIndex],
      time: _time!,
      guests: _guests,
      notes: _notes.text.trim(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MenuPage(draft: draft)),
    );
  }

  Widget _dateChip(int i) {
    final d = _dates[i];
    final selected = i == _dateIndex;
    return GestureDetector(
      onTap: () {
        if (i == _dateIndex) return;
        setState(() => _dateIndex = i);
        _loadSlots();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 64,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brown : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.brown : AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayShort(d),
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.day.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.brownDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip(String t, double width) {
    final ok = !_loadingSlots && (_available[t] ?? false);
    final selected = _time == t;
    return SizedBox(
      width: width,
      height: 54,
      child: GestureDetector(
        onTap: ok ? () => setState(() => _time = t) : null,
        child: MouseRegion(
          cursor: ok ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.brown : Colors.white,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: selected ? AppColors.brown : AppColors.border),
            ),
            child: Text(
              t.replaceAll(':', '.'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (ok ? AppColors.brownDark : const Color(0xFFB9ADA2)),
                decoration: ok ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? AppColors.brownDark : const Color(0xFFC9BFB5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final date = _dates[_dateIndex];
    final summary = _time == null
        ? 'Pilih jam reservasi'
        : '${dayShort(date)}, ${date.day} ${monthShort(date)} · ${_time!.replaceAll(':', '.')} · $_guests tamu';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Judul
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text('Reservasi Meja',
                            textAlign: TextAlign.center, style: heading(24)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info meja
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                AppConfig.mejaImage(table['image_url']),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${table['name']} · ${table['area']}',
                                      style: heading(22)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (table['description'] ?? '').toString(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 4),
                                  const Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: AppColors.green),
                                      SizedBox(width: 5),
                                      Text('Tersedia',
                                          style: TextStyle(
                                              color: AppColors.green,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1, color: AppColors.border),
                        ),

                        // Tanggal
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('Tanggal', style: heading(22)),
                            const SizedBox(width: 10),
                            Text(_monthLabel,
                                style: const TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 82,
                          child: ScrollConfiguration(
                            // Agar bisa digeser pakai mouse di desktop
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _dates.length,
                              itemBuilder: (_, i) => _dateChip(i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Jam
                        Text('Jam', style: heading(22)),
                        const SizedBox(height: 14),
                        if (_loadingSlots)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: AppColors.brown,
                              backgroundColor: AppColors.border,
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(color: AppColors.red)),
                                ),
                                TextButton(
                                    onPressed: _loadSlots, child: const Text('Coba lagi')),
                              ],
                            ),
                          ),
                        LayoutBuilder(
                          builder: (context, c) {
                            const gap = 12.0;
                            final w = (c.maxWidth - gap * 2) / 3;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [for (final t in _times) _timeChip(t, w)],
                            );
                          },
                        ),
                        const SizedBox(height: 26),

                        // Jumlah tamu
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jumlah tamu', style: heading(22)),
                                  const SizedBox(height: 2),
                                  Text('Maksimal $_capacity orang untuk meja ini',
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 13)),
                                ],
                              ),
                            ),
                            _stepButton(Icons.remove, _guests > 1,
                                () => setState(() => _guests--)),
                            SizedBox(
                              width: 44,
                              child: Text('$_guests',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w800)),
                            ),
                            _stepButton(Icons.add, _guests < _capacity,
                                () => setState(() => _guests++)),
                          ],
                        ),
                        const SizedBox(height: 26),

                        // Catatan
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('Catatan', style: heading(22)),
                            const SizedBox(width: 10),
                            const Text('Opsional',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notes,
                          maxLines: 3,
                          minLines: 2,
                          maxLength: 200,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Contoh: alergi kacang, rayakan ulang tahun',
                            hintStyle: const TextStyle(color: Color(0xFF9C8F84)),
                            contentPadding: const EdgeInsets.all(18),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.brown),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ringkasan dan tombol
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(summary,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 14)),
                          ),
                          Text('${table['name']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Lanjutkan',
                        onPressed: _time == null ? null : _continue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}