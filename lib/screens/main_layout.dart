import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; 
import 'study_session_screen.dart'; 

import 'analytics_screen.dart';

import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // We define the screens inside the build method so they can access the setState of _currentIndex
    final List<Widget> screens = [
      DashboardScreen(
        // This is the callback from the "Start a Session" button!
        onNavigateToSession: () {
          setState(() {
            _currentIndex = 1; // 1 is the index of the Session Tab
          });
        },
      ),
      const StudySessionScreen(), // The timer screen we built previously
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: "Session"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
    );
  }
}