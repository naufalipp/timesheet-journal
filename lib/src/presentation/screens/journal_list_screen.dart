import 'dart:typed_data'; // Keep if you need it for something else, else remove
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:file_saver/file_saver.dart'; // Not directly used here
// import 'package:excel/excel.dart'; // Not directly used here

import '../providers/journal_provider.dart';
import '../../domain/entities/journal_entry.dart'; // For type usage

class JournalListScreen extends ConsumerWidget {
  final DateTime selectedDate; // Renamed from selectedDay for clarity
  final TextEditingController _contentController = TextEditingController();

  JournalListScreen({required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the whole state if you need selectedMonth for filtering title
    final journalState = ref.watch(journalProvider);
    final journalNotifier = ref.read(journalProvider.notifier);

    // Filter entries for the specific selectedDate
    final dayEntries = journalState.entries
        .where((entry) => isSameDay(entry.date, selectedDate))
        .toList();
    // If you want to show all entries for the month of selectedDate:
    // final monthEntries = journalState.entries
    //     .where((entry) =>
    //         entry.date.year == selectedDate.year &&
    //         entry.date.month == selectedDate.month)
    //     .toList()
    //   ..sort((a, b) => b.date.compareTo(a.date)); // Sort descending by date

    return Scaffold(
      appBar: AppBar(
        title: Text('Entries for ${DateFormat('MMMM d, yyyy').format(selectedDate)}'),
        actions: [
          Tooltip(
            message: "Export entries for ${DateFormat('MMMM yyyy').format(journalState.selectedMonth)}",
            child: ElevatedButton.icon(
              icon: Icon(Icons.download, size: 18),
              label: Text('Export Month'),
              onPressed: () async {
                // No arguments needed for notifier's exportToExcel
                final String? filePath = await journalNotifier.exportToExcel();

                if (context.mounted) {
                  if (filePath != null && filePath.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported month to: $filePath')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed, was cancelled, or no entries to export.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ).copyWith(
                elevation: MaterialStateProperty.all(0), // flat button style
              ),
            ),
          ),
          SizedBox(width: 8), // Some spacing
        ],
      ),
      body: Column(
        children: [
          // Removed the month navigation and day headers from here,
          // as this screen is now focused on a single day's entries.
          // CalendarScreen handles month navigation.
          if (dayEntries.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No entries for this day.\nAdd one below!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dayEntries.length,
                itemBuilder: (context, index) {
                  final entry = dayEntries[index]; // Use dayEntries
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), // Increased padding
                      child: Column( // Changed to Column for better text layout
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(entry.date), // Show time of entry
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            entry.content,
                            style: TextStyle(fontSize: 15),
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
          if (journalNotifier.isFutureDate(selectedDate)) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cannot add entries for a future date.')),
              );
            return;
          }
          _contentController.clear(); // Clear previous text
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Add Entry for ${DateFormat('MMMM d, yyyy').format(selectedDate)}'),
              content: TextField(
                controller: _contentController,
                decoration: InputDecoration(hintText: 'Enter your journal thoughts...'),
                maxLines: 5,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () {
                    if (_contentController.text.isNotEmpty) {
                      // For an entry made on selectedDate, time would be 'now' or a fixed time.
                      // If you want to preserve the exact time of addition:
                      final entryTime = DateTime.now();
                      final entryDateWithTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        entryTime.hour,
                        entryTime.minute,
                        entryTime.second,
                      );

                      journalNotifier.addEntry(
                        JournalEntry(
                          date: entryDateWithTime, // Use the selectedDate with current time
                          content: _contentController.text,
                        ),
                      );
                      _contentController.clear();
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add new journal entry',
      ),
    );
  }
}