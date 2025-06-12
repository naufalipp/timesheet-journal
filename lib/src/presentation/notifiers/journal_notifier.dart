// journal_notifier.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart'; // For Excel, Sheet, TextCellValue, etc.
import 'package:file_saver/file_saver.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/journal_entry.dart'; // Your JournalEntry model
import '../../domain/repositories/journal_repository.dart'; // You still have _repository for other things
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

    Future<void> updateEntry(JournalEntry entry, String newContent) async {
    // Update the content of the passed entry object
    entry.content = newContent;
    // The repository will now call .save() on this modified object
    await _repository.editEntry(entry);
    await loadEntries(); // Reload to reflect the changes.
  }

  Future<void> deleteJournalEntry(JournalEntry entryToDelete) async {
    final key = await _repository.getKeyForEntry(entryToDelete);

    if (key != null) {
      await _repository.deleteEntry(key);
      await loadEntries(); // Reload to reflect the deletion
    } else {
      debugPrint(
          'Error: Could not find key for entry to delete: ${entryToDelete.content}');
    }
  }

  Future<void> exportToCsv(List<JournalEntry> monthEntries,
      DateTime selectedMonth, BuildContext context) async {
    try {
      // --- Step 1: Your data preparation logic remains the same ---
      final daysInMonth =
          DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      final Map<String, List<JournalEntry>> entryMap = {};
      for (var entry in monthEntries) {
        final dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
        entryMap.putIfAbsent(dateKey, () => []).add(entry);
      }
      List<List<String>> rows = [
        ['Date', 'Day', 'Title', 'Content']
      ];
      for (int day = 1; day <= daysInMonth; day++) {
        // ... (the rest of your CSV creation loop is perfect and stays here)
        final currentDate =
            DateTime(selectedMonth.year, selectedMonth.month, day);
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        final entries = entryMap[dateKey];
        if (entries != null && entries.isNotEmpty) {
          final mergedContent = entries.map((e) => e.content).join('; ');
          rows.add([
            DateFormat('dd-MM-yyyy').format(currentDate),
            DateFormat('EEEE').format(currentDate),
            '',
            mergedContent
          ]);
        } else {
          rows.add([
            DateFormat('dd-MM-yyyy').format(currentDate),
            DateFormat('EEEE').format(currentDate),
            '',
            ''
          ]);
        }
      }
      String csv = const ListToCsvConverter().convert(rows);

      // --- Step 2: Save the CSV to a temporary file in the app's cache ---
      final tempDir = await getTemporaryDirectory();
      final monthNameForFile = DateFormat('MMMM_yyyy').format(selectedMonth);
      final fileName = 'JournalExport_$monthNameForFile.csv';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csv);
      debugPrint('Created temporary file at: ${tempFile.path}');

      // --- Step 3: Present the "Save As..." dialog to the user ---
      final params = SaveFileDialogParams(sourceFilePath: tempFile.path);
      final String? finalPath =
          await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        debugPrint('File successfully saved to public storage: $finalPath');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported: ${fileName}'),
              // action: SnackBarAction(
              //   label: 'Open',
              //   onPressed: () async {
              //     if (finalPath != null) {
              //       try {
              //         debugPrint('Attempting to open path: $finalPath');

              //         // THE CHANGE IS HERE: We are adding the 'type' parameter
              //         final result = await OpenFile.open(
              //           finalPath,
              //           type:
              //               "text/csv", // Explicitly tell it this is a CSV file
              //         );

              //         debugPrint(
              //             'OpenFile result: ${result.type} ${result.message}');

              //         // Add a check here for the error message
              //         if (result.type == ResultType.fileNotFound) {
              //           if (context.mounted) {
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               SnackBar(
              //                   content: Text(
              //                       'Error: File not found. The path may be invalid.')),
              //             );
              //           }
              //         } else if (result.type == ResultType.noAppToOpen) {
              //           if (context.mounted) {
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               SnackBar(
              //                   content: Text(
              //                       'Error: No application found to open CSV files.')),
              //             );
              //           }
              //         }
              //       } catch (e) {
              //         debugPrint('Error opening file: $e');
              //         if (context.mounted) {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             SnackBar(content: Text('Could not open file: $e')),
              //           );
              //         }
              //       }
              //     }
              //   },
              // ),
            ),
          );
        }
      }
    } catch (e, s) {
      debugPrint('Export failed. Error: $e');
      debugPrint('Stack trace: $s');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
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
