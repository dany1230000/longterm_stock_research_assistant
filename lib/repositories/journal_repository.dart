import '../models/journal_entry.dart';

abstract class JournalRepository {
  List<JournalEntry> fetchEntries();

  void addEntry(JournalEntry entry);
}
