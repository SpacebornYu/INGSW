import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue.dart';

class IssueService {
  // Per Chrome usiamo localhost
  static const String baseUrl = 'http://localhost:3000'; 

  Future<List<Issue>> getIssues() async {
    final url = Uri.parse('$baseUrl/issues');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception("Token non trovato");

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
      throw Exception("Errore ${response.statusCode}");
    }
  }
}