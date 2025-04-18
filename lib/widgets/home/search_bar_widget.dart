import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    setState(() {
      _query = value;
    });
    widget.onSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      onChanged: _handleSearch,
      hintText: 'Mekan ara...',
      leading: const Icon(Icons.search),
      trailing: [
        if (_query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _query = '';
                _controller.clear();
              });
              widget.onSearch('');
            },
          ),
      ],
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
          // Return to Explore page by closing the search and triggering a search with empty query
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
    return Container(); // Arama sonuçları başka bir sayfada gösterileceği için boş container
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: [
        if (query.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.search),
            title: Text('$query ara'),
            onTap: () {
              onSearch(query);
              close(context, query);
            },
          ),

        // Önerilen aramalar
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Kütüphane'),
          onTap: () {
            onSearch('kütüphane');
            close(context, 'kütüphane');
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Yemekhane'),
          onTap: () {
            onSearch('yemekhane');
            close(context, 'yemekhane');
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Spor Salonu'),
          onTap: () {
            onSearch('spor salonu');
            close(context, 'spor salonu');
          },
        ),
      ],
    );
  }
}
