import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart'; // Assicurati che questo file esista in lib/screens/

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _handleLogin() async {
    // Chiudi la tastiera se è aperta
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    // Chiamata al servizio di Login
    bool success = await _authService.login(email, password);

    // Se il widget non è più montato (es. l'utente è uscito), non fare nulla
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // MODIFICA EFFETTUATA QUI:
      // Usiamo pushReplacement per andare alla Dashboard.
      // "Replacement" serve a rimuovere la schermata di Login dalla memoria,
      // così se premi "Indietro" dalla Dashboard non torni al Login (che sarebbe strano).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      // Mostra il popup di errore identico al mockup
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C), // Grigio scuro popup
        title: const Center(
          child: Text(
            "Credenziali non valide",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          )
        ),
        content: const Text(
          "Si prega di inserire delle credenziali valide e di effettuare nuovamente il login.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ok", style: TextStyle(color: Colors.blue)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Background scuro
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cerchio Placeholder (Logo)
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 24),
            // Titolo
            const Text(
              "Welcome to\nBugBoard26!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Campo Email
            _buildTextField("Email", _emailController, false),
            const SizedBox(height: 16),
            // Campo Password
            _buildTextField("Password", _passwordController, true),
            const SizedBox(height: 32),

            // Bottone Login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E4F2F), // Verde scuro mockup
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E1E1E), // Grigio Input
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}