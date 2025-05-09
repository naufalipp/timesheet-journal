import 'package:hive/hive.dart';

// It's common to generate this part using build_runner
// part 'journal_entry.g.dart'; // If you were using build_runner for Hive type adapters

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String content;

  JournalEntry({required this.date, required this.content});

  // toJson might be useful for other purposes (e.g., remote sync)
  // but is not strictly part of the domain entity if it's purely for data layer.
  // Keeping it here is fine for simplicity in this case.
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'content': content,
      };
}