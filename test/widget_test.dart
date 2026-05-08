// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Update these imports if your package name differs in pubspec.yaml
import 'package:studymate_studytracker/screens/auth/login_screen.dart';
import 'package:studymate_studytracker/screens/auth/signup_screen.dart';
import 'package:studymate_studytracker/providers/auth_provider.dart';

// 1. Create a Mock Provider to bypass Firebase Initialization during testing
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoading = false;

  @override
  Future<String?> login(String email, String password) async {
    return null; // Simulate successful response
  }

  @override
  Future<String?> signup(String email, String password, String arg3, String arg4) async {
    return null; // Simulate successful response
  }
}

void main() {
  group('Auth Screens Widget Tests', () {

    // --- TEST 1: Login UI Renders ---
    testWidgets('Test 1: Login Screen renders essential UI components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: MockAuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify that exactly 2 TextFields exist (Email and Password)
      expect(find.byType(TextField), findsNWidgets(2));

      // Verify that the Login Elevated Button exists
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Verify the TextButton (for navigating to Signup) exists
      expect(find.byType(TextButton), findsOneWidget);
    });

    // --- TEST 2: Signup UI Renders ---
    testWidgets('Test 2: Signup Screen renders essential UI components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: MockAuthProvider(),
            child: const SignupScreen(),
          ),
        ),
      );

      // Verify that the Signup Elevated Button exists
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    // --- TEST 3: Dynamic State Changes (Loading Indicator) ---
    testWidgets('Test 3: Login Screen shows loading indicator when authenticating', (WidgetTester tester) async {
      // Setup the mock to simulate an active loading state
      final mockProvider = MockAuthProvider();
      mockProvider.isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify that the CircularProgressIndicator is displayed instead of the text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
  });
}