import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search state model.
class SearchState {
  final bool isSearching;
  final String? error;

  const SearchState({
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({bool? isSearching, String? error}) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

/// Search state notifier with safe mounted checks.
class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());

  void setSearching(bool isSearching) {
    if (mounted) {
      state = state.copyWith(isSearching: isSearching);
    }
  }

  void setError(String? error) {
    if (mounted) {
      state = state.copyWith(error: error, isSearching: false);
    }
  }

  void clear() {
    if (mounted) {
      state = const SearchState();
    }
  }
}

final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>(
        (ref) => SearchStateNotifier());

final searchQueryProvider = StateProvider<String>((ref) => '');
