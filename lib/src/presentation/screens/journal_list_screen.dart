import 'dart:typed_data'; // Keep if you need it for something else, else remove
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; 

import '../providers/journal_provider.dart'; // Assuming this path is correct
import '../../domain/entities/journal_entry.dart'; // For type usage

void showJournalDialog({
  required BuildContext context,
  required DateTime selectedDate,
  required TextEditingController contentController,
  required VoidCallback onSavePressed,
}) {
  final BorderRadius dialogBorderRadius = BorderRadius.circular(20.0);
  final Color primaryColor = Theme.of(context).colorScheme.primary;
  final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
  final Color subtleBorderColor = Colors.grey.shade300;
  final Color textFieldFillColor =
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade100;
  final Color hintTextColor = Colors.grey.shade500;
  final Color dialogBackgroundColor = Theme.of(context).cardColor;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: dialogBorderRadius),
        backgroundColor: dialogBackgroundColor,
        elevation: 8.0,
        titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        actionsPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 20.0),
        title: Text(
          'New Entry: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 19.0,
            color: primaryColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  hintText: 'Add your journal for this day',
                  hintStyle: TextStyle(color: hintTextColor, fontSize: 15.0),
                  filled: true,
                  fillColor: textFieldFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide:
                        BorderSide(color: subtleBorderColor, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                ),
                maxLines: 5,
                autofocus: true,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500)),
            onPressed: () {
              Navigator.pop(dialogContext);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: onPrimaryColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 3.0,
            ),
            child: const Text('Save Entry',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600)),
            onPressed:
                onSavePressed, // This will now call the logic defined in the FAB's onPressed
          ),
        ],
      );
    },
  );
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// End of Dialog Definition
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

class JournalListScreen extends ConsumerWidget {
  final DateTime selectedDate;
  final TextEditingController _contentController = TextEditingController();

  JournalListScreen({super.key, required this.selectedDate}); // Added super.key

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final journalNotifier = ref.read(journalProvider.notifier);

    final dayEntries = journalState.entries
        .where((entry) => isSameDay(entry.date, selectedDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by time, recent first

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Entries for ${DateFormat('MMMM d,<y_bin_398>').format(selectedDate)}'),
        actions: [
          Tooltip(
            message:
                "Export entries for ${DateFormat('MMMM<y_bin_398>').format(journalState.selectedMonth)}",
            child: ElevatedButton.icon(
                icon: Icon(Icons.download, size: 18),
                label: Text('Export Month'),
                onPressed: () async {
                  final String? filePath =
                      await journalNotifier.exportToExcel();

                  if (context.mounted) {
                    if (filePath != null && filePath.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exported month to: $filePath')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Export failed, was cancelled, or no entries to export.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  // Consider using TextButton for a flatter look if desired, or style ElevatedButton
                  // foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  // backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation:
                      0, // For a flatter style if preferred for appbar actions
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ) //.copyWith( // .copyWith can be tricky with styleFrom
                // elevation: MaterialStateProperty.all(0),
                //),
                ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (dayEntries.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No entries for this day.\nTap the "+" button to add your first thought!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17, color: Colors.grey[600], height: 1.5),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 8.0), // Add padding to ListView
                itemCount: dayEntries.length,
                itemBuilder: (context, index) {
                  final entry = dayEntries[index];
                  return Card(
                    margin: EdgeInsets.symmetric(
                        vertical: 6, horizontal: 8), // Adjusted margin
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)), // Slightly more rounded
                    elevation: 3, // Consistent elevation
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Increased padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(entry.date),
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant, // Theme aware color
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 6),
                          Text(
                            entry.content,
                            style: TextStyle(
                              fontSize: 16,
                              height:
                                  1.4, // Improved line spacing for readability
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface, // Theme aware color
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
          if (journalNotifier.isFutureDate(selectedDate)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot add entries for a future date.')),
            );
            return;
          }
          _contentController.clear();

          // Define the save logic that will be passed to the aesthetic dialog
          void handleSave() {
            if (_contentController.text.isNotEmpty) {
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
                  date: entryDateWithTime,
                  content: _contentController.text,
                ),
              );
              _contentController.clear(); // Clear after successful save
              Navigator.pop(
                  context); // Close the dialog (context here is from FAB's scope)
            } else {
              // If content is empty, show a SnackBar.
              // The dialog will remain open for the user to enter text.
              ScaffoldMessenger.of(context).showSnackBar(
                // Use the FAB's context
                SnackBar(
                  content: Text('Please write something to save!'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }

          // Call the aesthetic dialog
          showJournalDialog(
            context: context, // This is the BuildContext from the build method
            selectedDate: selectedDate,
            contentController: _contentController,
            onSavePressed: handleSave,
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add new journal entry',
      ),
    );
  }
}
