// lib/screens/admin/admin_global_events_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../services/calendar_service.dart';
import '../../utils/app_theme.dart';

class AdminGlobalEventsScreen extends StatefulWidget {
  const AdminGlobalEventsScreen({super.key});

  @override
  State<AdminGlobalEventsScreen> createState() =>
      _AdminGlobalEventsScreenState();
}

class _AdminGlobalEventsScreenState extends State<AdminGlobalEventsScreen> {
  final _db = FirebaseFirestore.instance;

  Stream<List<CalendarEvent>> _stream() {
    return _db
        .collection('global_events')
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
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
                id: d.id,
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
            }).toList());
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Event?'),
        content:
            const Text('Event ini akan dihapus dari semua tampilan siswa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await CalendarService.instance.deleteGlobalEvent(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event dihapus'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showForm({CalendarEvent? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GlobalEventForm(
        existing: existing,
        onSave: (ev) async {
          if (existing != null) {
            // ✅ PERBAIKAN: Gunakan CalendarService untuk update
            await CalendarService.instance.updateGlobalEvent(ev);
          } else {
            // ✅ SUDAH BENAR: Gunakan CalendarService untuk create
            await CalendarService.instance.addGlobalEvent(ev);
          }
          if (mounted) Navigator.pop(context);
          setState(() {}); // Refresh UI
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header (sama seperti sebelumnya)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C6FF7), Color(0xFF9B8FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Global Events',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('Tampil di kalender semua siswa',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7C6FF7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<CalendarEvent>>(
              stream: _stream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF7C6FF7)));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final events = snap.data ?? [];
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 52)),
                        const SizedBox(height: 12),
                        Text('Belum ada global event',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('Tap "Tambah" untuk membuat event baru',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EventCard(
                    event: events[i],
                    onEdit: () => _showForm(existing: events[i]),
                    onDelete: () => _delete(events[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EVENT CARD (SAMA, TIDAK BERUBAH)
// ─────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard(
      {required this.event, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = event.color;
    final dateStr = DateFormat('EEE, d MMM yyyy', 'id_ID').format(event.date);
    final timeStr =
        event.isAllDay ? 'Seharian' : event.time?.format(context) ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                event.type == CalendarEventType.note ? '🔵' : '📅',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF2D2D2D))),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(dateStr,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(timeStr,
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  if (event.description != null) ...[
                    const SizedBox(height: 3),
                    Text(event.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: Color(0xFF7C6FF7)),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: Colors.red.shade400),
                onPressed: onDelete,
                tooltip: 'Hapus',
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FORM BOTTOM SHEET (SAMA, TIDAK BERUBAH)
// ─────────────────────────────────────────────

class _GlobalEventForm extends StatefulWidget {
  final CalendarEvent? existing;
  final Future<void> Function(CalendarEvent) onSave;

  const _GlobalEventForm({required this.onSave, this.existing});

  @override
  State<_GlobalEventForm> createState() => _GlobalEventFormState();
}

class _GlobalEventFormState extends State<_GlobalEventForm> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _date;
  late CalendarEventType _type;
  late bool _isAllDay;
  late TimeOfDay _time;
  late Color _color;
  bool _saving = false;

  final List<Color> _colorOptions = const [
    Color(0xFF7C6FF7),
    Color(0xFFFF6B6B),
    Color(0xFF3BCEAC),
    Color(0xFFFFB347),
    Color(0xFF4FC3F7),
    Color(0xFFBA68C8),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _date = e?.date ?? DateTime.now();
    _type = e?.type ?? CalendarEventType.event;
    _isAllDay = e?.isAllDay ?? true;
    _time = e?.time ?? TimeOfDay.now();
    _color = e?.color ?? const Color(0xFF7C6FF7);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF7C6FF7)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(CalendarEvent(
      id: widget.existing?.id ?? 'gev_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: _date,
      type: _type,
      color: _color,
      isAllDay: _isAllDay,
      time: _isAllDay ? null : _time,
      isGlobal: true,
    ));
    if (mounted) setState(() => _saving = false);
  }

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
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.existing != null ? 'Edit Global Event' : 'Buat Global Event',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 4),
          Text(
            'Akan tampil di kalender semua siswa',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _tBtn(CalendarEventType.event, '📅 Event', const Color(0xFF7C6FF7)),
            const SizedBox(width: 8),
            _tBtn(
                CalendarEventType.note, '🔵 Catatan', const Color(0xFF3BCEAC)),
          ]),
          const SizedBox(height: 14),
          _field(_titleCtrl, 'Judul event...'),
          const SizedBox(height: 10),
          _field(_descCtrl, 'Deskripsi (opsional)...', maxLines: 2),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: Color(0xFF7C6FF7)),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_date),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Switch(
                value: _isAllDay,
                activeColor: _color,
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
                  icon: Icon(Icons.access_time_rounded, color: _color),
                  label: Text(_time.format(context),
                      style: TextStyle(
                          color: _color, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Text('Warna:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(width: 12),
            ..._colorOptions.map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _color == c
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _color == c
                          ? [
                              BoxShadow(
                                  color: c.withOpacity(0.5), blurRadius: 6)
                            ]
                          : null,
                    ),
                  ),
                )),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
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
                  : Text(
                      widget.existing != null
                          ? 'Simpan Perubahan'
                          : 'Buat Event',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ]),
      ),
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
              borderSide: BorderSide(color: _color, width: 1.5)),
        ),
      );
}
