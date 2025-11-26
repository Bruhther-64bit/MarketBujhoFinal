import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  // Save search query
  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = await getHistory();

    // Remove if already exists (to move it to top)
    history.remove(query);

    // Add to beginning
    history.insert(0, query);

    // Keep only last 10
    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }

    await prefs.setStringList(_key, history);
  }

  // Get search history
  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // Remove single item
  Future<void> removeItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = await getHistory();
    history.remove(query);
    await prefs.setStringList(_key, history);
  }
}