import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchBarWidget extends ConsumerStatefulWidget {
  final Function(String) onSearch;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
  });

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _debouncer = Debouncer<String>(
    const Duration(milliseconds: 500),
    initialValue: '',
  );
  bool _showSuggestions = false;
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  static const String _searchHistoryKey = 'search_history';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _debouncer.values.listen((value) {
      widget.onSearch(value);
      _updateSearchHistory(value);
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchHistoryKey, _searchHistory);
  }

  void _updateSearchHistory(String query) {
    if (query.isEmpty) return;

    setState(() {
      if (_searchHistory.contains(query)) {
        _searchHistory.remove(query);
      }
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    _saveSearchHistory();
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = _searchHistory;
      });
      return;
    }

    final queryLower = query.toLowerCase();
    setState(() {
      _suggestions = _searchHistory
          .where((item) => item.toLowerCase().contains(queryLower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = ref.watch(isSearchingProvider);

    return Stack(
      children: [
        // Overlay for handling tap outside
        if (_showSuggestions)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                setState(() {
                  _showSuggestions = false;
                });
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
                _updateSuggestions(value);
                setState(() {
                  _showSuggestions = true;
                });
              },
              onTap: () {
                setState(() {
                  _showSuggestions = true;
                });
              },
              onSubmitted: (value) {
                _focusNode.unfocus();
                setState(() {
                  _showSuggestions = false;
                });
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Mekan ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _suggestions.map((suggestion) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(
                          suggestion,
                          style: theme.textTheme.bodyLarge,
                        ),
                        onTap: () {
                          _controller.text = suggestion;
                          ref.read(searchQueryProvider.notifier).state =
                              suggestion;
                          _focusNode.unfocus();
                          setState(() {
                            _showSuggestions = false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
