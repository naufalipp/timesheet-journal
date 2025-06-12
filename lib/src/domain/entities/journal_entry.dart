import 'package:hive/hive.dart';

// It's common to generate this part using build_runner
// part 'journal_entry.g.dart'; // If you were using build_runner for Hive type adapters


@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String content; // Removed 'final' and 'late' to make it mutable

  JournalEntry({required this.date, required this.content});
}
