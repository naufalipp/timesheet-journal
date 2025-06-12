// Keep if you need it for something else, else remove
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timesheet_journal/src/presentation/notifiers/journal_notifier.dart';

import '../providers/journal_provider.dart'; // Assuming this path is correct
import '../../domain/entities/journal_entry.dart'; // For type usage

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A versatile dialog for both adding and editing journal entries, using your provided UI.
void showJournalDialog({
  required BuildContext context,
  required JournalNotifier journalNotifier,
  required DateTime selectedDate,
  JournalEntry? entry, // If entry is provided, we are in "edit" mode
}) {
  final isEditing = entry != null;
  final _contentController =
      TextEditingController(text: isEditing ? entry.content : '');

  void handleSave() {
    if (_contentController.text.isNotEmpty) {
      if (isEditing) {
        // Call update logic
        journalNotifier.updateEntry(entry!, _contentController.text);
      } else {
        // Call add logic
        final entryTime = DateTime.now();
        final entryDateWithTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            entryTime.hour,
            entryTime.minute,
            entryTime.second);
        journalNotifier.addEntry(JournalEntry(
            date: entryDateWithTime, content: _contentController.text));
      }
      Navigator.pop(context); // Close the dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please write something to save!'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  // Using the UI from your JournalListScreen
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
          isEditing
              ? 'Edit Entry'
              : 'New Entry: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 19.0, color: primaryColor),
        ),
        content: TextField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: 'Add your journal for this day',
            hintStyle: TextStyle(color: hintTextColor, fontSize: 15.0),
            filled: true,
            fillColor: textFieldFillColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: subtleBorderColor, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: primaryColor, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          ),
          maxLines: 5,
          autofocus: true,
          style: TextStyle(
              fontSize: 16.0,
              color: Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.black87),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: Colors.grey.shade400, width: 1)),
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500)),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: onPrimaryColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              elevation: 3.0,
            ),
            child: Text(isEditing ? 'Save Changes' : 'Save Entry',
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600)),
            onPressed: handleSave,
          ),
        ],
      );
    },
  );
}

void _showDeleteDialog(
    BuildContext context, JournalEntry entry, JournalNotifier journalNotifier) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Delete Entry"),
        content: Text("Are you sure you want to delete this journal entry?"),
        actions: <Widget>[
          TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              journalNotifier.deleteJournalEntry(entry);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// This function now calls the unified dialog for editing
void _editEntry(
    BuildContext context, JournalEntry entry, JournalNotifier journalNotifier) {
  showJournalDialog(
    context: context,
    journalNotifier: journalNotifier,
    selectedDate: entry.date,
    entry: entry, // Pass the entry to activate "edit" mode
  );
}

// --- WIDGETS ---

// Restored JournalListScreen
class JournalListScreen extends ConsumerWidget {
  final DateTime selectedDate;
  JournalListScreen({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is an example of how you might get your provider.
    // Replace `journalProvider` with your actual provider instance.
    // final journalState = ref.watch(journalProvider);
    // final journalNotifier = ref.read(journalProvider.notifier);

    // Using placeholder data since the provider isn't fully defined yet.
    // In your real app, you would remove this and use the lines above.
    final journalState = ref.watch(journalProvider);
    final journalNotifier = ref.read(journalProvider.notifier);

    // Filter entries from the actual state
    final dayEntries = journalState.entries
        .where((entry) => isSameDay(entry.date, selectedDate))
        .toList();

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left :8.0),
              child: Text(
                'Entries for ${DateFormat('d MMMM yyyy').format(selectedDate)}',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey[850],
                    fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            if (dayEntries.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: dayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = dayEntries[index];
                    return Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: showCardList(context, journalNotifier, entry),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (journalNotifier.isFutureDate(selectedDate)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cannot add entries for a future date.')),
            );
            return;
          }
          // The unified dialog is called here for adding a new entry
          showJournalDialog(
            context: context,
            journalNotifier: journalNotifier,
            selectedDate: selectedDate,
            // No 'entry' is passed, so it correctly enters "add" mode.
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add new journal entry',
      ),
    );
  }
}

Widget showCardList(
    BuildContext context, JournalNotifier journalNotifier, JournalEntry entry) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 12.0),
              child: Text(
                DateFormat.jm().format(entry.date),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  decoration: TextDecoration
                      .underline, // Add this line to underline the text
                  decorationStyle: TextDecorationStyle.solid,
                  
                ),
              ),
            ),
            Spacer(),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onSelected: (String result) {
                if (result == 'edit') {
                  _editEntry(context, entry, journalNotifier);
                } else if (result == 'delete') {
                  _showDeleteDialog(context, entry, journalNotifier);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit')
                  ]),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Delete')
                  ]),
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Text(
            entry.content,
            style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    ),
  );
}
// Widget showCardList(
//     BuildContext context, JournalNotifier journalNotifier, JournalEntry entry) {
//   final now = DateTime.now();
//   final DateTime today = DateTime.utc(now.year, now.month, now.day);
//   final DateTime yesterday = DateTime.utc(now.year, now.month, now.day - 1);
//   final String rightText = DateFormat('dd/MM/yyyy').format(entry.date);
//   String leftText;
//   TextStyle leftTextStyle = TextStyle(
//     fontSize: 15, // Adjusted for consistency
//     fontWeight: FontWeight.w600, // Make it stand out
//     color:
//         Theme.of(context).colorScheme.primary, // Use primary color for emphasis
//   );

//   if (isSameDay(entry.date, today)) {
//     leftText = "Today";
//   } else if (isSameDay(entry.date, yesterday)) {
//     leftText = "Yesterday";
//     leftTextStyle = leftTextStyle.copyWith(
//         color: Theme.of(context)
//             .colorScheme
//             .secondary); // Different color for yesterday
//   } else {
//     leftText = DateFormat('EEEE').format(entry.date); // Day of the week
//     leftTextStyle = leftTextStyle.copyWith(
//       fontWeight: FontWeight.normal, // Normal weight for other days
//       color: Theme.of(context).colorScheme.onSurfaceVariant,
//     );
//   }
//   return GestureDetector(
//     onTap: () {
//       journalNotifier.updateActuallySelectedDay(entry.date);
//       journalNotifier.updateSelectedMonth(entry.date);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => JournalListScreen(selectedDate: entry.date),
//         ),
//       );
//     },
//     child: Container(
//       padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       decoration: BoxDecoration(
//         border: Border(
//           left: BorderSide(
//             color: Colors.grey, // You can change this color
//             width: 2.0, // Adjust the width for thickness
//           ),
//         ),
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: Offset(1, 1), // changes position of shadow
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(leftText, style: leftTextStyle),
//               Text(
//                 rightText,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8), // Spacing between the date row and content
//           Text(
//             entry.content,
//             maxLines: 3, // Allow more lines for content preview
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 15,
//               height: 1.4, // Improved line spacing
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
