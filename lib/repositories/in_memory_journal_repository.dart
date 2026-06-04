import '../models/journal_entry.dart';
import 'journal_repository.dart';

class InMemoryJournalRepository implements JournalRepository {
  final List<JournalEntry> _entries = [];

  @override
  List<JournalEntry> fetchEntries() {
    return List.unmodifiable(_entries);
  }

  @override
  void addEntry(JournalEntry entry) {
    _entries.insert(0, entry);
  }
}
