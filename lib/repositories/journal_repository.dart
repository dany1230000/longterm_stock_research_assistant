import '../models/journal_entry.dart';

abstract class JournalRepository {
  List<JournalEntry> fetchEntries();

  void addEntry(JournalEntry entry);

  void updateEntry(JournalEntry entry);

  void deleteEntry(String id);
}
