import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/calendar/calendar_screen.dart';
import 'global_event_reminder_service.dart';

class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // uid user yang sedang login — sama seperti pola di firebase_service.dart
  String get _uid => _auth.currentUser!.uid;

  // ── Referensi ────────────────────────────────

  /// Sub-collection di bawah /users/{uid}/ — konsisten dengan struktur kamu
  CollectionReference<Map<String, dynamic>> get _userEvents =>
      _db.collection('users').doc(_uid).collection('calendar_events');

  /// Collection top-level untuk event global buatan admin
  CollectionReference<Map<String, dynamic>> get _globalEvents =>
      _db.collection('global_events');

  // ─────────────────────────────────────────────
  // STREAM: gabung user events + global events
  // ─────────────────────────────────────────────

  /// Gunakan di CalendarScreen pakai StreamBuilder:
  ///
  ///   StreamBuilder<List<CalendarEvent>>(
  ///     stream: CalendarService.instance.eventsStream(),
  ///     builder: (ctx, snap) { ... }
  ///   )
  Stream<List<CalendarEvent>> eventsStream() {
    // Listen user events secara realtime,
    // setiap ada perubahan juga ambil global events terbaru
    return _userEvents.orderBy('date').snapshots().asyncMap((userSnap) async {
      // Ambil global events (biasanya tidak sering berubah)
      final globalSnap = await _globalEvents.orderBy('date').get();

      final userList = userSnap.docs
          .map((d) => _fromFirestore(d.id, d.data(), isGlobal: false))
          .toList();

      final globalList = globalSnap.docs
          .map((d) => _fromFirestore(d.id, d.data(), isGlobal: true))
          .toList();

      // Gabung: user events dulu, global di belakang
      return [...userList, ...globalList];
    });
  }

  // // ─────────────────────────────────────────────
  // // CRUD — USER EVENTS
  // // ─────────────────────────────────────────────

  // /// Tambah event/note baru milik user
  // Future<void> addEvent(CalendarEvent event) async {
  //   await _userEvents.doc(event.id).set(_toFirestore(event));
  // }

  // /// Update event/note yang sudah ada
  // Future<void> updateEvent(CalendarEvent event) async {
  //   await _userEvents.doc(event.id).update(_toFirestore(event));
  // }

  // /// Hapus event/note milik user (tidak bisa hapus event global)
  // Future<void> deleteEvent(String eventId) async {
  //   await _userEvents.doc(eventId).delete();
  // }

  // ─────────────────────────────────────────────
  // ADMIN — GLOBAL EVENTS
  // ─────────────────────────────────────────────

  /// Dipanggil dari admin_service.dart atau admin screen
  /// Contoh: CalendarService.instance.addGlobalEvent(event)
  Future<void> addGlobalEvent(CalendarEvent event) async {
    await _globalEvents.doc(event.id).set({
      ..._toFirestore(event),
      'createdBy': _uid,
      'isGlobal': true,
    });
    // Schedule reminder untuk event baru
    await GlobalEventReminderService.scheduleForNewEvent(event);
  }

  // Update method deleteGlobalEvent
  Future<void> deleteGlobalEvent(String eventId) async {
    // Cancel reminder terlebih dahulu
    await GlobalEventReminderService.cancelEventReminder(eventId);
    await _globalEvents.doc(eventId).delete();
  }

  // Tambahkan method baru untuk update global event
  Future<void> updateGlobalEvent(CalendarEvent event) async {
    await _globalEvents.doc(event.id).update({
      'title': event.title,
      'description': event.description,
      'date': Timestamp.fromDate(event.date),
      'type': event.type.name,
      'color': event.color.value,
      'isAllDay': event.isAllDay,
      'hour': event.time?.hour,
      'minute': event.time?.minute,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update reminder
    await GlobalEventReminderService.updateEventReminder(event);
  }
  // ─────────────────────────────────────────────
  // KONVERTER  (Dart ↔ Firestore)
  // ─────────────────────────────────────────────

  /// Dart → Firestore document
  Map<String, dynamic> _toFirestore(CalendarEvent e) => {
        'title': e.title,
        'description': e.description,
        // Simpan sebagai Timestamp — konsisten dengan cara firebase_service.dart
        // menyimpan data lain (saveQuizResult pakai FieldValue.serverTimestamp)
        'date': Timestamp.fromDate(e.date),
        'type': e.type.name, // 'event' atau 'note'
        'color': e.color.value, // int hex, mudah dibaca kembali
        'isAllDay': e.isAllDay,
        'hour': e.time?.hour, // null kalau isAllDay = true
        'minute': e.time?.minute,
        // Pakai FieldValue.serverTimestamp() seperti di saveQuizResult
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _uid,
      };

  /// Firestore document → Dart
  CalendarEvent _fromFirestore(
    String id,
    Map<String, dynamic> data, {
    required bool isGlobal,
  }) {
    // date disimpan sebagai Timestamp
    final ts = data['date'];
    DateTime date;
    if (ts is Timestamp) {
      date = ts.toDate();
    } else if (ts is String) {
      // fallback: kalau ada data lama yang tersimpan sebagai ISO string
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
      isGlobal: isGlobal,
    );
  }
}
