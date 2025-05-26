import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../data/datasources/journal_local_data_source.dart';
import '../../data/repositories/journal_repository_impl.dart';
import '../notifiers/journal_notifier.dart';
import '../notifiers/journal_state.dart';

// Provider for the Hive Box
final journalBoxProvider = Provider<Box<JournalEntry>>((ref) {
  return Hive.box<JournalEntry>('journalBox');
});

// Provider for JournalLocalDataSource
final journalLocalDataSourceProvider = Provider<JournalLocalDataSource>((ref) {
  final box = ref.watch(journalBoxProvider);
  return JournalLocalDataSource(box);
});

// Provider for JournalRepository
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final dataSource = ref.watch(journalLocalDataSourceProvider);
  return JournalRepositoryImpl(dataSource);
});

// StateNotifierProvider for JournalNotifier
final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return JournalNotifier(repository);
});