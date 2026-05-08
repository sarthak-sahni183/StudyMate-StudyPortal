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
  Future<String?> signup(String name, String age, String email, String password) async {
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
      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('Test 3: Login Screen shows error when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: MockAuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Please enter both email and password.'), findsOneWidget);
    });

    testWidgets('Test 5: Signup Screen shows error when passwords do not match', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: MockAuthProvider(),
            child: const SignupScreen(),
          ),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), '25');
      await tester.enterText(fields.at(2), 'test@example.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'password321');

      final signUpButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('Passwords do not match. Please try again.'), findsOneWidget);
    });

    testWidgets('Test 6: Signup Screen shows loading indicator when authenticating', (WidgetTester tester) async {
      final mockProvider = MockAuthProvider();
      mockProvider.isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockProvider,
            child: const SignupScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- TEST 7: Dynamic State Changes (Loading Indicator) ---
    testWidgets('Test 7: Login Screen shows loading indicator when authenticating', (WidgetTester tester) async {
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