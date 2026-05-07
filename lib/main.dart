import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/database_provider.dart'; // <-- 1. Add this import!
import 'screens/auth_wrapper.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // <-- 2. Add the DatabaseProvider here! -->
        ChangeNotifierProvider(
          create: (_) => DatabaseProvider(), 
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Study Planner',
        theme: ThemeData(
          primarySwatch: Colors.green, // Changed to green to match your new UI theme!
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}