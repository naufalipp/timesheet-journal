import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For DateFormat if needed here
// import 'package:timesheet_journal/src/backup.dart';
import 'package:timesheet_journal/src/domain/entities/journal_entry.dart';
import 'package:timesheet_journal/src/presentation/notifiers/journal_notifier.dart';

import '../providers/journal_provider.dart';
import '../providers/ui_provider.dart';

import 'journal_list_screen.dart';
// Removed domain entities import if not directly used

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch these providers to trigger rebuilds when their values change
    final scrollController = ref.watch(scrollControllerProvider);
    final isFabVisible = ref.watch(isFabVisibleProvider);
    final TextEditingController contentController = TextEditingController();

    final journalState = ref.watch(journalProvider);
    final journalNotifier =
        ref.read(journalProvider.notifier); // Use .notifier to access methods

    final now = DateTime.now();
    final DateTime today = DateTime.utc(now.year, now.month, now.day);

    final monthEntries = journalState.entries.where((entry) {
      return entry.date.year == journalState.selectedMonth.year &&
          entry.date.month == journalState.selectedMonth.month;
    }).toList()
      ..sort((a, b) =>
          b.date.compareTo(a.date)); // Sort by date, most recent first


    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton.icon(
              icon: Icon(Icons.download, size: 18),
              label: Text('Export Month'),
              onPressed: () async {
                debugPrint(
                    'Storage permission: ${await Permission.storage.status}');
                debugPrint(
                    'Manage external storage: ${await Permission.manageExternalStorage.status}');
                bool hasPermission = await _requestStoragePermission(context);
                if (!hasPermission) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Storage permission is required to export.')),
                  );
                  return;
                }
                final currentJournalState = journalNotifier.state;

                final List<JournalEntry> monthEntriesToExport =
                    currentJournalState.entries
                        .where((entry) =>
                            entry.date.year ==
                                currentJournalState.selectedMonth.year &&
                            entry.date.month ==
                                currentJournalState.selectedMonth.month)
                        .toList();

                if (monthEntriesToExport.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'No entries for ${DateFormat('MMMM yyyy').format(currentJournalState.selectedMonth)} to export.')),
                    );
                  }
                  return;
                }
                debugPrint('Entries to export: ${monthEntriesToExport.length}');
                debugPrint(
                    'Entries to export: ${monthEntriesToExport.map((e) => e.toString()).toList()}');
                final String monthName = DateFormat('MMMM_yyyy')
                    .format(currentJournalState.selectedMonth);
                final String? filePath = await journalNotifier.exportToCsv(
                    monthEntriesToExport, monthName, context);

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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              )),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            Text(
                'Journal Timesheet Calendar - ${DateFormat('MMMM yyyy').format(journalState.selectedMonth)}'),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(
                  DateTime.now().year, DateTime.now().month + 6, 0),
              focusedDay: journalState.selectedMonth,
              calendarFormat: CalendarFormat.month,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(fontSize: 18.0),
              ),
              eventLoader: (day) {
                return journalState.entries
                    .where((entry) => isSameDay(entry.date, day))
                    .toList();
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }
                  return null;
                },
                disabledBuilder: (context, day, focusedDay) {
                  if (day.isAfter(today)) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    );
                  }
                  return null;
                },
              ),
              selectedDayPredicate: (day) {
                return journalState.actuallySelectedDay != null &&
                    isSameDay(journalState.actuallySelectedDay!, day);
              },
              enabledDayPredicate: (DateTime day) {
                return !day.isAfter(today);
              },
              onPageChanged: (focusedDay) {
                journalNotifier.updateSelectedMonth(focusedDay);
              },
              onDaySelected: (selectedDay, focusedDay) {
                journalNotifier.updateActuallySelectedDay(selectedDay);
                journalNotifier.updateSelectedMonth(selectedDay);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JournalListScreen(selectedDate: selectedDay),
                  ),
                );
              },
            ),
            Divider(),
            Expanded(
              child: monthEntries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "No journal entries for this month yet.",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller:
                          scrollController, // Attach the scroll controller
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: monthEntries.length,
                      itemBuilder: (context, index) {
                        final JournalEntry entry = monthEntries[index];

                        return Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: showCardList(
                                    context, journalNotifier, entry)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: isFabVisible // Conditionally render the FAB
          ? FloatingActionButton.extended(
              onPressed: () {
                if (journalNotifier.isFutureDate(today)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Cannot add entries for a future date.')),
                  );
                  return;
                }
                contentController.clear();

                void handleSave() {
                  if (contentController.text.isNotEmpty) {
                    final entryTime = DateTime.now();
                    final entryDateWithTime = DateTime(
                      today.year,
                      today.month,
                      today.day,
                      entryTime.hour,
                      entryTime.minute,
                      entryTime.second,
                    );

                    journalNotifier.addEntry(
                      JournalEntry(
                        date: entryDateWithTime,
                        content: contentController.text,
                      ),
                    );
                    contentController.clear(); // Clear after successful save
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please write something to save!'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }

                showJournalDialog(
                  context: context,
                  selectedDate: today,
                  contentController: contentController,
                  onSavePressed: handleSave,
                );
              },
              tooltip: 'Add today journal',
              icon: Icon(Icons.add),
              label: Text('Add Journal'),
            )
          : null, // Set to null to hide the FAB
    );
  }

  // Helper function to check if two DateTime objects represent the same day.
  // Make sure this is defined globally or within a class where it's accessible.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

Future<bool> _requestStoragePermission(BuildContext context) async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      debugPrint('Manage external storage permission already granted.');
      return true;
    }

    PermissionStatus manageStorageStatus =
        await Permission.manageExternalStorage.request();
    if (manageStorageStatus.isGranted) {
      debugPrint('Manage external storage permission granted.');
      return true;
    } else if (manageStorageStatus.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Please enable storage permission in settings.'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      debugPrint('Manage external storage permanently denied.');
      return false;
    }

    if (await Permission.storage.isGranted) {
      debugPrint('Storage permission already granted.');
      return true;
    }

    PermissionStatus storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      debugPrint('Storage permission granted.');
      return true;
    } else if (storageStatus.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Please enable storage permission in settings.'),
            action: SnackBarAction(
              label: 'Open Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      debugPrint('Storage permission permanently denied.');
      return false;
    }
    debugPrint('Storage permission denied: $storageStatus');
    return false;
  } else if (Platform.isIOS) {
    debugPrint('iOS platform: No storage permission required.');
    return true;
  } else {
    debugPrint('Non-mobile platform: No storage permission required.');
    return true;
  }
}

// Ensure isSameDay is accessible, placing it outside the class or in a utility file
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Your existing showJournalDialog and showCardList functions (assuming they are defined globally or in a utility file)
// Make sure to import them if they are in separate files.
void showJournalDialog({
  required BuildContext context,
  required DateTime selectedDate,
  required TextEditingController contentController,
  required VoidCallback onSavePressed,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
            'Add Journal Entry for ${selectedDate.toLocal().toString().split(' ')[0]}'),
        content: TextField(
          controller: contentController,
          maxLines: 5,
          decoration: InputDecoration(hintText: 'Write your thoughts...'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onSavePressed,
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

Widget showCardList(
    BuildContext context, JournalNotifier journalNotifier, JournalEntry entry) {
  final now = DateTime.now();
  final DateTime today = DateTime.utc(now.year, now.month, now.day);
  final DateTime yesterday = DateTime.utc(now.year, now.month, now.day - 1);
  final String rightText = DateFormat('dd/MM/yyyy').format(entry.date);
  String leftText;
  TextStyle leftTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.primary,
  );

  if (isSameDay(entry.date, today)) {
    leftText = "Today";
  } else if (isSameDay(entry.date, yesterday)) {
    leftText = "Yesterday";
    leftTextStyle =
        leftTextStyle.copyWith(color: Theme.of(context).colorScheme.secondary);
  } else {
    leftText = DateFormat('EEEE').format(entry.date);
    leftTextStyle = leftTextStyle.copyWith(
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
  return Dismissible(
    key: ValueKey(entry.hashCode),
    direction:
        DismissDirection.endToStart, // Only allow swipe from right to left
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    confirmDismiss: (direction) async {
      // Show a confirmation dialog before actually dismissing
      return await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
                "Are you sure you want to delete this journal entry?"),
            actions: <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(false), // User cancels
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(true), // User confirms
                child: const Text("Delete"),
              ),
            ],
          );
        },
      );
    },
    onDismissed: (direction) async {
      // This callback is fired AFTER the user has confirmed and the item is dismissed
      await journalNotifier.deleteJournalEntry(entry);
      // Show a brief message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Entry "${entry.content.split('\n')[0].trim()}..." deleted.'),
          duration: Duration(seconds: 2),
        ),
      );
    },
    child: GestureDetector(
      onTap: () {
        journalNotifier.updateActuallySelectedDay(entry.date);
        journalNotifier.updateSelectedMonth(entry.date);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JournalListScreen(selectedDate: entry.date),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey,
              width: 2.0,
            ),
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(leftText, style: leftTextStyle),
                Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
