import 'dart:async';
import 'dart:math';
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
            // Animated Subject Selection
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Subject", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color.fromARGB(255, 72, 181, 78))),
                  const SizedBox(height: 10),
                  
                  // Real-time dropdown from Firebase
                  StreamBuilder<List<Subject>>(
                    stream: db.getSubjectsStream(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                        );
                      }

                      List<Subject> subjects = snapshot.data ?? [];

                      return Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.green, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  filled: true,
                                  fillColor: Colors.green.shade50,
                                ),
                                hint: const Text("Choose a subject...", style: TextStyle(color: Colors.green)),
                                initialValue: _selectedSubjectName,
                                items: subjects.map((sub) {
                                  return DropdownMenuItem(
                                    value: sub.name,
                                    child: Text(sub.name, style: const TextStyle(color: Colors.green)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedSubjectName = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Button to create a new subject
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: InkWell(
                              onTap: () => _showAddSubjectDialog(db),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: const Icon(Icons.add, color: Colors.green),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Animated Duration Slider
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Duration: $_durationMinutes minutes", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                  const SizedBox(height: 15),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.green.shade400,
                      inactiveTrackColor: Colors.green.shade100,
                      thumbColor: Colors.green,
                      overlayColor: Colors.green.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                    ),
                    child: Slider(
                      value: _durationMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      onChanged: (val) {
                        setState(() => _durationMinutes = val.toInt());
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("5 min", style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                      Text("120 min", style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Animated Start Button
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _startSession(db),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.green.withOpacity(0.3),
                  ),
                  child: const Text("Start Session", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
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
    double progress = _secondsRemaining / (_durationMinutes * 60);

    return Container(
      key: const ValueKey('running'),
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final circleSize = min(constraints.maxWidth * 0.8, 460.0).clamp(260.0, 460.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Studying $_selectedSubjectName", 
                style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.w500)),
              const SizedBox(height: 30),
              
              // Animated Circular Progress Indicator
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // --- THE FIX: Wrap the TweenBuilder in a SizedBox.expand ---
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 14,
                            backgroundColor: Colors.blue.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                          );
                        },
                      ),
                    ),
                    // Animated Time Display
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$minutesStr:$secondsStr",
                                  style: TextStyle(
                                    fontSize: circleSize * 0.18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    fontFeatures: [const FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "minutes remaining",
                                  style: TextStyle(fontSize: circleSize * 0.045, color: Colors.blue.shade600),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.redAccent.withOpacity(0.3),
                  ),
                  child: const Text("End Session", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        },
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
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Celebration Icon
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: const Icon(Icons.celebration, size: 80, color: Colors.purple),
          ),
          
          const SizedBox(height: 20),
          
          // Animated Title
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: const Text("Session Complete!", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
          ),
          
          const SizedBox(height: 30),
          
          // Animated Productivity Slider
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text("How productive were you? (${_productivity.toInt()}/10)", 
                  style: TextStyle(fontSize: 16, color: Colors.purple.shade700, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.purple.shade400,
                    inactiveTrackColor: Colors.purple.shade100,
                    thumbColor: Colors.purple,
                    overlayColor: Colors.purple.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                    valueIndicatorColor: Colors.purple,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  ),
                  child: Slider(
                    value: _productivity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _productivity.toInt().toString(),
                    onChanged: (val) => setState(() => _productivity = val),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("1 - Not productive", style: TextStyle(fontSize: 12, color: Colors.purple.shade600)),
                    Text("10 - Very productive", style: TextStyle(fontSize: 12, color: Colors.purple.shade600)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Animated Save Button
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _saveRating(db),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: Colors.purple.withOpacity(0.3),
                ),
                child: const Text("Save & Finish", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
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
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text("Create New Subject", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Text Field
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Subject Name",
                          labelStyle: TextStyle(color: Colors.green.shade600),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.green.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.green.shade50,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Animated Difficulty Slider
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text("Difficulty: $diff/5", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.orange.shade400,
                              inactiveTrackColor: Colors.orange.shade100,
                              thumbColor: Colors.orange,
                              overlayColor: Colors.orange.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            ),
                            child: Slider(
                              value: diff.toDouble(), 
                              min: 1, 
                              max: 5, 
                              divisions: 4, 
                              onChanged: (v) => setStateDialog(() => diff = v.toInt())
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Animated Importance Slider
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text("Importance: $imp/5", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.red.shade400,
                              inactiveTrackColor: Colors.red.shade100,
                              thumbColor: Colors.red,
                              overlayColor: Colors.red.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            ),
                            child: Slider(
                              value: imp.toDouble(), 
                              min: 1, 
                              max: 5, 
                              divisions: 4, 
                              onChanged: (v) => setStateDialog(() => imp = v.toInt())
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Animated Cancel Button
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))
                    ),
                  ),
                  
                  // Animated Save Button
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1100),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty) {
                          await db.addSubject(uid: uid, name: nameController.text.trim(), difficulty: diff, importance: imp);
                          setState(() {
                            _selectedSubjectName = nameController.text.trim(); // Auto-select the new subject
                          });
                          Navigator.pop(context); // close dialog
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Save Subject"),
                    ),
                  )
                ],
              ),
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