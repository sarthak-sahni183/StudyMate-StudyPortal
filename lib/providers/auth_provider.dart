import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> login(
      String email,
      String password) async {
    isLoading = true;
    notifyListeners();

    await _authService.login(email, password);

    isLoading = false;
    notifyListeners();
  }

  Future<void> signup(
      String email,
      String password) async {
    isLoading = true;
    notifyListeners();

    await _authService.signUp(email, password);

    isLoading = false;
    notifyListeners();
  }
}