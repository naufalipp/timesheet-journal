import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

// Domain Layer: Entity
@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;
  @HiveField(1)
  final String content;

  JournalEntry({required this.date, required this.content});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'content': content,
      };
}

// Domain Layer: Repository Abstract
abstract class JournalRepository {
  Future<void> addEntry(JournalEntry entry);
  Future<List<JournalEntry>> getEntries();
  // Future<String> exportToExcel(List<JournalEntry> entries, String month);
  Future<String?> exportToExcel(List<JournalEntry> entries, String month);
}

// Data Layer: Local Data Source
class JournalLocalDataSource {
  final Box<JournalEntry> box;

  JournalLocalDataSource(this.box);

  Future<void> addEntry(JournalEntry entry) async {
    await box.put(entry.date.toIso8601String(), entry);
  }

  Future<List<JournalEntry>> getEntries() async {
    return box.values.toList();
  }
}

// Data Layer: Repository Implementation
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
    try {
      // Suggest a filename
      String fileName = 'Journal_$month.xlsx';

      // Use file_saver to save the file.
      // This will typically open a save dialog or save to a common location like Downloads.
      // It handles permissions on Android and uses appropriate mechanisms for iOS (like Share Sheet or Files app integration).
      String? savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(fileBytes), // Convert List<int> to Uint8List
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel, // Or MimeType.OPEN_XML_SPREADSHEET (more modern)
      );
      
      // For more control, especially on desktop, or to let the user pick the name and location:
      // String? savedPath = await FileSaver.instance.saveAs(
      //   fileName: fileName, // Initial proposed file name
      //   bytes: Uint8List.fromList(fileBytes),
      //   ext: 'xlsx',
      //   mimeType: MimeType.MICROSOFT_EXCEL,
      // );

      return savedPath; // This path might be temporary or a direct path depending on the platform and method
    } catch (e) {
      print("Error saving file: $e");
      // Optionally, rethrow or return an error indicator
      return null;
    }
  } else {
    print("Failed to encode Excel file.");
    return null;
  }
}
}

// Presentation Layer: State and Provider
class JournalState {
  final List<JournalEntry> entries;
  final DateTime selectedMonth;

  JournalState({required this.entries, required this.selectedMonth});
}

class JournalNotifier extends StateNotifier<JournalState> {
  final JournalRepository repository;

  JournalNotifier(this.repository)
      : super(JournalState(entries: [], selectedMonth: DateTime.now())) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    final entries = await repository.getEntries();
    state = JournalState(entries: entries, selectedMonth: state.selectedMonth);
  }

  Future<void> addEntry(JournalEntry entry) async {
    if (!isFutureDate(entry.date)) {
      await repository.addEntry(entry);
      await loadEntries();
    }
  }
  @override
Future<String?> exportToExcel() async { // <<-- Takes 0 arguments
  final monthEntries = state.entries
      .where((entry) =>
          entry.date.year == state.selectedMonth.year &&
          entry.date.month == state.selectedMonth.month)
      .toList();
  final monthName = DateFormat('MMMM_yyyy').format(state.selectedMonth);

  try {
    // Calls the repository's exportToExcel WITH 2 arguments
    return await repository.exportToExcel(monthEntries, monthName);
  } catch (e) {
    print("Error in JournalNotifier.exportToExcel: $e");
    // If an error occurs calling the repository, or within it if not caught there,
    // return null to indicate failure at this level.
    return null;
  }
}


  // Future<String> exportToExcel() async {
  //   final monthEntries = state.entries
  //       .where((entry) =>
  //           entry.date.year == state.selectedMonth.year &&
  //           entry.date.month == state.selectedMonth.month)
  //       .toList();
  //   final monthName = DateFormat('MMMM_yyyy').format(state.selectedMonth);
  //   return await repository.exportToExcel(monthEntries, monthName);
  // }

  void updateSelectedMonth(DateTime newMonth) {
    state = JournalState(entries: state.entries, selectedMonth: newMonth);
  }

  bool isFutureDate(DateTime date) {
    return date.isAfter(DateTime.now());
  }
}

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final box = Hive.box<JournalEntry>('journalBox');
  return JournalRepositoryImpl(JournalLocalDataSource(box));
});

final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return JournalNotifier(repository);
});

// Main App
void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(JournalEntryAdapter());
  await Hive.openBox<JournalEntry>('journalBox');
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CalendarScreen(),
    );
  }
}

// Screen 1: Full-Screen Calendar
class CalendarScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Calendar'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: journalState.selectedMonth,
        calendarFormat: CalendarFormat.month,
        onPageChanged: (focusedDay) {
          ref.read(journalProvider.notifier).updateSelectedMonth(focusedDay);
        },
        eventLoader: (day) {
          return journalState.entries
              .where((entry) => isSameDay(entry.date, day))
              .toList();
        },
        calendarStyle: CalendarStyle(
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          ref.read(journalProvider.notifier).updateSelectedMonth(focusedDay);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JournalListScreen(selectedDay: selectedDay),
            ),
          );
        },
      ),
    );
  }
}

// Screen 2: Journal List
class JournalListScreen extends ConsumerWidget {
  final DateTime selectedDay;
  final TextEditingController _controller = TextEditingController();

  JournalListScreen({required this.selectedDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final journalNotifier = ref.read(journalProvider.notifier);

    final monthEntries = journalState.entries
        .where((entry) =>
            entry.date.year == journalState.selectedMonth.year &&
            entry.date.month == journalState.selectedMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Journal'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final filePath = await journalNotifier.exportToExcel();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exported to $filePath')),
              );
            },
            child: Text('Export to Excel'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () {
                    final newMonth = DateTime(journalState.selectedMonth.year,
                        journalState.selectedMonth.month - 1);
                    journalNotifier.updateSelectedMonth(newMonth);
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(journalState.selectedMonth),
                  style: TextStyle(fontSize: 20),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: journalState.selectedMonth.month <
                              DateTime.now().month ||
                          journalState.selectedMonth.year < DateTime.now().year
                      ? () {
                          final newMonth = DateTime(
                              journalState.selectedMonth.year,
                              journalState.selectedMonth.month + 1);
                          journalNotifier.updateSelectedMonth(newMonth);
                        }
                      : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                  Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = journalState.selectedMonth.day +
                    index -
                    (journalState.selectedMonth.weekday % 7);
                final isCurrentMonth = day > 0 &&
                    day <=
                        DateTime(journalState.selectedMonth.year,
                                journalState.selectedMonth.month + 1, 0)
                            .day;
                final isSelected = day == selectedDay.day;
                return Expanded(
                  child: CircleAvatar(
                    backgroundColor:
                        isSelected ? Colors.blue : Colors.transparent,
                    child: Text(
                      isCurrentMonth ? day.toString() : '',
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: monthEntries.length,
              itemBuilder: (context, index) {
                final entry = monthEntries[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(entry.date.day.toString()),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.content.split('\n')[0],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                entry.content.split('\n').skip(1).join('\n'),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!journalNotifier.isFutureDate(selectedDay)) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                    'Add Journal Entry for ${DateFormat('yyyy-MM-dd').format(selectedDay)}'),
                content: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: 'Enter your journal'),
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text('Save'),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        journalNotifier.addEntry(
                          JournalEntry(
                            date: selectedDay,
                            content: _controller.text,
                          ),
                        );
                        _controller.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// Hive Adapter for JournalEntry
class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 0;

  @override
  JournalEntry read(BinaryReader reader) {
    return JournalEntry(
      date: DateTime.parse(reader.readString()),
      content: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer.writeString(obj.date.toIso8601String());
    writer.writeString(obj.content);
  }
}
