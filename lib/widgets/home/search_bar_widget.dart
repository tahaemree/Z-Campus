import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  double _lastBottomInset = 0;
  Timer? _debounceTimer;

  static const int _minSearchLength = 2; // Minimum arama uzunluğu
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChange);

    // Root GestureDetector için listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupUnfocusListener();
    });
  }

  void _setupUnfocusListener() {
    if (!mounted) return;

    // Ana ekrana dokunulduğunda search bar'ın odağını kaldır
    GestureDetector? rootGestureDetector;
    void findGestureDetector(BuildContext context) {
      context.visitChildElements((element) {
        if (element.widget is GestureDetector) {
          rootGestureDetector = element.widget as GestureDetector;
        } else {
          findGestureDetector(element);
        }
      });
    }

    findGestureDetector(context);

    if (rootGestureDetector != null) {
      final originalOnTapDown = rootGestureDetector!.onTapDown;
      (rootGestureDetector as dynamic).onTapDown = (TapDownDetails details) {
        _focusNode.unfocus();
        if (originalOnTapDown != null) {
          originalOnTapDown(details);
        }
      };
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _focusNode.unfocus();
    }
  }

  @override
  void didChangeMetrics() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (_lastBottomInset > 0 && bottomInset == 0) {
      // Klavye kapandı
      _focusNode.unfocus();
    }
    _lastBottomInset = bottomInset;
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _clearSearch();
    }
  }

  void _clearSearch() {
    setState(() {
      _query = '';
      _controller.clear();
    });
    widget.onSearch('');
  }

  void _handleSearch(String value) {
    setState(() {
      _query = value;
    });

    // Mevcut debounce timer'ı iptal et
    _debounceTimer?.cancel();

    final normalizedQuery = value.trim();

    // Eğer arama metni minimum uzunluktan kısaysa ve boş değilse, arama yapma
    if (normalizedQuery.length < _minSearchLength &&
        normalizedQuery.isNotEmpty) {
      return;
    }

    // Yeni bir debounce timer başlat
    _debounceTimer = Timer(_debounceDuration, () {
      widget.onSearch(normalizedQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: SearchBar(
        focusNode: _focusNode,
        padding: WidgetStateProperty.all(const EdgeInsets.fromLTRB(2, 8, 2, 8)),
        controller: _controller,
        onChanged: _handleSearch,
        hintText: 'Ara...',
        hintStyle: WidgetStateProperty.all(
          TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        leading: Icon(
          Icons.search,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        trailing: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: _clearSearch,
            ),
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;

  CustomSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
          close(context, '');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
