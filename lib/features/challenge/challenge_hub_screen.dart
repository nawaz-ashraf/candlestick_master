import 'package:candlestick_master/features/challenge/challenge_library_screen.dart';
import 'package:candlestick_master/features/challenge/daily_challenge_screen.dart';
import 'package:flutter/material.dart';

class ChallengeHubScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;

  const ChallengeHubScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Arena'),
          automaticallyImplyLeading: false,
          leading: onOpenDrawer != null
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: "Open Navigation Menu",
                  onPressed: onOpenDrawer,
                )
              : null,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'Daily'),
              Tab(icon: Icon(Icons.grid_view_rounded), text: 'Practice'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DailyChallengeScreen(showAppBar: false),
            ChallengeLibraryScreen(),
          ],
        ),
      ),
    );
  }
}
