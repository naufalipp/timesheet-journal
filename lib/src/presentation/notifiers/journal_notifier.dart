import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/jorunal_repository.dart';
import 'journal_state.dart';

class JournalNotifier extends StateNotifier<JournalState> {
  final JournalRepository _repository;

  JournalNotifier(this._repository)
      : super(JournalState(
          entries: [],
          selectedMonth: DateTime.now(),
          actuallySelectedDay: DateTime.now(),
        )) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    final entries = await _repository.getEntries();
    state =
        state.copyWith(entries: entries); // Using copyWith from JournalState
  }

  Future<void> addEntry(JournalEntry entry) async {
    if (!isFutureDate(entry.date)) {
      await _repository.addEntry(entry);
      // No need to call loadEntries() again if you can update state optimistically
      // or add the new entry directly to the existing list for better UX.
      // For simplicity, loadEntries() is fine.
      await loadEntries();
    }
  }

  Future<String?> exportToExcel() async {
    final monthEntries = state.entries
        .where((entry) =>
            entry.date.year == state.selectedMonth.year &&
            entry.date.month == state.selectedMonth.month)
        .toList();

    if (monthEntries.isEmpty) {
      debugPrint("No entries for the selected month to export.");
      return null; // Or throw an exception / return a specific message
    }
 
    final monthName = DateFormat('MMMM_yyyy').format(state.selectedMonth);

    try {
      return await _repository.exportToExcel(monthEntries, monthName);
    } catch (e) {
      debugPrint("Error in JournalNotifier.exportToExcel: $e");
      return null;
    }
  }

  void updateSelectedMonth(DateTime newMonth) {
    // Ensure newMonth is not in the future if that's a rule for selection
    if (newMonth.isAfter(DateTime.now()) &&
        !isSameMonth(newMonth, DateTime.now())) {
      // Optionally prevent selecting future months or cap at current month
      // For now, allowing it as per original logic in CalendarScreen's lastDay
      state = state.copyWith(selectedMonth: newMonth);
    } else {
      state = state.copyWith(selectedMonth: newMonth);
    }
    // If entries are month-specific and not all loaded at once, you might reload here.
    // But your current loadEntries fetches all.
  }

  void updateActuallySelectedDay(DateTime? newSelectedDay) {
    state = state.copyWith(actuallySelectedDay: newSelectedDay);
  }

  bool isFutureDate(DateTime date) {
    // Compare only the date part, ignoring time, if you want to allow today.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    return inputDate.isAfter(today);
  }

  // Helper to check if two DateTime objects are in the same month and year
  bool isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}
