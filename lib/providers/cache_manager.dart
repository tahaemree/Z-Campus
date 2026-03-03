import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/models/venue_model.dart';

/// Generic cache entry with timestamp for TTL-based invalidation.
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  const CacheEntry({required this.data, required this.timestamp});
}

/// TTL-based cache manager for venue data.
class CacheManager
    extends StateNotifier<Map<String, CacheEntry<List<VenueModel>>>> {
  CacheManager() : super(const {});

  static const cacheDuration = Duration(minutes: 15);

  void put(String key, List<VenueModel> data) {
    state = {
      ...state,
      key: CacheEntry(data: data, timestamp: DateTime.now()),
    };
  }

  List<VenueModel>? get(String key) {
    final entry = state[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > cacheDuration) {
      state = Map.from(state)..remove(key);
      return null;
    }

    return entry.data;
  }

  void invalidate(String key) {
    if (state.containsKey(key)) {
      state = Map.from(state)..remove(key);
    }
  }

  void clear() {
    state = const {};
  }

  bool hasValidCache(String key) {
    final entry = state[key];
    if (entry == null) return false;
    return DateTime.now().difference(entry.timestamp) <= cacheDuration;
  }
}

final venuesCacheProvider = StateNotifierProvider<CacheManager,
    Map<String, CacheEntry<List<VenueModel>>>>(
  (ref) => CacheManager(),
);
