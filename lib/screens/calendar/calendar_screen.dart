// lib/screens/calendar/calendar_screen.dart
//
// Dependensi di pubspec.yaml (HAPUS syncfusion, tambahkan ini):
//   table_calendar: ^3.1.2
//   intl: ^0.19.0
//
// Buka dari streak card di home_screen.dart:
//   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../utils/app_theme.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

enum CalendarEventType { event, note }

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final CalendarEventType type;
  final Color color;
  final bool isAllDay;
  final TimeOfDay? time;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.type,
    required this.color,
    this.isAllDay = true,
    this.time,
  });
}

// ─────────────────────────────────────────────
// SCREEN UTAMA
// ─────────────────────────────────────────────

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;

  // Data — sambungkan ke Firestore nanti
  late List<CalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
    _panelController.forward();
    _initDummyData();
  }

  void _initDummyData() {
    final now = DateTime.now();
    _events = [
      CalendarEvent(
        id: 'ev1',
        title: '📝 Ulangan Matematika',
        description: 'Bab 3: Pecahan dan Desimal',
        date: now.add(const Duration(days: 2)),
        type: CalendarEventType.event,
        color: const Color(0xFF7C6FF7),
        isAllDay: false,
        time: const TimeOfDay(hour: 9, minute: 0),
      ),
      CalendarEvent(
        id: 'ev2',
        title: '🏆 Turnamen Kuis',
        description: 'Kompetisi antar pengguna – semua mata pelajaran',
        date: now.add(const Duration(days: 5)),
        type: CalendarEventType.event,
        color: const Color(0xFFFF6B6B),
        isAllDay: false,
        time: const TimeOfDay(hour: 14, minute: 0),
      ),
      CalendarEvent(
        id: 'ev3',
        title: '🎯 Target Mingguan',
        description: 'Selesaikan 10 kuis minggu ini',
        date: now.add(const Duration(days: 1)),
        type: CalendarEventType.event,
        color: const Color(0xFF06D6A0),
        isAllDay: true,
      ),
      CalendarEvent(
        id: 'note1',
        title: '💡 Catatan IPA',
        description: 'Fotosintesis: 6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
        date: now,
        type: CalendarEventType.note,
        color: const Color(0xFF3BCEAC),
        isAllDay: true,
      ),
      CalendarEvent(
        id: 'note2',
        title: '📌 Reminder Belajar',
        description: 'Review materi IPS bab 4 sebelum kuis',
        date: now.subtract(const Duration(days: 1)),
        type: CalendarEventType.note,
        color: const Color(0xFFFFB347),
        isAllDay: true,
      ),
    ];
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  List<CalendarEvent> _eventsForDay(DateTime day) =>
      _events.where((e) => isSameDay(e.date, day)).toList();

  bool _hasStreak(DateTime day, int streakDays) {
    final now = DateTime.now();
    for (int i = 0; i < streakDays; i++) {
      if (isSameDay(day, now.subtract(Duration(days: i)))) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;
    final streakDays = user?.streakDays ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: Column(
        children: [
          _buildHeader(user, streakDays),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendar(streakDays),
                  _buildDayPanel(streakDays),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Header ───────────────────────────────────

  Widget _buildHeader(dynamic user, int streakDays) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C6FF7), Color(0xFF9B8FFF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '📅 Kalender Belajar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip('🔥', '$streakDays hari streak'),
                    _chip('📅',
                        '${_events.where((e) => e.type == CalendarEventType.event).length} event'),
                    _chip('🔵',
                        '${_events.where((e) => e.type == CalendarEventType.note).length} catatan'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── Calendar ─────────────────────────────────

  Widget _buildCalendar(int streakDays) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _formatBtn(CalendarFormat.month, '📆 Bulan'),
                const SizedBox(width: 6),
                _formatBtn(CalendarFormat.twoWeeks, '2 Minggu'),
                const SizedBox(width: 6),
                _formatBtn(CalendarFormat.week, '7️⃣ Minggu'),
              ],
            ),
          ),
          TableCalendar<CalendarEvent>(
            locale: 'id_ID',
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            eventLoader: _eventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: Color(0xFF7C6FF7)),
              rightChevronIcon:
                  Icon(Icons.chevron_right_rounded, color: Color(0xFF7C6FF7)),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888)),
              weekendStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B6B)),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: const BoxDecoration(
                color: Color(0xFF7C6FF7),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF7C6FF7).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C6FF7), width: 2),
              ),
              selectedTextStyle: const TextStyle(
                  color: Color(0xFF7C6FF7), fontWeight: FontWeight.w800),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
              markerSize: 5,
              markersMaxCount: 3,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, fd) =>
                  _dayCell(day, streakDays, false, false),
              todayBuilder: (ctx, day, fd) =>
                  _dayCell(day, streakDays, true, false),
              selectedBuilder: (ctx, day, fd) =>
                  _dayCell(day, streakDays, false, true),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _panelController
                ..reset()
                ..forward();
            },
            onFormatChanged: (f) => setState(() => _calendarFormat = f),
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime day, int streakDays, bool isToday, bool isSelected) {
    final hasStreak = _hasStreak(day, streakDays);
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? const Color(0xFF7C6FF7)
                : isSelected
                    ? const Color(0xFF7C6FF7).withOpacity(0.12)
                    : Colors.transparent,
            border: isSelected && !isToday
                ? Border.all(color: const Color(0xFF7C6FF7), width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isToday || isSelected ? FontWeight.w800 : FontWeight.normal,
                color: isToday
                    ? Colors.white
                    : isSelected
                        ? const Color(0xFF7C6FF7)
                        : const Color(0xFF333333),
              ),
            ),
          ),
        ),
        if (hasStreak)
          Positioned(
            bottom: 1,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _formatBtn(CalendarFormat fmt, String label) {
    final isActive = _calendarFormat == fmt;
    return GestureDetector(
      onTap: () => setState(() => _calendarFormat = fmt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7C6FF7)
              : const Color(0xFF7C6FF7).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF7C6FF7),
          ),
        ),
      ),
    );
  }

  // ── Day Panel ────────────────────────────────

  Widget _buildDayPanel(int streakDays) {
    final dayEvents = _eventsForDay(_selectedDay);
    final hasStreakToday = _hasStreak(_selectedDay, streakDays);

    return FadeTransition(
      opacity: _panelAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(_panelAnimation),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(_selectedDay),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                    if (hasStreakToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 4),
                            Text('Streak!',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              if (dayEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada event atau catatan',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + untuk menambahkan',
                          style: TextStyle(
                              color: Colors.grey.shade300, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: dayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _EventTile(
                    event: dayEvents[i],
                    onDelete: () => setState(() =>
                        _events.removeWhere((e) => e.id == dayEvents[i].id)),
                    onEdit: () => _showAddSheet(existing: dayEvents[i]),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── FAB ──────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF7C6FF7),
      elevation: 4,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Tambah',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      onPressed: () => _showAddSheet(),
    );
  }

  void _showAddSheet({CalendarEvent? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEventSheet(
        selectedDate: _selectedDay,
        existing: existing,
        onSave: (event) {
          setState(() {
            if (existing != null) {
              _events.removeWhere((e) => e.id == existing.id);
            }
            _events.add(event);
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EVENT TILE
// ─────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EventTile(
      {required this.event, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isNote = event.type == CalendarEventType.note;
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: event.color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(isNote ? '🔵' : '📅',
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF2D2D2D))),
                    if (event.description != null) ...[
                      const SizedBox(height: 3),
                      Text(event.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.isAllDay
                          ? 'Seharian'
                          : event.time?.format(context) ?? '',
                      style: TextStyle(
                          fontSize: 11,
                          color: event.color,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(isNote ? 'Catatan' : 'Event',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADD / EDIT BOTTOM SHEET
// ─────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? existing;
  final void Function(CalendarEvent) onSave;

  const _AddEventSheet({
    required this.selectedDate,
    required this.onSave,
    this.existing,
  });

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  late CalendarEventType _type;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late bool _isAllDay;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? CalendarEventType.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _isAllDay = e?.isAllDay ?? true;
    _time = e?.time ?? TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _activeColor => _type == CalendarEventType.event
      ? const Color(0xFF7C6FF7)
      : const Color(0xFF3BCEAC);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEdit ? 'Edit' : 'Tambah ke Kalender',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                .format(widget.selectedDate),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _typeBtn(
                  CalendarEventType.event, '📅 Event', const Color(0xFF7C6FF7)),
              const SizedBox(width: 8),
              _typeBtn(CalendarEventType.note, '🔵 Catatan',
                  const Color(0xFF3BCEAC)),
            ],
          ),
          const SizedBox(height: 14),
          _field(
            controller: _titleCtrl,
            hint: _type == CalendarEventType.event
                ? 'Nama event...'
                : 'Judul catatan...',
          ),
          const SizedBox(height: 10),
          _field(
            controller: _descCtrl,
            hint: 'Deskripsi (opsional)...',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Switch(
                  value: _isAllDay,
                  activeColor: _activeColor,
                  onChanged: (v) => setState(() => _isAllDay = v),
                ),
                Text('Seharian',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const Spacer(),
                if (!_isAllDay)
                  TextButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                    icon: Icon(Icons.access_time_rounded, color: _activeColor),
                    label: Text(_time.format(context),
                        style: TextStyle(
                            color: _activeColor, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _activeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _save,
              child: Text(
                isEdit ? 'Simpan Perubahan' : 'Simpan',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(CalendarEventType type, String label, Color color) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : color,
              )),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5F4FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _activeColor, width: 1.5),
        ),
      ),
    );
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    widget.onSave(CalendarEvent(
      id: widget.existing?.id ?? 'ev_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: widget.selectedDate,
      type: _type,
      color: _activeColor,
      isAllDay: _isAllDay,
      time: _isAllDay ? null : _time,
    ));
  }
}
