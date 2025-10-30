import 'package:flutter/material.dart';
import 'package:pomodoro/home_screen.dart';

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.redAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
