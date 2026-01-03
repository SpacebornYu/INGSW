import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Importa i tuoi file corretti qui:
import 'package:bugboard_frontend/services/auth_service.dart';
import 'package:bugboard_frontend/services/issue_service.dart';

// Generazione del Mock per il Client HTTP
@GenerateMocks([http.Client])
import 'unit_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late AuthService authService;
  late IssueService issueService;

  setUp(() {
    // Inizializza il mock delle SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Inizializza il mock del client HTTP
    mockClient = MockClient();
    
    // Inietta il mock nei service
    authService = AuthService(client: mockClient);
    issueService = IssueService(client: mockClient);
  });

  group('AuthService Tests', () {
    // TEST 1: Login Success (2 Parametri)
    test('login returns true when status code is 200', () async {
      // ARRANGE (Prepariamo i dati finti)
      const email = 'test@test.com';
      const password = 'password123';
      
      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/auth/login'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({
          'token': 'fake_token',
          'user': {'email': email, 'role': 'USER', 'id': 1}
        }), 
        200
      ));

      // ACT (Eseguiamo il metodo)
      final result = await authService.login(email, password);

      // ASSERT (Verifichiamo il risultato)
      expect(result, true);
    });

    // TEST 2: Register User (3 Parametri - Admin)
    test('registerUser returns null (success) when status code is 201', () async {
      // ARRANGE
      // Simuliamo che siamo già loggati mettendo un token nelle prefs
      SharedPreferences.setMockInitialValues({'token': 'admin_token'});
      
      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/users/admin/users'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('', 201));

      // ACT
      final error = await authService.registerUser('new@user.com', 'pass', 'USER');

      // ASSERT
      expect(error, null); // Null significa nessun errore
    });
  });

  group('IssueService Tests', () {
    // TEST 3: Post Comment (2 Parametri)
    test('postComment returns true when comment is created', () async {
      SharedPreferences.setMockInitialValues({'token': 'valid_token'});
      
      when(mockClient.post(
        Uri.parse('${IssueService.baseUrl}/issues/1/comments'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"id": 1}', 201));

      final result = await issueService.postComment(1, "Bel lavoro!");

      expect(result, true);
    });

    // TEST 4: Update Status (2 Parametri)
    test('updateStatus returns true when patch is successful', () async {
      SharedPreferences.setMockInitialValues({'token': 'valid_token'});
      
      when(mockClient.patch(
        Uri.parse('${IssueService.baseUrl}/issues/1'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"status": "IN_PROGRESS"}', 200));

      final result = await issueService.updateStatus(1, "IN_PROGRESS");

      expect(result, true);
    });
  });
}