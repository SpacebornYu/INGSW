import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue.dart';

class IssueService {
  // Usa localhost per Web/iOS, 10.0.2.2 per Android
  static const String baseUrl = 'http://localhost:3000'; 

  // --- GET LISTA ---
  Future<List<Issue>> getIssues() async {
    final url = Uri.parse('$baseUrl/issues');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token non trovato");

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => Issue.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- GET DETTAGLIO ---
  Future<Issue?> getIssueDetails(int id) async {
    final url = Uri.parse('$baseUrl/issues/$id');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Issue.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- POST COMMENTO ---
  Future<bool> postComment(int issueId, String content) async {
    final url = Uri.parse('$baseUrl/issues/$issueId/comments');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'content': content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- DELETE COMMENTO ---
  Future<bool> deleteComment(int commentId) async {
    final url = Uri.parse('$baseUrl/comments/$commentId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // --- CREA ISSUE (CORRETTO: Accetta List<String>) ---
  Future<bool> createIssue(String title, String description, String type, String priority, String label, List<String> imagePaths) async {
    final url = Uri.parse('$baseUrl/issues');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String formattedPriority = priority;
    if (priority == 'Very High') formattedPriority = 'VERY HIGH';
    else if (priority == 'High') formattedPriority = 'HIGH';
    else if (priority == 'Medium') formattedPriority = 'MEDIUM';
    else if (priority == 'Low') formattedPriority = 'LOW';
    else if (priority == 'Very Low') formattedPriority = 'VERY LOW';

    Map<String, dynamic> bodyMap = {
      'title': title,
      'description': description,
      'type': type.toUpperCase(),
      'priority': formattedPriority,
      'tags': [label],
    };

    // Impacchetta la lista in una stringa JSON
    if (imagePaths.isNotEmpty) {
      bodyMap['imageUrl'] = jsonEncode(imagePaths); 
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode != 201) {
        print("ERRORE CREAZIONE: ${response.body}");
      }
      return response.statusCode == 201;
    } catch (e) {
      print("ECCEZIONE: $e");
      return false;
    }
  }

  // --- AGGIORNA STATO ---
  Future<bool> updateStatus(int issueId, String newStatus) async {
    final url = Uri.parse('$baseUrl/issues/$issueId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
}