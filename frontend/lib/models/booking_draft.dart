/// Data reservasi yang sedang disusun (dibawa ke halaman menu dan checkout)
class BookingDraft {
  final Map<String, dynamic> table;
  final DateTime date;
  final String time; // format HH:MM
  final int guests;
  final String notes;

  const BookingDraft({
    required this.table,
    required this.date,
    required this.time,
    required this.guests,
    this.notes = '',
  });

  String get dateKey => dateKeyOf(date);

  String get label =>
      '${dayShort(date)}, ${date.day} ${monthShort(date)} · ${time.replaceAll(':', '.')} · $guests tamu';
}

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String dayShort(DateTime d) => _days[d.weekday - 1];
String monthShort(DateTime d) => _months[d.month - 1];

String dateKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';