import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    bool success = await _authService.login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const DashboardScreen())
      );
    } else {
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Center(child: Text("Credenziali non valide", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        content: const Text("Si prega di inserire delle credenziali valide.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Ok")))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFF2C2C2C), shape: BoxShape.circle)),
            const SizedBox(height: 24),
            const Text("Welcome to\nBugBoard26!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _buildInput("Email", _emailController, false),
            const SizedBox(height: 16),
            _buildInput("Password", _passwordController, true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E4F2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _handleLogin, 
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl, bool isPass) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}