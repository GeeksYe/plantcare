import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'ai_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';

/// 底部导航壳：首页 / 识别 / 发现 / 我的
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), AiScreen(), DiscoverScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.softCard,
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                fontSize: 11,
                color: states.contains(WidgetState.selected)
                    ? AppColors.forest
                    : AppColors.sub,
                fontWeight: FontWeight.w600,
              )),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          height: 64,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.local_florist_outlined),
                selectedIcon: Icon(Icons.local_florist, color: AppColors.forest),
                label: '首页'),
            NavigationDestination(
                icon: Icon(Icons.center_focus_weak_outlined),
                selectedIcon: Icon(Icons.center_focus_weak, color: AppColors.forest),
                label: '识别'),
            NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore, color: AppColors.forest),
                label: '发现'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.forest),
                label: '我的'),
          ],
        ),
      ),
    );
  }
}
