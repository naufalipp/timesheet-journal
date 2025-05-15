import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // For DateFormat if needed here
import 'package:timesheet_journal/src/domain/entities/journal_entry.dart';

import '../providers/journal_provider.dart';
import 'journal_list_screen.dart';
// Removed domain entities import if not directly used

class CalendarScreen extends ConsumerWidget {
  // Added super.key for constructor
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalProvider);
    final journalNotifier = ref.read(journalProvider.notifier);

    // Get today's date, normalized to midnight for accurate comparison with calendar days
    final now = DateTime.now();
    final DateTime today = DateTime.utc(now.year, now.month, now.day);
    final DateTime yesterday = DateTime.utc(now.year, now.month, now.day - 1);
    final monthEntries = journalState.entries.where((entry) {
      return entry.date.year == journalState.selectedMonth.year &&
          entry.date.month == journalState.selectedMonth.month;
    }).toList()
      // Sort entries by date, most recent first, or a.date.compareTo(b.date) for oldest first
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
          // title: Text(
          //     'Journal Timesheet Calendar - ${DateFormat('MMMM yyyy').format(journalState.selectedMonth)}'),
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
              // focusedDay is driven by selectedMonth (which represents the current page/month)
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
              // Use `actuallySelectedDay` for the visual selection
              selectedDayPredicate: (day) {
                return journalState.actuallySelectedDay != null &&
                    isSameDay(journalState.actuallySelectedDay!, day);
              },
              enabledDayPredicate: (DateTime day) {
                return !day.isAfter(today);
              },
              onPageChanged: (focusedDay) {
                // When the page (month) changes, only update the selectedMonth (for focusedDay and title)
                // Do NOT update actuallySelectedDay here, so previous selections can persist if desired,
                // or clear it if you want selection to reset on month swipe:
                journalNotifier.updateSelectedMonth(focusedDay);
                // To clear selection on swipe:
                // journalNotifier.updateActuallySelectedDay(null);
              },
              onDaySelected: (selectedDay, focusedDay) {
                // When a day is tapped:
                // 1. Update the `actuallySelectedDay` to the day the user tapped.
                journalNotifier.updateActuallySelectedDay(selectedDay);

                // 2. Update `selectedMonth` to keep `focusedDay` and AppBar title in sync
                //    with the month of the `selectedDay`.
                journalNotifier.updateSelectedMonth(
                    selectedDay); // Use selectedDay for month context

                // 3. Navigate
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: monthEntries.length,
                      itemBuilder: (context, index) {
                        final JournalEntry entry = monthEntries[index];
                        String leftText;
                        TextStyle leftTextStyle = TextStyle(
                          fontSize: 15, // Adjusted for consistency
                          fontWeight: FontWeight.w600, // Make it stand out
                          color: Theme.of(context)
                              .colorScheme
                              .primary, // Use primary color for emphasis
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
                          leftText = DateFormat('EEEE')
                              .format(entry.date); // Day of the week
                          leftTextStyle = leftTextStyle.copyWith(
                            fontWeight: FontWeight
                                .normal, // Normal weight for other days
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          );
                        }

                        final String rightText =
                            DateFormat('dd/MM/yy h:mm a').format(entry.date);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: InkWell(
                            // Added InkWell for tap effect
                            borderRadius: BorderRadius.circular(
                                10.0), // Match Card's shape
                            onTap: () {
                              journalNotifier
                                  .updateActuallySelectedDay(entry.date);
                              journalNotifier.updateSelectedMonth(entry.date);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JournalListScreen(
                                      selectedDate: entry.date),
                                ),
                              );
                            },
                            child: Padding(
                              // Use Padding instead of ListTile for custom layout
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(leftText, style: leftTextStyle),
                                      Text(
                                        rightText,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                      height:
                                          8), // Spacing between the date row and content
                                  Text(
                                    entry.content,
                                    maxLines:
                                        3, // Allow more lines for content preview
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4, // Improved line spacing
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to check if two DateTime objects represent the same month and year.
  bool isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}
