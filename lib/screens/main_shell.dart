import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'ai_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';

/// 底部导航壳：浮动白色圆角胶囊，顺序对齐设计稿：首页 / 发现 / 识别 / 我的
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), DiscoverScreen(), AiScreen(), ProfileScreen()];

  static const _tabs = [
    (Icons.home_rounded, '首页'),
    (Icons.filter_vintage, '发现'),
    (Icons.photo_camera_outlined, '识别'),
    (Icons.person, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        IndexedStack(index: _index, children: _screens),
        Positioned(left: 24, right: 24, bottom: 14, child: _navBar()),
      ]),
    );
  }

  Widget _navBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(child: _navItem(i)),
      ]),
    );
  }

  Widget _navItem(int i) {
    final (icon, label) = _tabs[i];
    final selected = _index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _index = i),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 19, color: selected ? Colors.white : AppColors.sub),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.sub)),
        ]),
      ),
    );
  }
}
