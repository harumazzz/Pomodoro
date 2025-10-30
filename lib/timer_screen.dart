import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pomodoro/pomodoro_service.dart';
import 'package:pomodoro/background_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const int _workDuration = 25 * 60;

  static const int _breakDuration = 5 * 60;

  bool _isWorking = true;
  int _timeRemaining = _workDuration;
  Timer? _currentTimer;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    PomodoroService().initializeNotifications();
    BackgroundService.initialize();
  }

  Future<void> _initializeTimer() async {
    final savedState = await BackgroundService.loadTimerState();

    if (savedState != null && savedState['isActive'] == true) {
      final int elapsed = await BackgroundService.getElapsedSeconds();
      final int newTime = (savedState['timeRemaining'] as int) - elapsed;

      setState(() {
        _isWorking = savedState['isWorking'] as bool;
        _timeRemaining = newTime > 0 ? newTime : 0;
      });

      debugPrint(
        '[TimerScreen] Restored timer: $_timeRemaining sec, working: $_isWorking',
      );
    }

    _startTimer();
  }

  @override
  void dispose() {
    BackgroundService.saveTimerState(
      _timeRemaining,
      _isWorking,
      _currentTimer?.isActive ?? false,
    );
    PomodoroService().stopFocusMusic();
    _currentTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _currentTimer?.cancel();
    _timeRemaining = _isWorking ? _workDuration : _breakDuration;
    _resumeTimer();
  }

  void _resumeTimer() {
    PomodoroService().playFocusMusic();
    BackgroundService.saveTimerState(_timeRemaining, _isWorking, true);
    _currentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
          BackgroundService.saveTimerState(_timeRemaining, _isWorking, true);
        } else {
          _handleTimerFinished();
        }
      });
    });

    debugPrint(
      '[TimerScreen] Timer started: ${_isWorking ? 'WORK' : 'BREAK'} - $_timeRemaining sec',
    );
  }

  void _handleTimerFinished() async {
    _currentTimer?.cancel();
    await PomodoroService().playCompletionSound();
    debugPrint("Timer finished! Playing sound...");
    await PomodoroService().showCompletionNotification(
      _isWorking ? "Break Time!" : "Time to Focus!",
    );
    debugPrint("Showing notification...");
    setState(() {
      _isWorking = !_isWorking;
    });
    _startTimer();
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String currentMode = _isWorking ? 'FOCUS' : 'BREAK';
    final Color primaryColor = _isWorking
        ? Colors.redAccent
        : Colors.greenAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentMode),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            BackgroundService.saveTimerState(
              _timeRemaining,
              _isWorking,
              _currentTimer?.isActive ?? false,
            );
            _currentTimer?.cancel();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              currentMode,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _formatTime(_timeRemaining),
              style: Theme.of(context).textTheme.displayLarge,
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _currentTimer?.isActive == true
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  iconSize: 60,
                  color: Colors.white,
                  onPressed: () {
                    if (_currentTimer?.isActive == true) {
                      BackgroundService.saveTimerState(
                        _timeRemaining,
                        _isWorking,
                        false,
                      );
                      PomodoroService().pauseFocusMusic();
                      _currentTimer?.cancel();
                      debugPrint(
                        '[TimerScreen] Timer paused at $_timeRemaining sec',
                      );
                    } else {
                      _resumeTimer();
                      debugPrint(
                        '[TimerScreen] Timer resumed from $_timeRemaining sec',
                      );
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  iconSize: 60,
                  color: Colors.white,
                  onPressed: () async {
                    await BackgroundService.stopBackgroundTask();
                    await PomodoroService().stopFocusMusic();
                    _currentTimer?.cancel();
                    debugPrint('[TimerScreen] Timer stopped');
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
