import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/services/firebase/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service providers - shared instances for the app
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Cache for venues - uses TTL based caching mechanism
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

    // Check if cache entry is expired
    final now = DateTime.now();
    if (now.difference(entry.timestamp) > cacheDuration) {
      // Cache expired, remove it and return null
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

    final now = DateTime.now();
    return now.difference(entry.timestamp) <= cacheDuration;
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  const CacheEntry({required this.data, required this.timestamp});
}

final venuesCacheProvider = StateNotifierProvider<CacheManager,
    Map<String, CacheEntry<List<VenueModel>>>>(
  (ref) => CacheManager(),
);

/// Stream of all venues
final venuesProvider = StreamProvider<List<VenueModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getVenues();
});

/// Stream of venues filtered by category
final venuesByCategoryProvider =
    StreamProvider.family<List<VenueModel>, String>((ref, category) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getVenuesByCategory(category);
});

/// Stream of venues matching search query - debounced to avoid excessive queries
final searchVenuesProvider =
    StreamProvider.family<List<VenueModel>, String>((ref, query) async* {
  if (query.isEmpty) {
    ref.read(isSearchingProvider.notifier).state = false;
    yield [];
    return;
  }

  try {
    ref.read(isSearchingProvider.notifier).state = true;
    final firestoreService = ref.read(firestoreServiceProvider);

    await for (final venues in firestoreService.searchVenues(query)) {
      ref.read(isSearchingProvider.notifier).state = false;
      yield venues;
    }
  } catch (e) {
    ref.read(isSearchingProvider.notifier).state = false;
    debugPrint('Search error: $e');
    yield [];
  }
});

/// Venue by ID provider with automatic caching based on last fetch
final venueByIdProvider =
    FutureProvider.family<VenueModel?, String>((ref, venueId) async {
  if (venueId.isEmpty) {
    throw Exception('Geçersiz mekan ID\'si');
  }

  try {
    final cacheManager = ref.watch(venuesCacheProvider.notifier);
    final cacheKey = 'venue_$venueId';

    // Önbellekten kontrol et
    final cachedVenues = cacheManager.get(cacheKey);
    if (cachedVenues != null && cachedVenues.isNotEmpty) {
      return cachedVenues.first;
    }

    // Firestore'dan çek
    final firestoreService = ref.watch(firestoreServiceProvider);
    final venue = await firestoreService.getVenueById(venueId);

    if (venue == null) {
      throw Exception('Mekan bulunamadı');
    }

    // Sonucu önbelleğe al
    cacheManager.put(cacheKey, [venue]);

    return venue;
  } catch (e) {
    debugPrint('Error fetching venue by ID: $e');
    // Daha açıklayıcı hata mesajı
    if (e.toString().contains('Mekan bulunamadı')) {
      throw Exception('Mekan bulunamadı');
    }
    throw Exception(
        'Mekan yüklenirken bir hata oluştu. Lütfen tekrar deneyin.');
  }
});

/// Featured venues with TTL-based caching
final featuredVenuesProvider = FutureProvider<List<VenueModel>>((ref) async {
  final cacheManager = ref.watch(venuesCacheProvider.notifier);
  const cacheKey = 'featured';

  // Check cache first
  final cachedVenues = cacheManager.get(cacheKey);
  if (cachedVenues != null) {
    return cachedVenues;
  }

  // Fetch from Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);
  final venues = await firestoreService.getFeaturedVenues();

  // Cache the result
  cacheManager.put(cacheKey, venues);

  return venues;
});

/// Recently viewed venues with proper TTL-based caching
final recentlyViewedVenuesProvider =
    FutureProvider<List<VenueModel>>((ref) async {
  final cacheManager = ref.watch(venuesCacheProvider.notifier);
  const cacheKey = 'recentlyViewed';
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  // Check cache first with short TTL for recently viewed items
  if (cacheManager.hasValidCache(cacheKey)) {
    final cached = cacheManager.get(cacheKey);
    if (cached != null) return cached;
  }

  // Fetch from Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);
  final venues = await firestoreService.getRecentlyViewedVenues(userId);

  // Cache the result
  cacheManager.put(cacheKey, venues);

  return venues;
});

/// Favorite venues with cached data that auto-refreshes
final favoriteVenuesProvider = FutureProvider<List<VenueModel>>((ref) async {
  final cacheManager = ref.watch(venuesCacheProvider.notifier);
  const cacheKey = 'favorites';
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  // Check cache first
  final cachedVenues = cacheManager.get(cacheKey);
  if (cachedVenues != null) {
    return cachedVenues;
  }

  // Fetch from Firestore
  final firestoreService = ref.watch(firestoreServiceProvider);
  // Get all favorited venue IDs for the user and then fetch those venues
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final favoriteIds =
      List<String>.from(userDoc.data()?['favoriteVenues'] ?? []);
  final venues = await firestoreService.getVenuesByIds(favoriteIds);

  // Cache the result
  cacheManager.put(cacheKey, venues);

  return venues;
});

/// Recent searches provider
final recentSearchesProvider = FutureProvider<List<VenueModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return const [];
  }

  try {
    // Get user document to get recentSearches array
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final recentSearchIds =
        List<String>.from(userDoc.data()?['recentSearches'] ?? []);
    if (recentSearchIds.isEmpty) return const [];

    return firestoreService.getVenuesByIds(recentSearchIds);
  } catch (e) {
    debugPrint('Error getting recent searches: $e');
    return const [];
  }
});

/// Function to selectively clear venues cache
void clearVenuesCache(WidgetRef ref, {String? specificKey}) {
  final cacheManager = ref.read(venuesCacheProvider.notifier);

  if (specificKey != null) {
    cacheManager.invalidate(specificKey);
  } else {
    cacheManager.clear();
  }
}

/// Helper for invalidating a specific venue
void invalidateVenue(WidgetRef ref, String venueId) {
  clearVenuesCache(ref, specificKey: 'venue_$venueId');
}

final searchResultsProvider = StreamProvider<List<VenueModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return Stream.value([]);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.searchVenues(query);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final isSearchingProvider = StateProvider<bool>((ref) => false);
