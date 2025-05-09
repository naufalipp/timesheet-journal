import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For DateFormat if needed here

import '../providers/journal_provider.dart';
import 'journal_list_screen.dart';
// Removed domain entities import if not directly used

class CalendarScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final journalNotifier = ref.read(journalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Calendar - ${DateFormat('MMMM yyyy').format(journalState.selectedMonth)}'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        // Allow navigation up to the current day/month for adding entries
        // lastDay: DateTime.now(), // Original
        lastDay: DateTime(DateTime.now().year, DateTime.now().month + 6, 0), // Example: Allow few future months for navigation
        focusedDay: journalState.selectedMonth,
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false, // Assuming you manage format via selectedMonth
          titleTextStyle: TextStyle(fontSize: 18.0),
        ),
        onPageChanged: (focusedDay) {
          journalNotifier.updateSelectedMonth(focusedDay);
        },
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
        ),
        selectedDayPredicate: (day) {
          // If you want to visually mark the selected day on the calendar itself
          // This is often managed by focusedDay, but you can customize.
          // For now, navigation handles selection.
          return isSameDay(journalState.selectedMonth, day); // Example to mark the month's focused day
        },
        onDaySelected: (selectedDay, focusedDay) {
          // Update selectedMonth to reflect the month page of the focusedDay
          // but pass the actual selectedDay to the list screen.
          if (!isSameMonth(journalState.selectedMonth, focusedDay)) {
             journalNotifier.updateSelectedMonth(focusedDay);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JournalListScreen(selectedDate: selectedDay),
            ),
          );
        },
      ),
    );
  }

  bool isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}