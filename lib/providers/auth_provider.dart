import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;

  // Returns null if successful, or an error string if it fails
  Future<String?> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    String? errorMsg = await _authService.login(email, password);

    isLoading = false;
    notifyListeners();
    
    return errorMsg; 
  }

  Future<String?> signup(String name, String age, String email, String password) async {
    isLoading = true;
    notifyListeners();

    String? errorMsg = await _authService.signUp(name, age, email, password);

    isLoading = false;
    notifyListeners();
    
    return errorMsg;
  }
}