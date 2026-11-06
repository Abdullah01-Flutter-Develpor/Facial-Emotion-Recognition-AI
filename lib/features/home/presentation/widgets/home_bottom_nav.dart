import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      height: 72,
      backgroundColor: const Color(0xff111C2E),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      indicatorColor: const Color(0xff2563EB).withValues(alpha: .18),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.home_rounded, color: Color(0xff60A5FA)),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.history_rounded, color: Color(0xff60A5FA)),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined, color: Colors.white54),
          selectedIcon: Icon(Icons.insights_rounded, color: Color(0xff60A5FA)),
          label: 'Insights',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded, color: Colors.white54),
          selectedIcon: Icon(
            Icons.person_rounded,
            color: Color(0xff60A5FA),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}