import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSession;
  const DashboardScreen({super.key, this.onNavigateToSession});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "";
  int streak = 0;
  bool isLoading = true;
  int totalStudyTime = 0;
  int totalSessions = 0;
  String avgProductivity = "0";
  
  // DYNAMIC STREAK TRACKER: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  // Defaulting all to false until Firebase loads
  List<bool> weekActivity = [false, false, false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final data = await FirestoreService().getDashboardData(uid);
      setState(() {
        userName = data['name'] ?? "Student";
        streak = data['streak'] ?? 0;
        totalStudyTime = data['totalStudyTime'] ?? 0;
        totalSessions = data['totalSessions'] ?? 0;
        avgProductivity = data['avgProductivity']?.toString() ?? "0";
        
        // Fetch the list from Firebase, or default to empty if not set yet
        weekActivity = List<bool>.from(
          data['weekActivity'] ?? [false, false, false, false, false, false, false]
        );
        
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Array of day names to match our boolean list
    final List<String> dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      body: SafeArea(
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
                        isLoading
                            ? const CircularProgressIndicator(color: Colors.green)
                            : Text("$userName!", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
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
                          // child: const Text("🔥", style: TextStyle(fontSize: 34)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Current Streak", style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              isLoading
                                  ? const CircularProgressIndicator(color: Colors.orange)
                                  : Text("$streak days", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                        // const Expanded(
                        //   child: Text("You're on fire! 🔥\nKeep it up and don't break the chain.", style: TextStyle(fontSize: 15, height: 1.5)),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // --- DYNAMIC TICKS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // We generate the 7 widgets dynamically based on our lists!
                      children: List.generate(7, (index) {
                        return buildDayCircle(dayNames[index], weekActivity[index]);
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
                    onTap: () => widget.onNavigateToSession?.call(),
                  ),
                  const SizedBox(height: 16),
                  buildActionCard(
                    title: "See Analytics",
                    subtitle: "Track your progress and improve every day.",
                    color: Colors.blue.shade50,
                    icon: Icons.bar_chart_rounded,
                    buttonColor: Colors.blue,
                    onTap: () {},
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
                        buildOverviewCard(title: "$totalStudyTime min", subtitle: "Total Study Time", color: Colors.green.shade50, icon: Icons.watch_later),
                        const SizedBox(height: 12),
                        buildOverviewCard(title: "$totalSessions", subtitle: "Total Sessions", color: Colors.orange.shade50, icon: Icons.menu_book),
                        const SizedBox(height: 12),
                        buildOverviewCard(title: "$avgProductivity/10", subtitle: "Avg. Productivity", color: Colors.purple.shade50, icon: Icons.analytics),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
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