import 'dart:async';
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final bool autoFocus;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.autoFocus = false,
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  Timer? _debounceTimer;
  bool _ownsController = false;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _query = _controller.text;
  }

  void _clearSearch() {
    if (!mounted) return;
    setState(() { _query = ''; _controller.clear(); });
    widget.onSearch('');
  }

  void _handleSearch(String value) {
    if (!mounted) return;
    setState(() { _query = value.trim(); });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      widget.onSearch(_query);
    });
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autoFocus,
          onChanged: _handleSearch,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Kampüste mekan veya etkinlik ara...',
            hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4), fontSize: 15),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.search_rounded, color: isDark ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.primary.withValues(alpha: 0.8), size: 24),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.6)),
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }
}
