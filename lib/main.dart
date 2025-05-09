import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timesheet_journal/src/data/adapters/journal_entry_adapter.dart';
import 'package:timesheet_journal/src/domain/entities/journal_entry.dart';
import 'src/app.dart'; // Import MyApp

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter();

  // Register your Hive adapter
  Hive.registerAdapter(JournalEntryAdapter());

  // Open your Hive box
  await Hive.openBox<JournalEntry>('journalBox');

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}