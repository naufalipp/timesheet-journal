import '../../domain/entities/journal_entry.dart';

class JournalState {
  final List<JournalEntry> entries;
  final DateTime selectedMonth; // To keep track of the currently viewed month in the calendar

  JournalState({required this.entries, required this.selectedMonth});

  // Optional: copyWith method for easier state updates if state becomes more complex
  JournalState copyWith({
    List<JournalEntry>? entries,
    DateTime? selectedMonth,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}