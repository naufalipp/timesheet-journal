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

//  Future<String?> exportToExcel(List<JournalEntry> monthEntries,
//       String monthNameForFile, BuildContext context) async {
//     if (monthEntries.isEmpty) {
//       debugPrint("Notifier.exportToExcel: No entries received to export.");
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No entries to export.')),
//         );
//       }
//       return null;
//     }

//     try {
//       // Validate monthEntries data
//       for (var entry in monthEntries) {
//         if (entry.date == null || entry.content == null) {
//           debugPrint(
//               'Notifier.exportToExcel: Invalid entry - date or content is null: $entry');
//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Invalid journal entry data.')),
//             );
//           }
//           return null;
//         }
//       }

//       var excel = Excel.createExcel();
//       Sheet sheetObject = excel['Journal Entries for $monthNameForFile'];

//       // Add headers
//       sheetObject.appendRow([
//          TextCellValue('Date'),
//          TextCellValue('Title'),
//          TextCellValue('Content'),
//       ]);

//       // Add data rows
//       for (var entry in monthEntries) {
//         TextCellValue cellDateFormatted =
//             TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(entry.date));
//         sheetObject.appendRow([
//           cellDateFormatted,
//           TextCellValue(''),
//           TextCellValue(entry.content),
//         ]);
//       }

//       // Save Excel file (remove fileName parameter for Android/iOS)
//       final List<int>? fileBytes = excel.save();
//       if (fileBytes == null || fileBytes.isEmpty) {
//         debugPrint(
//             'Notifier.exportToExcel: Failed to generate Excel bytes. Bytes are null or empty.');
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to generate Excel file.')),
//           );
//         }
//         return null;
//       }
//       debugPrint(
//           'Notifier.exportToExcel: Generated ${fileBytes.length} bytes.');

//       String suggestedFileName =
//           'JournalExport_${monthNameForFile.replaceAll(RegExp(r'[^\w\s-]'), '')}.xlsx';

//       if (kIsWeb) {
//         excel.save(fileName: suggestedFileName);
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Excel file downloaded.')),
//           );
//         }
//         return suggestedFileName;
//       }

//       // Use FilePicker to get save location
//       String? outputFile = await FilePicker.platform.saveFile(
//         dialogTitle: 'Save Journal Export',
//         fileName: suggestedFileName,
//       );

//       if (outputFile == null) {
//         debugPrint(
//             'Notifier.exportToExcel: User cancelled the save file dialog.');
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Export cancelled by user.')),
//           );
//         }
//         return null;
//       }

//       // Ensure the file path has the correct extension
//       if (!outputFile.endsWith('.xlsx')) {
//         outputFile = '$outputFile.xlsx';
//       }

//       final File file = File(outputFile);
//       await file.writeAsBytes(fileBytes, flush: true);

//       debugPrint(
//           'Notifier.exportToExcel: Exported successfully to: $outputFile');
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Exported month to: $outputFile')),
//         );
//       }
//       return outputFile;
//     } catch (e, s) {
//       debugPrint('Notifier.exportToExcel: Error: $e');
//       debugPrint('Notifier.exportToExcel: Stack trace: $s');
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Export failed: $e')),
//         );
//       }
//       return null;
//     }
//   }

  Future<String?> exportToCsv(List<JournalEntry> monthEntries,
      String monthNameForFile, BuildContext context) async {
    if (monthEntries.isEmpty) {
      debugPrint("Notifier.exportToCsv: No entries received to export.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries to export.')),
        );
      }
      return null;
    }

    try {
      // Validate monthEntries data
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
      }

      // Create CSV data
      List<List<String>> rows = [
        ['Date', 'Title', 'Content'], // Headers
      ];

      for (var entry in monthEntries) {
        rows.add([
          DateFormat('yyyy-MM-dd HH:mm').format(entry.date),
          '',
          entry.content,
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      List<int> bytes = utf8.encode(csv);
      debugPrint('Notifier.exportToCsv: Generated ${bytes.length} bytes.');

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
        outputFile = '{$basePath}_$counter.csv';
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
