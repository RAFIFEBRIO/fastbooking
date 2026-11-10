import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'beranda_tab.dart';
import 'menu_tab.dart';

class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavData(this.icon, this.activeIcon, this.label);
}

const _navItems = [
  _NavData(Icons.home_outlined, Icons.home, 'Beranda'),
  _NavData(Icons.menu, Icons.menu, 'Menu'),
  _NavData(Icons.notifications_none, Icons.notifications, 'Notifikasi'),
  _NavData(Icons.person_outline, Icons.person, 'Akun'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Widget _placeholder(String title) => Center(
        child: Text('Halaman $title menyusul',
            style: const TextStyle(color: AppColors.textMuted)),
      );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      BerandaTab(onOpenNotifications: () => setState(() => _index = 2)),
      MenuTab(onGoHome: () => setState(() => _index = 0)),
      _placeholder('Notifikasi'),
      _placeholder('Akun'),
    ];
    final body = IndexedStack(index: _index, children: pages);

    // Desktop: menu samping di kiri
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            _SideNav(
              selected: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Android / layar sempit: menu di bawah
    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _navItems.length; i++)
                _BottomItem(
                  data: _navItems[i],
                  selected: _index == i,
                  onTap: () => setState(() => _index = i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final _NavData data;
  final bool selected;
  final VoidCallback onTap;
  const _BottomItem({required this.data, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brownDark : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? data.activeIcon : data.icon, size: 28, color: color),
              const SizedBox(height: 3),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SideNav({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.creamSoft,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Center(child: AppLogo(width: 170)),
            const SizedBox(height: 32),
            for (var i = 0; i < _navItems.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected == i ? AppColors.cream : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected == i ? _navItems[i].activeIcon : _navItems[i].icon,
                          size: 26,
                          color: selected == i ? AppColors.brown : AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _navItems[i].label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: selected == i ? FontWeight.w800 : FontWeight.w500,
                            color: selected == i ? AppColors.brownDark : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}