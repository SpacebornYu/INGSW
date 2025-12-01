import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importa la tua schermata di login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BugBoard26',
      debugShowCheckedModeBanner: false, // Toglie la scritta "DEBUG" rossa in alto
      theme: ThemeData(
        brightness: Brightness.dark, // Imposta il tema scuro globale (come nel mockup)
        primaryColor: const Color(0xFF1C1C1E),
        scaffoldBackgroundColor: const Color(0xFF000000), // Sfondo nero
        useMaterial3: true,
      ),
      home: const LoginScreen(), // <--- Qui diciamo di partire dal Login!
    );
  }
}