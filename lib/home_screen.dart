import 'package:flutter/material.dart';
import 'package:pomodoro/timer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ready to focus?',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              child: const Text('START SESSION'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
