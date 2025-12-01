import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue.dart';

class IssueService {
  // Usa localhost per Chrome
  static const String baseUrl = 'http://localhost:3000'; 

  // GET TUTTE LE ISSUE
  Future<List<Issue>> getIssues() async {
    final url = Uri.parse('$baseUrl/issues');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception("Token non trovato");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => Issue.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Errore Get Issues: $e");
      return [];
    }
  }

  // CREA NUOVA ISSUE (Questa è la funzione che ti mancava!)
  Future<bool> createIssue(String title, String description, String type, String priority, String label) async {
    final url = Uri.parse('$baseUrl/issues');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Il backend si aspetta: VERY_HIGH (con underscore e maiuscolo)
    String formattedPriority = priority.toUpperCase().replaceAll(' ', '_');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'type': type.toUpperCase(), 
          'priority': formattedPriority,
          'tags': [label] 
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print("Errore Create Issue: $e");
      return false;
    }
  }
}