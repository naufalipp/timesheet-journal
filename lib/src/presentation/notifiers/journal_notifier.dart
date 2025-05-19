// journal_notifier.dart

import 'dart:io';
import 'package:excel/excel.dart'; // For Excel, Sheet, TextCellValue, etc.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/journal_entry.dart'; // Your JournalEntry model
import '../../domain/repositories/jorunal_repository.dart'; // You still have _repository for other things
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
    state = state.copyWith(entries: entries);
  }

  Future<void> addEntry(JournalEntry entry) async {
    if (!isFutureDate(entry.date)) {
      await _repository.addEntry(entry);
      await loadEntries();
    }
  }

  // This exportToExcel method is now part of JournalNotifier
  // It takes monthEntries and monthNameForFile as parameters.
  Future<String?> exportToExcel(
      List<JournalEntry> monthEntries, String monthNameForFile) async {
    if (monthEntries.isEmpty) {
      // This check is good, even if also done by the caller.
      debugPrint("Notifier.exportToExcel: No entries received to export.");
      return null;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Journal Entries for $monthNameForFile'];

      // Add headers - Wrap each string in TextCellValue
      sheetObject.appendRow([
        TextCellValue('Date'), // MODIFIED
        TextCellValue('Title'), // MODIFIED
        TextCellValue('Content'), // MODIFIED
      ]);

      // Add data rows
      for (var entry in monthEntries) {
        // Choose one way to handle dates:
        // Option 1: As a formatted string (will be text in Excel)
        TextCellValue cellDateFormatted =
            TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(entry.date));

        // Option 2: As a native Excel DateTime value (allows date functions in Excel)
        // DateTimeCellValue cellDateNative = DateTimeCellValue.fromDateTime(entry.date);

        sheetObject.appendRow([
          cellDateFormatted, // MODIFIED (use this for formatted string)
          // cellDateNative,            // OR use this for native Excel DateTime
          TextCellValue("="), // MODIFIED
          TextCellValue(entry.content), // MODIFIED
        ]);
      }

      final List<int>? fileBytes = excel.save(fileName: "temp_export.xlsx");

      if (fileBytes == null) {
        debugPrint('Notifier.exportToExcel: Error generating Excel bytes.');
        return null;
      }

      String suggestedFileName = 'JournalExport_$monthNameForFile.xlsx';
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Journal Export',
        fileName: suggestedFileName,
      );

      if (outputFile == null) {
        debugPrint(
            'Notifier.exportToExcel: User cancelled the save file dialog.');
        return null;
      }

      final File file = File(outputFile);
      await file.writeAsBytes(fileBytes, flush: true);

      debugPrint(
          'Notifier.exportToExcel: Exported successfully to: $outputFile');
      return outputFile;
    } catch (e, s) {
      debugPrint('Notifier.exportToExcel: Error: $e');
      debugPrint('Notifier.exportToExcel: Stack trace: $s');
      return null;
    }
  }

  void updateSelectedMonth(DateTime newMonth) {
    // ... your existing code ...
    state = state.copyWith(selectedMonth: newMonth);
  }

  void updateActuallySelectedDay(DateTime? newSelectedDay) {
    state = state.copyWith(actuallySelectedDay: newSelectedDay);
  }

  bool isFutureDate(DateTime date) {
    // ... your existing code ...
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    return inputDate.isAfter(today);
  }

  bool isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}
