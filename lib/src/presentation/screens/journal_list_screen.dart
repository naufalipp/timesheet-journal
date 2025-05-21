// Keep if you need it for something else, else remove
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timesheet_journal/src/presentation/notifiers/journal_notifier.dart';

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
                  debugPrint(
                      'Storage permission: ${await Permission.storage.status}');
                  debugPrint(
                      'Manage external storage: ${await Permission.manageExternalStorage.status}');
                  bool hasPermission = await _requestStoragePermission(context);
                  if (!hasPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Storage permission is required to export.')),
                    );
                    return;
                  }
                  final currentJournalState = journalNotifier
                      .state; // Or however you access state if using Riverpod ref.watch

                  // 2. Prepare monthEntries based on the current state
                  final List<JournalEntry> monthEntriesToExport =
                      currentJournalState.entries
                          .where((entry) =>
                              entry.date.year ==
                                  currentJournalState.selectedMonth.year &&
                              entry.date.month ==
                                  currentJournalState.selectedMonth.month)
                          .toList();

                  // 3. Handle if no entries (optional, as exportToExcel also checks, but good for quick UI feedback)
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
                  debugPrint(
                      'Entries to export: ${monthEntriesToExport.length}');
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

                  return Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: showCardList(context, journalNotifier, entry));
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

Future<bool> _requestStoragePermission(BuildContext context) async {
  if (Platform.isAndroid) {
    // Check Android version using package_info_plus or device_info_plus if needed
    // For simplicity, try manageExternalStorage first, then fallback to storage
    if (await Permission.manageExternalStorage.isGranted) {
      debugPrint('Manage external storage permission already granted.');
      return true;
    }

    // Request MANAGE_EXTERNAL_STORAGE for Android 11+ (API 30+)
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

    // Fallback to storage permission for older Android versions (API < 30)
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
    // iOS typically doesn't require explicit storage permissions for FilePicker
    debugPrint('iOS platform: No storage permission required.');
    return true;
  } else {
    // Web or other platforms: No permission needed for FilePicker or excel.save()
    debugPrint('Non-mobile platform: No storage permission required.');
    return true;
  }
}

Widget showCardList(
    BuildContext context, JournalNotifier journalNotifier, JournalEntry entry) {
  final now = DateTime.now();
  final DateTime today = DateTime.utc(now.year, now.month, now.day);
  final DateTime yesterday = DateTime.utc(now.year, now.month, now.day - 1);
  final String rightText = DateFormat('dd/MM/yyyy').format(entry.date);
  String leftText;
  TextStyle leftTextStyle = TextStyle(
    fontSize: 15, // Adjusted for consistency
    fontWeight: FontWeight.w600, // Make it stand out
    color:
        Theme.of(context).colorScheme.primary, // Use primary color for emphasis
  );

  if (isSameDay(entry.date, today)) {
    leftText = "Today";
  } else if (isSameDay(entry.date, yesterday)) {
    leftText = "Yesterday";
    leftTextStyle = leftTextStyle.copyWith(
        color: Theme.of(context)
            .colorScheme
            .secondary); // Different color for yesterday
  } else {
    leftText = DateFormat('EEEE').format(entry.date); // Day of the week
    leftTextStyle = leftTextStyle.copyWith(
      fontWeight: FontWeight.normal, // Normal weight for other days
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
  return GestureDetector(
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
            color: Colors.grey, // You can change this color
            width: 2.0, // Adjust the width for thickness
          ),
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(1, 1), // changes position of shadow
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
          SizedBox(height: 8), // Spacing between the date row and content
          Text(
            entry.content,
            maxLines: 3, // Allow more lines for content preview
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.4, // Improved line spacing
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}
