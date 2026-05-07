// lib/screens/analytics_screen.dart

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
                const Text("Weekly Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBarChart(user),
                const SizedBox(height: 30),
                const Text("Subject Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                StreamBuilder<List<StudySession>>(
                  stream: dbProvider.getSessionsStream(uid),
                  builder: (context, sessionSnapshot) {
                    if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.green)));
                    }
                    if (!sessionSnapshot.hasData || sessionSnapshot.data!.isEmpty) {
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
                    return _buildSubjectPieChart(sessionSnapshot.data!);
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
  Widget _buildBarChart(UserModel user) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10, // You can make this dynamic based on max study hours
          barTouchData: BarTouchData(enabled: false),
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
                  return SideTitleWidget(meta: meta, space: 4, child: Text(text, style: style));
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            // Placeholder: currently using weekActivity booleans to show bars of height 5 if active
            bool isActive = index < user.weekActivity.length ? user.weekActivity[index] : false;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: isActive ? 5 : 1, // Change this to actual study hours per day if you track it
                  color: isActive ? Colors.green : Colors.grey.shade300,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

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
          radius: 48,
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

  int _calculateSessionMinutes(StudySession session) {
    if (session.endTime != null) {
      final duration = session.endTime!.toDate().difference(session.startTime.toDate()).inMinutes;
      if (duration > 0) {
        return duration;
      }
    }
    return session.plannedDuration;
  }
}
