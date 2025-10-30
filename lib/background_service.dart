import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro/pomodoro_service.dart';

class BackgroundService {
  static const String timerTaskId = 'pomodoro_timer';
  static const String _lastTimestampKey = 'pomodoro_last_timestamp';
  static const String _timerActiveKey = 'pomodoro_timer_active';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      timerTaskId,
      'pomodoroTimerTask',
      frequency: const Duration(seconds: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    debugPrint('[BackgroundService] Background service initialized');
  }

  static Future<void> saveTimerState(
    int timeRemaining,
    bool isWorking,
    bool isActive,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_time_remaining', timeRemaining);
    await prefs.setBool('pomodoro_is_working', isWorking);
    await prefs.setBool(_timerActiveKey, isActive);
    await prefs.setInt(
      _lastTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    debugPrint(
      '[BackgroundService] State saved: $timeRemaining sec, isWorking: $isWorking, isActive: $isActive',
    );
  }

  static Future<Map<String, dynamic>?> loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    final int? timeRemaining = prefs.getInt('pomodoro_time_remaining');
    final bool? isWorking = prefs.getBool('pomodoro_is_working');
    final bool? isActive = prefs.getBool(_timerActiveKey);
    final int? lastTimestamp = prefs.getInt(_lastTimestampKey);

    if (timeRemaining != null &&
        isWorking != null &&
        isActive != null &&
        lastTimestamp != null) {
      debugPrint(
        '[BackgroundService] State loaded: $timeRemaining sec, isWorking: $isWorking, isActive: $isActive',
      );
      return {
        'timeRemaining': timeRemaining,
        'isWorking': isWorking,
        'isActive': isActive,
        'lastTimestamp': lastTimestamp,
      };
    }

    return null;
  }

  static Future<int> getElapsedSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastTimestamp = prefs.getInt(_lastTimestampKey);

    if (lastTimestamp == null) return 0;

    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final int elapsed = ((currentTimestamp - lastTimestamp) / 1000).toInt();

    debugPrint('[BackgroundService] Elapsed time calculated: $elapsed seconds');
    return elapsed;
  }

  static Future<void> stopBackgroundTask() async {
    await Workmanager().cancelByUniqueName(timerTaskId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timerActiveKey, false);
    debugPrint('[BackgroundService] Background task stopped');
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('[BackgroundService] All background tasks cancelled');
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'pomodoroTimerTask') {
        debugPrint('[BackgroundService] Background task executing...');

        final state = await BackgroundService.loadTimerState();
        if (state == null || state['isActive'] != true) {
          return true;
        }

        final int timeRemaining = state['timeRemaining'] as int;
        final bool isWorking = state['isWorking'] as bool;
        final int lastTimestamp = state['lastTimestamp'] as int;
        final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        final int elapsed = ((currentTimestamp - lastTimestamp) / 1000).toInt();
        final int newTimeRemaining = (timeRemaining - elapsed).clamp(
          0,
          timeRemaining,
        );

        debugPrint(
          '[BackgroundService] Timer check: $newTimeRemaining sec remaining, elapsed: $elapsed sec',
        );
        await BackgroundService.saveTimerState(
          newTimeRemaining,
          isWorking,
          true,
        );
        if (newTimeRemaining <= 0) {
          debugPrint(
            '[BackgroundService] Timer finished! Showing notification...',
          );
          await PomodoroService().playCompletionSound();
          await PomodoroService().showCompletionNotification(
            isWorking ? "Break Time!" : "Time to Focus!",
          );
          final bool newIsWorking = !isWorking;
          const int workDuration = 25 * 60;
          const int breakDuration = 5 * 60;
          final int newDuration = newIsWorking ? workDuration : breakDuration;

          await BackgroundService.saveTimerState(
            newDuration,
            newIsWorking,
            true,
          );
          debugPrint(
            '[BackgroundService] Switched to ${newIsWorking ? 'WORK' : 'BREAK'} phase',
          );
        }

        return true;
      }
    } catch (e) {
      debugPrint('[BackgroundService] Error in background task: $e');
    }

    return true;
  });
}
