import 'package:flutter/material.dart';
import 'package:timesheet_journal/src/presentation/screens/calendar_screen.dart';



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Consider using ColorScheme for modern themes
        // Example for modern themes:
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // useMaterial3: true,
      ),
      home: CalendarScreen(),
    );
  }
}