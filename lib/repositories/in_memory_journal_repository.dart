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

  @override
  void updateEntry(JournalEntry entry) {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      return;
    }
    _entries[index] = entry;
  }

  @override
  void deleteEntry(String id) {
    _entries.removeWhere((entry) => entry.id == id);
  }
}
