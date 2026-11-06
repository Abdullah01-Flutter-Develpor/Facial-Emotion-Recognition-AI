import 'package:flutter/material.dart';

import 'package:demo_app/features/history/presentation/screens/history_screen.dart';
import 'package:demo_app/features/insight/presentation/screens/insight_screen.dart';
import 'package:demo_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:demo_app/features/home/presentation/widgets/ai_insight_card.dart';
import 'package:demo_app/features/home/presentation/widgets/emotion_scan_card.dart';
import 'package:demo_app/features/home/presentation/widgets/emotion_summary_card.dart';
import 'package:demo_app/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:demo_app/features/home/presentation/widgets/home_header.dart';
import 'package:demo_app/features/home/presentation/widgets/recent_analysis.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeContent(
        onHistory: () {
          setState(() => currentIndex = 1);
        },
      ),
      const HistoryScreen(),
      const InsightsScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          setState(() => currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xff0F172A),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -350 && currentIndex < screens.length - 1) {
              setState(() => currentIndex++);
            } else if (velocity > 350 && currentIndex > 0) {
              setState(() => currentIndex--);
            }
          },
          child: IndexedStack(index: currentIndex, children: screens),
        ),
        bottomNavigationBar: HomeBottomNav(
          currentIndex: currentIndex,
          onChanged: (index) {
            setState(() => currentIndex = index);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final VoidCallback onHistory;

  const _HomeContent({required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const HomeHeader(),
            const SizedBox(height: 24),
            const EmotionScanCard(),
            const SizedBox(height: 20),
            const EmotionSummaryCard(),
            const SizedBox(height: 20),

            RecentAnalysis(onViewAll: onHistory),

            const SizedBox(height: 20),
            const AiInsightCard(),
          ],
        ),
      ),
    );
  }
}
