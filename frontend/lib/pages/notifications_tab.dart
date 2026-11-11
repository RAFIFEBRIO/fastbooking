import 'package:flutter/material.dart';
import '../models/booking_draft.dart';
import '../services/api_service.dart';
import '../theme.dart';

class NotificationsTab extends StatefulWidget {
  final bool active;
  const NotificationsTab({super.key, required this.active});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _onlyUnread = false;

  int get _unread => _items.where((n) => n['is_read'] != true).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant NotificationsTab old) {
    super.didUpdateWidget(old);
    // Muat ulang setiap kali tab dibuka
    if (widget.active && !old.active) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markAll() async {
    if (_unread == 0) return;
    setState(() {
      for (final n in _items) {
        n['is_read'] = true;
      }
    });
    try {
      await ApiService.markAllNotificationsRead();
    } on ApiException {
      _load(silent: true);
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    if (n['is_read'] == true) return;
    setState(() => n['is_read'] = true);
    try {
      await ApiService.markNotificationRead((n['id'] as num).toInt());
    } on ApiException {
      // Diabaikan: status akan disinkronkan saat tab dibuka lagi
    }
  }

  DateTime _created(Map<String, dynamic> n) =>
      (DateTime.tryParse('${n['created_at']}') ?? DateTime.now()).toLocal();

  int _dayDiff(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    return today.difference(day).inDays;
  }

  String _group(DateTime d) {
    final diff = _dayDiff(d);
    if (diff <= 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return 'SEBELUMNYA';
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
    if (diff.inHours < 24 && _dayDiff(d) <= 0) return '${diff.inHours} jam';
    if (_dayDiff(d) == 1) return 'Kemarin';
    return '${d.day} ${monthShort(d)}';
  }

  IconData _icon(String title) {
    final t = title.toLowerCase();
    if (t.contains('pembayaran')) return Icons.check_circle_outline;
    if (t.contains('login')) return Icons.login;
    if (t.contains('promo')) return Icons.local_offer_outlined;
    if (t.contains('selamat')) return Icons.person_outline;
    if (t.contains('dibatalkan')) return Icons.event_busy_outlined;
    return Icons.event_available_outlined;
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(right: 26),
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.brown : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppColors.brownDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> n) {
    final unread = n['is_read'] != true;
    final title = '${n['title']}';
    final message = '${n['message'] ?? ''}';
    return InkWell(
      onTap: () => _open(n),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_icon(title), size: 26, color: AppColors.brownDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                      )),
                  const SizedBox(height: 3),
                  Text(message,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 15, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_ago(_created(n)),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 8),
                if (unread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.brown,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final shown = _onlyUnread ? _items.where((n) => n['is_read'] != true).toList() : _items;

    if (shown.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 90),
          Icon(
            _onlyUnread ? Icons.mark_email_read_outlined : Icons.notifications_none,
            size: 56,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            _onlyUnread ? 'Semua notifikasi sudah dibaca' : 'Belum ada notifikasi',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
        ],
      );
    }

    final children = <Widget>[];
    String? lastGroup;
    for (final n in shown) {
      final g = _group(_created(n));
      if (g != lastGroup) {
        lastGroup = g;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Text(
            g,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ));
      }
      children.add(_row(n));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Notifikasi', style: heading(32))),
                    GestureDetector(
                      onTap: _markAll,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Tandai dibaca',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _unread > 0 ? AppColors.brown : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _tab('Semua', !_onlyUnread, () => setState(() => _onlyUnread = false)),
                    _tab('Belum dibaca ($_unread)', _onlyUnread,
                        () => setState(() => _onlyUnread = true)),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.red)),
                                TextButton(onPressed: _load, child: const Text('Coba lagi')),
                              ],
                            ),
                          )
                        : RefreshIndicator(onRefresh: () => _load(silent: true), child: _list()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}