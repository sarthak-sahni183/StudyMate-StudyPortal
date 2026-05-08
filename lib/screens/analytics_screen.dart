import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/database_provider.dart';
import '../models/user.dart';
import '../models/study_session.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      appBar: AppBar(
        title: const Text("Analytics", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<UserModel>(
        stream: dbProvider.getUserStream(uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!userSnapshot.hasData) {
            return const Center(child: Text("No analytics data available."));
          }

          UserModel user = userSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(user),
                const SizedBox(height: 30),
                
                // We wrap both charts in the Sessions Stream so they use REAL data!
                StreamBuilder<List<StudySession>>(
                  stream: dbProvider.getSessionsStream(uid),
                  builder: (context, sessionSnapshot) {
                    if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.green)));
                    }
                    
                    final sessions = sessionSnapshot.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Weekly Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildBarChart(sessions), // Now passes REAL sessions!
                        
                        const SizedBox(height: 30),
                        const Text("Subject Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        if (sessions.isEmpty)
                          Container(
                            height: 250,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                            ),
                            child: const Center(
                              child: Text(
                                "No subject breakdown available yet.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          _buildSubjectPieChart(sessions),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Summary Cards ---
  Widget _buildSummaryCards(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard("Total Time", "${user.totalStudyTime}m", Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard("Avg Prod.", "${user.avgProductivity}", Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  // --- Bar Chart: Weekly Activity ---
  Widget _buildBarChart(List<StudySession> sessions) {
    // 1. Calculate minutes per day for the CURRENT week
    List<double> weekMinutes = List.filled(7, 0.0);
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    for (var session in sessions) {
      if (!session.isCompleted) continue;
      DateTime sessionDate = session.startTime.toDate();
      
      // Check if session is from this current week
      if (sessionDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        int weekdayIndex = sessionDate.weekday - 1; // 0 = Mon, 6 = Sun
        weekMinutes[weekdayIndex] += _calculateSessionMinutes(session).toDouble();
      }
    }

    // 2. Determine the Max Y axis automatically
    double maxMinutes = weekMinutes.reduce((a, b) => a > b ? a : b);
    double maxY = maxMinutes > 0 ? maxMinutes * 1.2 : 60.0; // Give headroom, default to 60m

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 30, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY, // Dynamically scales to your longest study day
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} min',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                  String text;
                  switch (value.toInt()) {
                    case 0: text = 'M'; break;
                    case 1: text = 'T'; break;
                    case 2: text = 'W'; break;
                    case 3: text = 'T'; break;
                    case 4: text = 'F'; break;
                    case 5: text = 'S'; break;
                    case 6: text = 'S'; break;
                    default: text = ''; break;
                  }
                  return SideTitleWidget(meta: meta, space: 8, child: Text(text, style: style));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()}m", style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              )
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            double minutes = weekMinutes[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: minutes, 
                  color: minutes > 0 ? Colors.green : Colors.grey.shade300,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.shade100, // Light background track for the bar
                  )
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- Pie Chart: Subject Breakdown ---
  Widget _buildSubjectPieChart(List<StudySession> sessions) {
    final subjectHours = _aggregateSubjectHours(sessions);
    final List<Color> sectionColors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    final sortedSubjects = subjectHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedSubjects.isEmpty) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: const Center(
          child: Text(
            "No subject breakdown available yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < sortedSubjects.length && i < sectionColors.length; i++) {
      final subject = sortedSubjects[i];
      sections.add(
        PieChartSectionData(
          color: sectionColors[i],
          value: subject.value,
          title: '${subject.key}\n${subject.value.toStringAsFixed(1)}h',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
        ),
      ),
    );
  }

  // --- Aggregation Logic ---
  Map<String, double> _aggregateSubjectHours(List<StudySession> sessions) {
    final Map<String, double> subjectHours = {};

    for (final session in sessions) {
      if (!session.isCompleted) continue;
      final minutes = _calculateSessionMinutes(session);
      if (minutes <= 0) continue;

      final hours = minutes / 60.0;
      subjectHours[session.subjectName] = (subjectHours[session.subjectName] ?? 0) + hours;
    }

    return subjectHours;
  }

  // THE FIX: Accurate Time Calculation!
  int _calculateSessionMinutes(StudySession session) {
    // 1. If actualDuration exists, use it!
    if (session.actualDuration != null && session.actualDuration! > 0) {
      return session.actualDuration!;
    }
    
    // 2. Fallback: Calculate from start and end time manually
    if (session.endTime != null) {
      final duration = session.endTime!.toDate().difference(session.startTime.toDate()).inMinutes;
      if (duration > 0) {
        return duration;
      }
    }
    
    // 3. Absolute fallback: the planned duration
    return session.plannedDuration;
  }
}