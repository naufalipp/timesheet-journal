import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'; // If you kept this
import 'dart:io'; // For Platform.isAndroid

import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_data_source.dart';

class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource dataSource;

  JournalRepositoryImpl(this.dataSource);

  @override
  Future<void> addEntry(JournalEntry entry) async {
    await dataSource.addEntry(entry);
  }

  @override
  Future<List<JournalEntry>> getEntries() async {
    return await dataSource.getEntries();
  }

  @override
  Future<void> deleteEntry(dynamic key) async {
    await dataSource.deleteEntry(key);
  }

  @override
  Future<dynamic> getKeyForEntry(JournalEntry entry) async {
    // The repository's job is to simply delegate this request to the data source.
    // The actual logic of finding the Hive key resides in the dataSource.
    return await dataSource.getKeyForEntry(entry);
  }
  
  @override
  Future<String?> exportToExcel(List<JournalEntry> entries, String month) async {
    var excel = Excel.createExcel();
    var sheet = excel['Journal'];

    sheet.cell(CellIndex.indexByString("A1")).value = TextCellValue("Date");
    sheet.cell(CellIndex.indexByString("B1")).value = TextCellValue("Journal Note");

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = i + 2;
      sheet.cell(CellIndex.indexByString("A$row")).value =
          TextCellValue(DateFormat('yyyy-MM-dd').format(entry.date));
      sheet.cell(CellIndex.indexByString("B$row")).value = TextCellValue(entry.content);
    }

    final fileBytes = excel.encode();

    if (fileBytes != null) {
      String fileName = 'Journal_$month.xlsx';
      print("[Repository] Attempting to save file: $fileName with ${fileBytes.length} bytes.");

      // --- Optional: Enhanced Permission Handling (keep if you added it) ---
      if (Platform.isAndroid) { // Check if running on Android
        PermissionStatus status = await Permission.storage.request();
        if (!status.isGranted) {
          print("[Repository] Storage permission was denied. Status: $status");
          if (status.isPermanentlyDenied) {
            // Consider guiding user to settings: openAppSettings();
             print("[Repository] Storage permission permanently denied. User needs to go to settings.");
          }
          return null; // Can't save without permission
        }
        print("[Repository] Storage permission is granted. Status: $status");
      }
      // --- End Optional Permission Handling ---

      try {
        String? savedPath = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          // MimeType.OPEN_XML_SPREADSHEET is generally more accurate for .xlsx
          mimeType: MimeType.microsoftExcel,
        );
        print("[Repository] FileSaver.instance.saveFile returned path: $savedPath");
        return savedPath;
      } catch (e, s) {
        print("[Repository] Error occurred directly within FileSaver.instance.saveFile or its call:");
        print("[Repository] Exception: $e");
        print("[Repository] Stack Trace: $s");
        return null;
      }
    } else {
      print("[Repository] Failed to encode Excel file (fileBytes is null).");
      return null;
    }
  }
  
  
}