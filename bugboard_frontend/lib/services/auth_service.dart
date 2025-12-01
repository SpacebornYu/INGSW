import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // URL del backend:
  // Usa 'http://10.0.2.2:3000' se usi l'Emulatore Android
  // Usa 'http://localhost:3000' se usi il simulatore iOS
  // Usa il tuo IP locale (es. 192.168.1.X) se usi un telefono fisico
  static const String baseUrl = 'http://LocalHost:3000';

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      print("Provo a connettermi a: $url");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        // Login riuscito: il backend restituisce il token
        final data = jsonDecode(response.body);
        String token = data['token'];
        // Salviamo il token nella memoria del telefono
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return true;
      } else {
        // Login fallito (es. 401 Credenziali non valide)
        return false;
      }
    } catch (e) {
      print("Errore di connessione: $e");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}