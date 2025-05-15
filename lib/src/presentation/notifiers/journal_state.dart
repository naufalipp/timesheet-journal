import '../../domain/entities/journal_entry.dart';

class JournalState {
  final List<JournalEntry> entries;
  final DateTime
      selectedMonth; // To keep track of the currently viewed month in the calendar
  final DateTime? actuallySelectedDay;

  JournalState(
      {required this.entries,
      required this.selectedMonth,
      this.actuallySelectedDay});

  // Optional: copyWith method for easier state updates if state becomes more complex
  JournalState copyWith({
    List<JournalEntry>? entries,
    DateTime? selectedMonth,
    DateTime? actuallySelectedDay,
    bool forceActuallySelectedDayToNull = false,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      actuallySelectedDay: forceActuallySelectedDayToNull
          ? null
          : (actuallySelectedDay ?? this.actuallySelectedDay),
    );
  }
}
