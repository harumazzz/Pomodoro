import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PomodoroService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  PomodoroService._() {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.play(AssetSource('sounds/audio.mp3'));
    _musicPlayer.setVolume(0.5);
    _audioPlayer.setSourceAsset('sounds/finish.mp3');
  }

  factory PomodoroService() => _instance;

  static final PomodoroService _instance = PomodoroService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _kTimeRemainingKey = 'pomodoro_time_remaining';
  static const String _kIsWorkingKey = 'pomodoro_is_working';

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showCompletionNotification(String title) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pomodoro_channel_id',
          'Pomodoro Timer',
          channelDescription: 'Notification when work/break is finished.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      'Your current session has ended. Time for the next phase!',
      notificationDetails,
    );
  }

  Future<void> playCompletionSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<bool> isFocusMusicPlaying() async {
    try {
      final PlayerState state = _musicPlayer.state;
      return state == PlayerState.playing;
    } catch (e) {
      debugPrint("Error checking music state: $e");
      return false;
    }
  }

  Future<void> playFocusMusic() async {
    try {
      await _musicPlayer.resume();
    } catch (e) {
      debugPrint("Error playing focus music: $e");
    }
  }

  Future<void> pauseFocusMusic() async {
    try {
      await _musicPlayer.pause();
    } catch (e) {
      debugPrint("Error pausing music: $e");
    }
  }

  Future<void> resumeFocusMusic() async {
    try {
      await _musicPlayer.resume();
    } catch (e) {
      debugPrint("Error resuming music: $e");
    }
  }

  Future<void> stopFocusMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      debugPrint("Error stopping music: $e");
    }
  }

  Future<void> saveTimerState(int timeRemaining, bool isWorking) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTimeRemainingKey, timeRemaining);
    await prefs.setBool(_kIsWorkingKey, isWorking);
    debugPrint(
      "Timer state saved: $timeRemaining seconds, isWorking: $isWorking",
    );
  }

  Future<Map<String, dynamic>?> loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    int? timeRemaining = prefs.getInt(_kTimeRemainingKey);
    bool? isWorking = prefs.getBool(_kIsWorkingKey);

    if (timeRemaining != null && isWorking != null) {
      debugPrint(
        "Timer state loaded: $timeRemaining seconds, isWorking: $isWorking",
      );
      return {'timeRemaining': timeRemaining, 'isWorking': isWorking};
    }

    debugPrint("No timer state found.");
    return null;
  }
}
