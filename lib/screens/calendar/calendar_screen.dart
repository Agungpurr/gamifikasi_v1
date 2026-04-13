// lib/screens/calendar/calendar_screen.dart
// VERSI FIRESTORE — disesuaikan dengan struktur data kamu:
//   users/{uid}  → streakDays, subjectProgress, dll (UserModel)
//   users/{uid}/calendar_events/{id}  → event & note user
//   global_events/{id}  → event admin

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../services/calendar_service.dart';
import '../../../utils/app_theme.dart';

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
  final bool isGlobal;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.type,
    required this.color,
    this.isAllDay = true,
    this.time,
    this.isGlobal = false,
  });
}

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
  late AnimationController _panelCtrl;
  late Animation<double> _panelAnim;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _panelAnim =
        CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOutCubic);
    _panelCtrl.forward();
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    super.dispose();
  }

  List<CalendarEvent> _forDay(DateTime day, List<CalendarEvent> all) =>
      all.where((e) => isSameDay(e.date, day)).toList();

  /// Streak dihitung mundur dari hari ini
  /// Konsisten dengan logika updateStreak() di firebase_service.dart
  bool _hasStreak(DateTime day, int streakDays) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    return diff >= 0 && diff < streakDays;
  }

  Future<void> _save(CalendarEvent ev, {CalendarEvent? existing}) async {
    try {
      if (existing != null) {
        await CalendarService.instance.updateEvent(ev);
      } else {
        await CalendarService.instance.addEvent(ev);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red.shade400,
        ));
      }
    }
  }

  Future<void> _delete(CalendarEvent ev) async {
    if (ev.isGlobal) return;
    try {
      await CalendarService.instance.deleteEvent(ev.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red.shade400,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final streakDays = user?.streakDays ?? 0;

    return StreamBuilder<List<CalendarEvent>>(
      stream: CalendarService.instance.eventsStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F7FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7C6FF7)),
            ),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F7FF),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('😕', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Gagal memuat kalender',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6FF7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi',
                      style: TextStyle(color: Colors.white)),
                ),
              ]),
            ),
          );
        }

        final all = snap.data ?? [];
        final evCount =
            all.where((e) => e.type == CalendarEventType.event).length;
        final noteCount =
            all.where((e) => e.type == CalendarEventType.note).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F7FF),
          body: Column(children: [
            _header(streakDays, evCount, noteCount),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  _calendar(streakDays, all),
                  _dayPanel(streakDays, all),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ]),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF7C6FF7),
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Tambah',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            onPressed: () => _showSheet(),
          ),
        );
      },
    );
  }

  Widget _header(int streak, int ev, int note) => Container(
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('📅 Kalender Belajar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip('🔥', '$streak hari streak'),
                  _chip('📅', '$ev event'),
                  _chip('🔵', '$note catatan'),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _chip(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _calendar(int streak, List<CalendarEvent> all) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _fmtBtn(CalendarFormat.month, '📆 Bulan'),
              const SizedBox(width: 6),
              _fmtBtn(CalendarFormat.twoWeeks, '2 Minggu'),
              const SizedBox(width: 6),
              _fmtBtn(CalendarFormat.week, '7️⃣ Minggu'),
            ]),
          ),
          TableCalendar<CalendarEvent>(
            locale: 'id_ID',
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            eventLoader: (day) => _forDay(day, all),
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2D2D)),
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
                  color: Color(0xFF7C6FF7), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF7C6FF7).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C6FF7), width: 2),
              ),
              selectedTextStyle: const TextStyle(
                  color: Color(0xFF7C6FF7), fontWeight: FontWeight.w800),
              markerDecoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B), shape: BoxShape.circle),
              markerSize: 5,
              markersMaxCount: 3,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, _) => _cell(day, streak, false, false),
              todayBuilder: (ctx, day, _) => _cell(day, streak, true, false),
              selectedBuilder: (ctx, day, _) => _cell(day, streak, false, true),
            ),
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              });
              _panelCtrl
                ..reset()
                ..forward();
            },
            onFormatChanged: (f) => setState(() => _calendarFormat = f),
            onPageChanged: (f) => setState(() => _focusedDay = f),
          ),
          const SizedBox(height: 8),
        ]),
      );

  Widget _cell(DateTime day, int streak, bool isToday, bool isSel) {
    final hasStr = _hasStreak(day, streak);
    return Stack(alignment: Alignment.center, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isToday
              ? const Color(0xFF7C6FF7)
              : isSel
                  ? const Color(0xFF7C6FF7).withOpacity(0.12)
                  : Colors.transparent,
          border: isSel && !isToday
              ? Border.all(color: const Color(0xFF7C6FF7), width: 2)
              : null,
        ),
        child: Center(
          child: Text('${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isToday || isSel ? FontWeight.w800 : FontWeight.normal,
                color: isToday
                    ? Colors.white
                    : isSel
                        ? const Color(0xFF7C6FF7)
                        : const Color(0xFF333333),
              )),
        ),
      ),
      if (hasStr)
        Positioned(
          bottom: 2,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Colors.orange, shape: BoxShape.circle),
          ),
        ),
    ]);
  }

  Widget _fmtBtn(CalendarFormat fmt, String label) {
    final active = _calendarFormat == fmt;
    return GestureDetector(
      onTap: () => setState(() => _calendarFormat = fmt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF7C6FF7)
              : const Color(0xFF7C6FF7).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF7C6FF7))),
      ),
    );
  }

  Widget _dayPanel(int streak, List<CalendarEvent> all) {
    final day = _forDay(_selectedDay, all);
    final hasStr = _hasStreak(_selectedDay, streak);

    return FadeTransition(
      opacity: _panelAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(_panelAnim),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 16,
                  offset: Offset(0, 4))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                        .format(_selectedDay),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2D2D)),
                  ),
                ),
                if (hasStr)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('🔥', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Text('Streak!',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (day.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Column(children: [
                    const Text('✨', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text('Tidak ada event atau catatan',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Tap + untuk menambahkan',
                        style: TextStyle(
                            color: Colors.grey.shade300, fontSize: 12)),
                  ]),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: day.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _EventTile(
                  event: day[i],
                  onDelete: () => _delete(day[i]),
                  onEdit: () => _showSheet(existing: day[i]),
                ),
              ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _showSheet({CalendarEvent? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(
        selectedDate: _selectedDay,
        existing: existing,
        onSave: (ev) async {
          await _save(ev, existing: existing);
          if (mounted) Navigator.pop(context);
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
      direction:
          event.isGlobal ? DismissDirection.none : DismissDirection.endToStart,
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
        onTap: event.isGlobal ? null : onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: event.color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                    color: event.color,
                    borderRadius: BorderRadius.circular(4))),
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
                      style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF2D2D2D)))),
                      if (event.isGlobal) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C6FF7).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7C6FF7),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ]),
                    if (event.description != null) ...[
                      const SizedBox(height: 3),
                      Text(event.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADD / EDIT SHEET
// ─────────────────────────────────────────────

class _AddSheet extends StatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? existing;
  final Future<void> Function(CalendarEvent) onSave;
  const _AddSheet(
      {required this.selectedDate, required this.onSave, this.existing});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late CalendarEventType _type;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late bool _isAllDay;
  late TimeOfDay _time;
  bool _saving = false;

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

  Color get _col => _type == CalendarEventType.event
      ? const Color(0xFF7C6FF7)
      : const Color(0xFF3BCEAC);

  @override
  Widget build(BuildContext context) {
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text(widget.existing != null ? 'Edit' : 'Tambah ke Kalender',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D))),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(widget.selectedDate),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _tBtn(CalendarEventType.event, '📅 Event', const Color(0xFF7C6FF7)),
          const SizedBox(width: 8),
          _tBtn(CalendarEventType.note, '🔵 Catatan', const Color(0xFF3BCEAC)),
        ]),
        const SizedBox(height: 14),
        _field(
            _titleCtrl,
            _type == CalendarEventType.event
                ? 'Nama event...'
                : 'Judul catatan...'),
        const SizedBox(height: 10),
        _field(_descCtrl, 'Deskripsi (opsional)...', maxLines: 2),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F4FF),
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Switch(
                value: _isAllDay,
                activeColor: _col,
                onChanged: (v) => setState(() => _isAllDay = v)),
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
                icon: Icon(Icons.access_time_rounded, color: _col),
                label: Text(_time.format(context),
                    style: TextStyle(color: _col, fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _col,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(widget.existing != null ? 'Simpan Perubahan' : 'Simpan',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _tBtn(CalendarEventType t, String label, Color c) {
    final sel = _type == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? c : c.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: sel ? Colors.white : c)),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
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
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _col, width: 1.5)),
        ),
      );

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(CalendarEvent(
      id: widget.existing?.id ?? 'ev_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: widget.selectedDate,
      type: _type,
      color: _col,
      isAllDay: _isAllDay,
      time: _isAllDay ? null : _time,
    ));
    if (mounted) setState(() => _saving = false);
  }
}
