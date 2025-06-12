import 'package:hive/hive.dart';
import '../../domain/entities/journal_entry.dart';

class JournalLocalDataSource {
  final Box<JournalEntry> box;

  JournalLocalDataSource(this.box);

  Future<void> addEntry(JournalEntry entry) async {
    // Using date as string key; ensure uniqueness or consider auto-incrementing keys if needed
    await box.put(entry.date.toIso8601String(), entry);
  }

  Future<void>editEntry(JournalEntry entry) async {
    // Using date as string key; ensure uniqueness or consider auto-incrementing keys if needed
    await entry.save();
  }

  Future<void> deleteEntry(dynamic key) async {
    await box.delete(key);
  }

  Future<List<JournalEntry>> getEntries() async {
    return box.values.toList();
  }

  Future<dynamic> getKeyForEntry(JournalEntry entry) async {
    return entry.date.toIso8601String();
  }
}
