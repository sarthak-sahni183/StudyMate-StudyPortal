import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/database_provider.dart';
import '../../models/user.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSession;
  
  const DashboardScreen({super.key, this.onNavigateToSession});

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's ID
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Get the DatabaseProvider to access the stream
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

    final List<String> dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      // StreamBuilder automatically listens to our Firebase document
      body: StreamBuilder<UserModel>(
        stream: dbProvider.getUserStream(uid),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          // NEW: This will print the EXACT error to your screen (e.g., Permission Denied)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No user data found."));
          }
          
          UserModel user = snapshot.data!;
          // ... rest of the code

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- TOP BAR ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.menu, color: Colors.green),
                      ),
                      Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.menu_book_rounded, color: Colors.green),
                              SizedBox(width: 6),
                              Text("Smart Study", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Text("Planner", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: PopupMenuButton(
                          icon: const Icon(Icons.person, color: Colors.green),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text("Logout"),
                              onTap: () async {
                                await Future.delayed(Duration.zero);
                                await FirebaseAuth.instance.signOut();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- WELCOME SECTION ---
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Welcome back,", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            // Dynamically loading name from UserModel
                            Text("${user.name}!", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 16),
                            const Text("Stay consistent, stay focused,\nachieve greatness! ✨", style: TextStyle(fontSize: 17, height: 1.5, color: Colors.black87)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(30)),
                          child: const Center(child: Icon(Icons.track_changes_rounded, size: 100, color: Colors.green)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- STREAK CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                              child: const Text("🔥", style: TextStyle(fontSize: 34)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Current Streak", style: TextStyle(fontSize: 18)),
                                  const SizedBox(height: 8),
                                  // Dynamically loading streak from UserModel
                                  Text("${user.streak} days", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        
                        // --- DYNAMIC TICKS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          // Generate ticks mapping the dayNames list to the user's weekActivity list
                          children: List.generate(7, (index) {
                            // Adding a safety check in case the array size mismatches
                            bool isCompleted = index < user.weekActivity.length ? user.weekActivity[index] : false;
                            return buildDayCircle(dayNames[index], isCompleted);
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- ACTION CARDS ---
                  Column(
                    children: [
                      buildActionCard(
                        title: "Start a Session",
                        subtitle: "Focus, study and get things done.",
                        color: Colors.green.shade50,
                        icon: Icons.timer_outlined,
                        buttonColor: Colors.green,
                        onTap: () => onNavigateToSession?.call(),
                      ),
                      const SizedBox(height: 16),
                      buildActionCard(
                        title: "See Analytics",
                        subtitle: "Track your progress and improve every day.",
                        color: Colors.blue.shade50,
                        icon: Icons.bar_chart_rounded,
                        buttonColor: Colors.blue,
                        onTap: () {
                           // Navigate to analytics in the future
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- TODAY OVERVIEW ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: const [
                            Icon(Icons.access_time_filled, color: Colors.green),
                            SizedBox(height: 12),
                            Text("Today's Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [    
                            // Dynamically loading stats from UserModel
                            buildOverviewCard(
                              title: "${user.totalStudyTime} min", 
                              subtitle: "Total Study Time", 
                              color: Colors.green.shade50, 
                              icon: Icons.watch_later
                            ),
                            const SizedBox(height: 12),
                            buildOverviewCard(
                              title: "${user.totalSessions}", 
                              subtitle: "Total Sessions", 
                              color: Colors.orange.shade50, 
                              icon: Icons.menu_book
                            ),
                            const SizedBox(height: 12),
                            buildOverviewCard(
                              title: "${user.avgProductivity}/10", 
                              subtitle: "Avg. Productivity", 
                              color: Colors.purple.shade50, 
                              icon: Icons.analytics
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // --- Helper Widgets ---
  
  Widget buildDayCircle(String day, bool completed) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: completed ? Colors.green : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(completed ? Icons.check : Icons.circle_outlined, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(day),
      ],
    );
  }

  Widget buildActionCard({required String title, required String subtitle, required Color color, required IconData icon, required Color buttonColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 90, color: buttonColor),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),
            CircleAvatar(radius: 26, backgroundColor: buttonColor, child: const Icon(Icons.arrow_forward, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget buildOverviewCard({required String title, required String subtitle, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}