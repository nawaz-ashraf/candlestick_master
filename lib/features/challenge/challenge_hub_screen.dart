import 'package:candlestick_master/features/challenge/challenge_library_screen.dart';
import 'package:candlestick_master/features/challenge/daily_challenge_screen.dart';
import 'package:flutter/material.dart';

class ChallengeHubScreen extends StatelessWidget {
  const ChallengeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Arena'),
          automaticallyImplyLeading: false,
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
