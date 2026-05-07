import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Controls the red blink effect
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xffF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: 60, color: Colors.green),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to continue your learning journey.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ANIMATED CONTAINER FOR ERROR BLINK
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400), // Smooth fade in/out
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _hasError ? Colors.red.shade50 : Colors.white,
                    border: Border.all(
                      color: _hasError ? Colors.red : Colors.transparent, 
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                        _triggerErrorBlink("Please enter both email and password.");
                        return;
                      }

                      // We now capture the specific error string
                      String? errorMessage = await authProvider.login(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );

                      // If errorMessage is NOT null, it means it failed.
                      if (errorMessage != null) {
                        _triggerErrorBlink(errorMessage);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                      },
                      child: const Text("Sign Up", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to trigger the red blink and auto-reset
  void _triggerErrorBlink(String message) {
    setState(() => _hasError = true);
    
    // Show the error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      )
    );

    // Turn off the red blink after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _hasError = false);
      }
    });
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _hasError ? Colors.red : Colors.green),
        filled: true,
        fillColor: const Color(0xffF7F9FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _hasError ? Colors.red : Colors.green, width: 2)),
      ),
    );
  }
}