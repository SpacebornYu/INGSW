import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Usare localhost per Chrome e iOS Simulator
  // Usare 10.0.2.2 per Android Emulator
  static const String baseUrl = 'http://localhost:3000';

  // --- MODIFICA PER I TEST: Dependency Injection ---
  final http.Client client;

  // Costruttore: se 'client' non viene passato (uso normale), crea un nuovo http.Client().
  // Se viene passato (nei test), usa quello (che sarà il Mock).
  AuthService({http.Client? client}) : client = client ?? http.Client();

  // --- LOGIN ---
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      // Uso 'client.post' invece di 'http.post'
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('email', data['user']['email']);
        await prefs.setString('role', data['user']['role']);
        // SALVA L'ID UTENTE (serve per cancellare i commenti)
        if (data['user']['id'] != null) {
          await prefs.setInt('userId', data['user']['id']);
        }
        return true;
      }
      print("Login fallito: ${response.body}");
      return false;
    } catch (e) {
      print("Errore eccezione login: $e");
      return false;
    }
  }

  // REGISTRAZIONE NUOVO UTENTE (Solo per gli Admin)
  Future<String?> registerUser(String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/users/admin/users');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      // Uso 'client.post' invece di 'http.post'
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      if (response.statusCode == 201) {
        return null;
      } else {
        try {
          final body = jsonDecode(response.body);
          return body['error'] ?? "Errore server (${response.statusCode})";
        } catch (_) {
          return "Errore server (${response.statusCode})";
        }
      }
    } catch (e) {
      return "Errore di connessione: $e";
    }
  }

  // LOGOUT (Nessuna chiamata HTTP qui, rimane uguale)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}