import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';
import '../models/subject.dart';

// Defines the 3 stages of our workflow
enum SessionState { setup, running, rating }

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  SessionState _currentState = SessionState.setup;
  
  // Setup Variables
  String? _selectedSubjectName;
  int _durationMinutes = 25;
  
  // Running Variables
  String? _activeSessionId;
  int _secondsRemaining = 0;
  Timer? _timer;

  // Rating Variables
  double _productivity = 5;

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // --- WORKFLOW METHODS ---

  void _startSession(DatabaseProvider db) async {
    if (_selectedSubjectName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a subject first.")),
      );
      return;
    }

    try {
      // 1. Push start data to backend
      _activeSessionId = await db.startSession(
        uid: uid,
        subjectName: _selectedSubjectName!,
        plannedDuration: _durationMinutes,
      );

      // 2. Start local timer & update UI
      setState(() {
        _currentState = SessionState.running;
        _secondsRemaining = _durationMinutes * 60;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _endSession(); // Auto-end when timer hits 0
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _endSession() {
    _timer?.cancel();
    setState(() {
      _currentState = SessionState.rating;
    });
  }

  void _saveRating(DatabaseProvider db) async {
    try {
      await db.finishAndRateSession(
        uid: uid,
        sessionId: _activeSessionId!,
        productivityRating: _productivity.toInt(),
        duration: _durationMinutes
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session saved successfully!")),
      );

      // Reset everything for the next session
      setState(() {
        _currentState = SessionState.setup;
        _productivity = 5;
        _activeSessionId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final dbProvider = Provider.of<DatabaseProvider>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Study Session",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            
            // Switch UI based on the current state
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentState == SessionState.setup
                    ? _buildSetupView(dbProvider)
                    : _currentState == SessionState.running
                        ? _buildRunningView()
                        : _buildRatingView(dbProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. SETUP VIEW
  Widget _buildSetupView(DatabaseProvider db) {
    return SingleChildScrollView(
      key: const ValueKey('setup'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Subject", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            
            // Real-time dropdown from Firebase
            StreamBuilder<List<Subject>>(
              stream: db.getSubjectsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Subject> subjects = snapshot.data ?? [];

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        hint: const Text("Choose a subject..."),
                        value: _selectedSubjectName,
                        items: subjects.map((sub) {
                          return DropdownMenuItem(
                            value: sub.name,
                            child: Text(sub.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSubjectName = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Button to create a new subject
                    InkWell(
                      onTap: () => _showAddSubjectDialog(db),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.green),
                      ),
                    )
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            Text("Duration: $_durationMinutes minutes", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              activeColor: Colors.green,
              onChanged: (val) {
                setState(() => _durationMinutes = val.toInt());
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _startSession(db),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Start Session", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. RUNNING VIEW
  Widget _buildRunningView() {
    String minutesStr = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    String secondsStr = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      key: const ValueKey('running'),
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Studying $_selectedSubjectName", style: const TextStyle(fontSize: 20, color: Colors.blue)),
          const SizedBox(height: 20),
          Text(
            "$minutesStr:$secondsStr",
            style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _endSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("End Session", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. RATING VIEW
  Widget _buildRatingView(DatabaseProvider db) {
    return Container(
      key: const ValueKey('rating'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 80, color: Colors.purple),
          const SizedBox(height: 20),
          const Text("Session Complete!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 30),
          Text("How productive were you? (${_productivity.toInt()}/10)", style: const TextStyle(fontSize: 16)),
          Slider(
            value: _productivity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.purple,
            onChanged: (val) => setState(() => _productivity = val),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => _saveRating(db),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Save & Finish", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOG FOR NEW SUBJECT ---
  void _showAddSubjectDialog(DatabaseProvider db) {
    final nameController = TextEditingController();
    int diff = 3;
    int imp = 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Create New Subject"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Subject Name"),
                  ),
                  const SizedBox(height: 20),
                  Text("Difficulty: $diff/5"),
                  Slider(value: diff.toDouble(), min: 1, max: 5, divisions: 4, onChanged: (v) => setStateDialog(() => diff = v.toInt())),
                  const SizedBox(height: 10),
                  Text("Importance: $imp/5"),
                  Slider(value: imp.toDouble(), min: 1, max: 5, divisions: 4, onChanged: (v) => setStateDialog(() => imp = v.toInt())),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      await db.addSubject(uid: uid, name: nameController.text.trim(), difficulty: diff, importance: imp);
                      setState(() {
                        _selectedSubjectName = nameController.text.trim(); // Auto-select the new subject
                      });
                      Navigator.pop(context); // close dialog
                    }
                  },
                  child: const Text("Save Subject"),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}