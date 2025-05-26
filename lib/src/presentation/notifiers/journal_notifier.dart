// journal_notifier.dart

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart'; // For Excel, Sheet, TextCellValue, etc.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
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

  Future<String?> exportToCsv(List<JournalEntry> monthEntries,
      String monthNameForFile, BuildContext context) async {
    if (monthNameForFile.isEmpty) {
      debugPrint("Notifier.exportToCsv: Invalid monthNameForFile provided.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid month name for export.')),
        );
      }
      return null;
    }

    try {
      // Parse the month and year from monthNameForFile (format: MMMM_yyyy, e.g., May_2025)
      final dateFormat = DateFormat('MMMM_yyyy');
      DateTime monthDate;
      try {
        monthDate = dateFormat.parse(monthNameForFile);
      } catch (e) {
        debugPrint(
            'Notifier.exportToCsv: Invalid monthNameForFile format: $monthNameForFile');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid month format. Expected: May_2025')),
          );
        }
        return null;
      }

      // Get the number of days in the month
      final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      // Group entries by date (yyyy-MM-dd) and collect content
      final Map<String, List<JournalEntry>> entryMap = {};
      for (var entry in monthEntries) {
        if (entry.date == null || entry.content == null) {
          debugPrint(
              'Notifier.exportToCsv: Invalid entry - date or content is null: $entry');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid journal entry data.')),
            );
          }
          return null;
        }
        final dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
        entryMap.putIfAbsent(dateKey, () => []).add(entry);
      }

      // Create CSV data
      List<List<String>> rows = [
        ['Date', 'Day', 'Title', 'Content'], // Headers
      ];

      // Add a row for every day in the month
      for (int day = 1; day <= daysInMonth; day++) {
        final currentDate = DateTime(monthDate.year, monthDate.month, day);
        final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
        final entries = entryMap[dateKey];

        if (entries != null && entries.isNotEmpty) {
          // Merge content for all entries on this date
          final mergedContent =
              entries.map((e) => e.content).join(', - '); // Use ; as delimiter
          rows.add([
            DateFormat('dd-MM-yyyy').format(currentDate),
            DateFormat('EEEE').format(currentDate),
            '',
            mergedContent,
          ]);
        } else {
          // No entry for this date, add a row with empty content
          rows.add([
            DateFormat('dd-MM-yyyy').format(currentDate),
            DateFormat('EEEE').format(currentDate),
            '',
            '',
          ]);
        }
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);
      List<int> bytes = utf8.encode(csv);
      debugPrint('Notifier.exportToCsv: Generated ${bytes.length} bytes.');

      // Generate file name
      String suggestedFileName =
          'JournalExport_${monthNameForFile.replaceAll(RegExp(r'[^\w\s-]'), '')}.csv';

      // Try to save to public Downloads folder
      String outputFile = '/storage/emulated/0/Download/$suggestedFileName';
      Directory? fallbackDirectory;

      // Check if public Downloads folder is accessible
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          debugPrint(
              'Notifier.exportToCsv: Public Downloads directory does not exist.');
          throw Exception('Public Downloads directory not found');
        }
      } catch (e) {
        debugPrint(
            'Notifier.exportToCsv: Error accessing public Downloads directory: $e');
        // Fallback to app's documents directory
        fallbackDirectory = await getApplicationDocumentsDirectory();
        outputFile = '${fallbackDirectory.path}/$suggestedFileName';
      }

      // Ensure unique file name to avoid overwriting
      int counter = 1;
      String basePath =
          outputFile.substring(0, outputFile.length - '.csv'.length);
      while (await File(outputFile).exists()) {
        outputFile = '${basePath}_$counter.csv';
        counter++;
      }

      final File file = File(outputFile);
      await file.writeAsBytes(bytes, flush: true);

      debugPrint('Notifier.exportToCsv: Exported successfully to: $outputFile');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to Downloads: $suggestedFileName'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final result = await OpenFile.open(outputFile);
                if (result.type != ResultType.done && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to open file: ${result.message}')),
                  );
                }
              },
            ),
          ),
        );
      }
      return outputFile;
    } catch (e, s) {
      debugPrint('Notifier.exportToCsv: Error: $e');
      debugPrint('Notifier.exportToCsv: Stack trace: $s');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
      return null;
    }
  }

  // Future<String?> exportToCsv(List<JournalEntry> monthEntries,
  //     String monthNameForFile, BuildContext context) async {
  //   if (monthEntries.isEmpty) {
  //     debugPrint("Notifier.exportToCsv: No entries received to export.");
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No entries to export.')),
  //       );
  //     }
  //     return null;
  //   }

  //   try {
  //     // Validate monthEntries data
  //     for (var entry in monthEntries) {
  //       if (entry.date == null || entry.content == null) {
  //         debugPrint(
  //             'Notifier.exportToCsv: Invalid entry - date or content is null: $entry');
  //         if (context.mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Invalid journal entry data.')),
  //           );
  //         }
  //         return null;
  //       }
  //     }

  //     // Create CSV data
  //     List<List<String>> rows = [
  //       ['Date', 'Title', 'Content'], // Headers
  //     ];

  //     for (var entry in monthEntries) {
  //       rows.add([
  //         DateFormat('yyyy-MM-dd HH:mm').format(entry.date),
  //         '',
  //         entry.content,
  //       ]);
  //     }

  //     String csv = const ListToCsvConverter().convert(rows);
  //     List<int> bytes = utf8.encode(csv);
  //     debugPrint('Notifier.exportToCsv: Generated ${bytes.length} bytes.');

  //     String suggestedFileName =
  //         'JournalExport_${monthNameForFile.replaceAll(RegExp(r'[^\w\s-]'), '')}.csv';

  //     // Try to save to public Downloads folder
  //     String outputFile = '/storage/emulated/0/Download/$suggestedFileName';
  //     Directory? fallbackDirectory;

  //     // Check if public Downloads folder is accessible
  //     try {
  //       final downloadsDir = Directory('/storage/emulated/0/Download');
  //       if (!await downloadsDir.exists()) {
  //         debugPrint(
  //             'Notifier.exportToCsv: Public Downloads directory does not exist.');
  //         throw Exception('Public Downloads directory not found');
  //       }
  //     } catch (e) {
  //       debugPrint(
  //           'Notifier.exportToCsv: Error accessing public Downloads directory: $e');
  //       // Fallback to app's documents directory
  //       fallbackDirectory = await getApplicationDocumentsDirectory();
  //       outputFile = '${fallbackDirectory.path}/$suggestedFileName';
  //     }

  //     // Ensure unique file name to avoid overwriting
  //     int counter = 1;
  //     String basePath =
  //         outputFile.substring(0, outputFile.length - '.csv'.length);
  //     while (await File(outputFile).exists()) {
  //       outputFile = '{$basePath}_$counter.csv';
  //       counter++;
  //     }

  //     final File file = File(outputFile);
  //     await file.writeAsBytes(bytes, flush: true);

  //     debugPrint('Notifier.exportToCsv: Exported successfully to: $outputFile');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Exported to Downloads: $suggestedFileName'),
  //           action: SnackBarAction(
  //             label: 'Open',
  //             onPressed: () async {
  //               final result = await OpenFile.open(outputFile);
  //               if (result.type != ResultType.done && context.mounted) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(
  //                       content:
  //                           Text('Failed to open file: ${result.message}')),
  //                 );
  //               }
  //             },
  //           ),
  //         ),
  //       );
  //     }
  //     return outputFile;
  //   } catch (e, s) {
  //     debugPrint('Notifier.exportToCsv: Error: $e');
  //     debugPrint('Notifier.exportToCsv: Stack trace: $s');
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Export failed: $e')),
  //       );
  //     }
  //     return null;
  //   }
  // }

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
