// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'gamifikasi_channel';
  static const _channelName = 'Pengingat Belajar';

  // Notification IDs
  static const int _idHarian = 1;
  static const int _idSiang = 2;
  static const int _idSore = 3;
  static const int _idMalam = 4;
  static const int _idStreakWarning = 5; // Ganti dari 2 karena conflict
  static const int _idMilestone = 6; // Ganti dari 3 karena conflict

  // ═══════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Minta permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Ganti method _details yang lama dengan ini
  static NotificationDetails _buildDetails({
    required String body,
    String? bigPicturePath,
  }) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          // ← ini yang bikin bisa di-expand seperti WA
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: false,
            contentTitle: null,
            summaryText: _namaApp,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  static const _namaApp = 'Gamifikasi Edukatif';

  // ═══════════════════════════════════════════
  // 1. PENGINGAT HARIAN — jam 07:00, 12:00, 17:00, 20:00
  // ═══════════════════════════════════════════

  static Future<void> scheduleDailyReminder() async {
    final messages = [
      (
        '📚 Yuk Belajar Hari Ini!',
        'Jangan lupa kuis hari ini. Streak kamu menunggu! 🔥'
      ),
      (
        '🚀 Semangat Pagi!',
        'Mulai hari dengan belajar 10 menit. Kamu pasti bisa!'
      ),
      (
        '⭐ Hari Baru, Ilmu Baru!',
        'Buka app dan selesaikan satu kuis. Mudah banget!'
      ),
      ('🎯 Target Hari Ini', 'Selesaikan 3 kuis dan dapatkan +50 XP Bonus!'),
      (
        '🌟 Halo, Jagoan!',
        'Otak kamu siap menyerap ilmu baru hari ini. Ayo mulai!'
      ),
      (
        '💪 Konsisten itu Keren!',
        'Belajar sedikit tiap hari lebih baik dari belajar banyak sekali.'
      ),
      (
        '🏆 Juara Dimulai dari Sini',
        'Para juara di leaderboard juga mulai dari nol. Yuk kejar!'
      ),
      (
        '💀 Bahkan Jenius Pernah Gagal',
        'Bedanya, mereka memilih bangkit. Kamu gimana?'
      ),
      (
        '⚡ Semua Pernah Bodoh',
        'Yang beda cuma yang terus belajar dan yang menyerah.'
      ),
      (
        '🌍 Dunia Kejam bagi yang Lemah',
        'Tapi kamu bisa jadi kuat dengan belajar setiap hari!'
      ),
      (
        '🔥 Dunia Terasa Kejam',
        'Jadikan itu alasan untuk terus belajar dan berkembang.'
      ),
      (
        '💡 Dunia Tidak Selalu Adil',
        'Ilmu adalah cara terbaik untuk mengubah keadaanmu.'
      ),
    ];

    // Pilih pesan berdasarkan hari dalam seminggu
    final dayIndex = DateTime.now().weekday - 1; // 0-6
    final (title, body) = messages[dayIndex];

    final schedules = [
      {'hour': 7, 'minute': 0, 'id': _idHarian}, // 07:00
      {'hour': 12, 'minute': 0, 'id': _idSiang}, // 12:00
      {'hour': 17, 'minute': 0, 'id': _idSore}, // 17:00
      {'hour': 20, 'minute': 0, 'id': _idMalam}, // 20:00
    ];

    for (var schedule in schedules) {
      // Gunakan 'as int' untuk konversi tipe yang aman
      final int hour = schedule['hour'] as int;
      final int minute = schedule['minute'] as int;
      final int id = schedule['id'] as int;

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextTZInstanceOf(hour, minute), // Gunakan fungsi TZDateTime
        _buildDetails(body: body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat harian
      );
    }
  }

  // ═══════════════════════════════════════════
  // 2. STREAK WARNING — jam 19:00 jika belum login
  //    (dipanggil dari luar setelah cek Firestore)
  // ═══════════════════════════════════════════

  static Future<void> scheduleStreakWarning(int currentStreak) async {
    if (currentStreak == 0) return;

    await _plugin.zonedSchedule(
      _idStreakWarning,
      '⚠️ Streak $currentStreak Hari Mau Hilang!',
      'Kamu belum belajar hari ini. Login sekarang sebelum streak kamu reset! 😱',
      _nextTZInstanceOf(19, 0), // 19:00 sebagai peringatan malam
      _buildDetails(
        body:
            'Kamu belum belajar hari ini. Login sekarang sebelum streak kamu reset! 😱',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStreakWarning() async {
    await _plugin.cancel(_idStreakWarning);
  }

  // ═══════════════════════════════════════════
  // 3. MILESTONE STREAK — tampil langsung (tidak terjadwal)
  // ═══════════════════════════════════════════

  static Future<void> showMilestoneNotification(int streakDays) async {
    final milestones = {
      3: (
        '🔥 Streak 3 Hari!',
        'Luar biasa! Kamu sudah belajar 3 hari berturut-turut. Terus semangat!'
      ),
      7: (
        '⚡ Streak 7 Hari!',
        'Wow, seminggu penuh! Kamu luar biasa! Badge "Semangat Seminggu" sudah kamu raih!'
      ),
      14: (
        '💎 Streak 2 Minggu!',
        'Dua minggu tanpa henti! Kamu benar-benar juara sejati!'
      ),
      30: (
        '👑 Streak 30 Hari!',
        'LUAR BIASA! Sebulan penuh belajar setiap hari. Kamu adalah legenda!'
      ),
    };

    if (!milestones.containsKey(streakDays)) return;

    final (title, body) = milestones[streakDays]!;

    await _plugin.show(
      _idMilestone,
      title,
      body,
      _buildDetails(body: body),
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════

  // Hanya SATU fungsi _nextTZInstanceOf yang mengembalikan TZDateTime
  static tz.TZDateTime _nextTZInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
