import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import '../screens/calendar/calendar_screen.dart';

class GlobalEventReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'global_events_channel';
  static const String _channelName = 'Pengingat Event Global';
  static const int _baseReminderId = 1000;

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
  }

  static NotificationDetails _buildDetails(String title, String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> scheduleAllGlobalEventReminders() async {
    final db = FirebaseFirestore.instance;

    try {
      final snapshot = await db.collection('global_events').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final event = _docToCalendarEvent(doc.id, data);
        if (event != null && !event.isAllDay && event.time != null) {
          await _scheduleEventReminder(event);
        }
      }
    } catch (e) {
      print('Error scheduling global event reminders: $e');
    }
  }

  static Future<void> _scheduleEventReminder(CalendarEvent event) async {
    if (event.isAllDay || event.time == null) return;

    final reminderTime = _getReminderDateTime(event);
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
    final reminderId = _getReminderId(event.id);

    final title = '📅 Event Hari Ini: ${event.title}';
    final body =
        'Dimulai pukul ${_formatTimeOfDay(event.time!)}. ${event.description ?? "Jangan sampai ketinggalan!"}';

    await _plugin.zonedSchedule(
      reminderId,
      title,
      body,
      tzReminderTime,
      _buildDetails(title, body),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static DateTime _getReminderDateTime(CalendarEvent event) {
    return DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      event.time!.hour,
      event.time!.minute,
    ).subtract(const Duration(hours: 1));
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static int _getReminderId(String eventId) {
    return _baseReminderId + eventId.hashCode.abs() % 10000;
  }

  static Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(_getReminderId(eventId));
  }

  static Future<void> scheduleForNewEvent(CalendarEvent event) async {
    if (!event.isAllDay && event.time != null) {
      await _scheduleEventReminder(event);
    }
  }

  static Future<void> updateEventReminder(CalendarEvent event) async {
    await cancelEventReminder(event.id);
    if (!event.isAllDay && event.time != null) {
      await _scheduleEventReminder(event);
    }
  }

  static CalendarEvent? _docToCalendarEvent(
      String id, Map<String, dynamic> data) {
    try {
      final ts = data['date'];
      DateTime date;
      if (ts is Timestamp) {
        date = ts.toDate();
      } else if (ts is String) {
        date = DateTime.tryParse(ts) ?? DateTime.now();
      } else {
        date = DateTime.now();
      }

      final hour = data['hour'] as int?;
      final minute = data['minute'] as int?;

      return CalendarEvent(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] as String?,
        date: date,
        type: data['type'] == 'note'
            ? CalendarEventType.note
            : CalendarEventType.event,
        color: Color(data['color'] as int? ?? 0xFF7C6FF7),
        isAllDay: data['isAllDay'] as bool? ?? true,
        time: (hour != null && minute != null)
            ? TimeOfDay(hour: hour, minute: minute)
            : null,
        isGlobal: true,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
