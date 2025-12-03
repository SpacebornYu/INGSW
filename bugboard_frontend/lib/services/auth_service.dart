import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Usa localhost per Chrome e iOS Simulator
  // Usa 10.0.2.2 per Android Emulator
  static const String baseUrl = 'http://localhost:3000'; 

  // --- LOGIN ---
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login'); 
    try {
      final response = await http.post(
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
        
        // SALVIAMO L'ID UTENTE (Fondamentale per cancellare i commenti)
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

  // --- REGISTRAZIONE NUOVO UTENTE (Solo Admin) ---
  Future<String?> registerUser(String email, String password, String role) async {
    // Rotta combinata corretta
    final url = Uri.parse('$baseUrl/users/admin/users'); 
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
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
        return null; // Successo
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

  // --- LOGOUT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}