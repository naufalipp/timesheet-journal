import '../entities/journal_entry.dart';

abstract class JournalRepository {
  Future<void> addEntry(JournalEntry entry);
  Future<void> editEntry(JournalEntry entry);
  Future<void> deleteEntry(dynamic key);
  Future<dynamic> getKeyForEntry(JournalEntry entry);
  Future<List<JournalEntry>> getEntries();
  // Future<String?> exportToExcel(List<JournalEntry> entries, String month);
}