import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() =>
      _AddSessionScreenState();
}

class _AddSessionScreenState
    extends State<AddSessionScreen> {

  final TextEditingController subjectController =
      TextEditingController();

  final TextEditingController durationController =
      TextEditingController();

  double productivity = 5;

  @override
  Widget build(BuildContext context) {

    final sessionProvider =
        Provider.of<SessionProvider>(context);

    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Add Study Session"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 20),

            // SUBJECT FIELD
            TextField(
              controller: subjectController,

              decoration: InputDecoration(
                labelText: "Subject",
                hintText: "Enter subject name",

                prefixIcon:
                    const Icon(Icons.book),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // DURATION FIELD
            TextField(
              controller: durationController,

              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                labelText: "Duration (minutes)",
                hintText: "Enter study duration",

                prefixIcon:
                    const Icon(Icons.timer),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // PRODUCTIVITY LABEL
            Text(
              "Productivity Level: ${productivity.toInt()}/10",

              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            // PRODUCTIVITY SLIDER
            Slider(
              value: productivity,

              min: 1,
              max: 10,

              divisions: 9,

              label:
                  productivity.toInt().toString(),

              onChanged: (value) {

                setState(() {
                  productivity = value;
                });
              },
            ),

            const SizedBox(height: 40),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: () async {

                  // VALIDATION
                  if (subjectController.text
                          .trim()
                          .isEmpty ||
                      durationController.text
                          .trim()
                          .isEmpty) {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please fill all fields",
                        ),
                      ),
                    );

                    return;
                  }

                  await sessionProvider.addSession(
                    uid: user!.uid,

                    subject:
                        subjectController.text.trim(),

                    duration: int.parse(
                      durationController.text.trim(),
                    ),

                    productivity:
                        productivity.toInt(),
                  );

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Session Added Successfully",
                      ),
                    ),
                  );

                  Navigator.pop(context);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  "Save Session",

                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}