import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/database_provider.dart';
import '../../models/user.dart';
import '../../models/goal.dart';
import 'add_goal_screen.dart'; // Make sure this file exists!

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSession;
  
  const DashboardScreen({super.key, this.onNavigateToSession});

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's ID
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Get the DatabaseProvider to access the streams
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

    final List<String> dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      // StreamBuilder automatically listens to our Firebase User document
      body: StreamBuilder<UserModel>(
        stream: dbProvider.getUserStream(uid),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, color: Colors.green),
                              SizedBox(width: 6),
                              Text("Study Mate", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.person, color: Colors.green),
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
                          children: List.generate(7, (index) {
                            bool isCompleted = index < user.weekActivity.length ? user.weekActivity[index] : false;
                            return buildDayCircle(dayNames[index], isCompleted);
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- UPCOMING GOALS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Upcoming Goals",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to the Add Goal screen
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddGoalScreen()));
                        },
                        child: const Text("+ Add New", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Secondary StreamBuilder just for the Goals collection
                  StreamBuilder<List<GoalModel>>(
                    stream: dbProvider.getGoalsStream(uid),
                    builder: (context, goalSnapshot) {
                      if (goalSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: Colors.green)));
                      }

                      if (!goalSnapshot.hasData || goalSnapshot.data!.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Column(
                            children: [
                              Icon(Icons.flag_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("No upcoming goals yet.", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      // Map the Firebase Goal models into UI Cards
                      // Map the Firebase Goal models into UI Cards
                      return Column(
                        children: goalSnapshot.data!.map((goal) => buildGoalCard(
                          goalId: goal.id,        // <-- NEW
                          goal: goal.title, 
                          description: goal.description, 
                          date: goal.deadline,
                          db: dbProvider,         // <-- NEW
                          uid: uid,               // <-- NEW
                        )).toList(),
                      );
                    }
                  ),
                  const SizedBox(height: 30),

                  // --- ACTION CARDS (Remaining) ---
                  // --- TODAY OVERVIEW ---
                  Container(
                    width: double.infinity,
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
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 12,
                          runSpacing: 12,
                          children: [    
                            buildOverviewCard(
                              title: "${user.totalStudyTime} min", 
                              subtitle: "Total Study Time", 
                              color: Colors.green.shade50, 
                              icon: Icons.watch_later
                            ),
                            buildOverviewCard(
                              title: "${user.totalSessions}", 
                              subtitle: "Total Sessions", 
                              color: Colors.orange.shade50, 
                              icon: Icons.menu_book
                            ),
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

  // Parses the date and calculates days left automatically
  // Parses the date and calculates days left automatically
  Widget buildGoalCard({
    required String goalId,
    required String goal, 
    required String description, 
    required DateTime date,
    required DatabaseProvider db,
    required String uid,
  }) {
    // Calculate how many days are left from today
    final int daysLeft = date.difference(DateTime.now()).inDays;
    
    // Dynamic text and color based on urgency
    String timeLeftText = daysLeft < 0 ? "Overdue" : daysLeft == 0 ? "Due Today" : "$daysLeft days left";
    Color urgencyColor = daysLeft < 0 ? Colors.red : daysLeft <= 3 ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // THE NEW CHECKMARK BUTTON
          InkWell(
            onTap: () async {
              // Trigger the completion! The stream will auto-refresh and hide this card.
              await db.completeGoal(uid: uid, goalId: goalId);
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: urgencyColor, width: 2),
              ),
              child: Icon(Icons.check, color: urgencyColor, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                  description, 
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${date.day}/${date.month}/${date.year}", 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  timeLeftText, 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: urgencyColor)
                ),
              ),
            ],
          ),
        ],
      ),
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