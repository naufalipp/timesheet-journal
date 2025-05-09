import 'package:hive/hive.dart';
import '../../domain/entities/journal_entry.dart';

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 0;

  @override
  JournalEntry read(BinaryReader reader) {
    // Read fields in the order they were written
    final dateString = reader.readString();
    final content = reader.readString();
    return JournalEntry(
      date: DateTime.parse(dateString),
      content: content,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeString(obj.date.toIso8601String());
    writer.writeString(obj.content);
  }
}