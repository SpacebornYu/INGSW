import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart'; // FONDAMENTALE: Importa la dashboard

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

  void _login() async {
    // Controllo campi vuoti
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Inserisci email e password."),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      bool success = await _authService.login(email, password);

      if (!mounted) return;

      if (success) {
        // CORREZIONE: Usiamo il push diretto, non named
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login fallito. Controlla le credenziali."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      print("Errore di login: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Errore di connessione: ${e.toString().split('\n')[0]}"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICONA CIRCOLARE
              Container(
                width: 140, 
                height: 140, 
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, 
                  color: Colors.white10, 
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0), 
                  child: ClipOval( 
                    child: Image.asset(
                      'assets/images/app_logo.png', 
                      fit: BoxFit.cover, 
                      // Aggiungiamo un gestore errori nel caso l'immagine non ci sia
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.bug_report, size: 70, color: Colors.white),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              const Text(
                'Accedi a BugBoard26',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              
              _buildInputField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Accedi',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
      ),
    );
  }
}