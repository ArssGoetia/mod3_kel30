import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'detail.dart';

class HomePage extends StatefulWidget {
  final List<Country> favoriteCountries;
  final List<Country> historyCountries;
  final void Function(Country country) onToggleFavorite;
  final void Function(Country country) onAddToHistory;

  const HomePage({
    super.key,
    required this.favoriteCountries,
    required this.historyCountries,
    required this.onToggleFavorite,
    required this.onAddToHistory,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Country>> countries;
  final TextEditingController _searchController = TextEditingController();
  String _selectedContinent = 'Semua';

  final List<String> _continentOptions = [
    'Semua',
    'Africa',
    'Americas',
    'Asia',
    'Europe',
    'Oceania',
    'Antarctica',
  ];

  @override
  void initState() {
    super.initState();
    countries = fetchCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Country>> fetchCountries() async {
    final uri = Uri.parse('https://www.apicountries.com/countries');
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      final respBody = await response.transform(utf8.decoder).join();
      final List jsonData = jsonDecode(respBody);
      final countryList = jsonData.map((j) => Country.fromJson(j)).toList();
      countryList.sort((a, b) {
        final regionComparison = a.region.compareTo(b.region);
        if (regionComparison != 0) {
          return regionComparison;
        }
        return a.name.compareTo(b.name);
      });
      return countryList;
    } else {
      throw Exception('Failed to load countries: ${response.statusCode}');
    }
  }

  List<Country> _applySearchAndSort(List<Country> list) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = list.where((country) {
      return query.isEmpty ||
          country.name.toLowerCase().contains(query) ||
          country.region.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (_selectedContinent != 'Semua') {
        final aPriority = a.region == _selectedContinent ? 0 : 1;
        final bPriority = b.region == _selectedContinent ? 0 : 1;
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
      }

      final regionComparison = a.region.compareTo(b.region);
      if (regionComparison != 0) {
        return regionComparison;
      }
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  bool _isFavorite(Country country) {
    return widget.favoriteCountries.any((item) => item.name == country.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Countries')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedContinent,
                  decoration: const InputDecoration(
                    labelText: 'Sort by continent',
                    border: OutlineInputBorder(),
                  ),
                  items: _continentOptions
                      .map(
                        (continent) => DropdownMenuItem(
                          value: continent,
                          child: Text(continent),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedContinent = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Country>>(
              future: countries,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No countries found'));
                }

                final visibleCountries = _applySearchAndSort(snapshot.data!);

                if (visibleCountries.isEmpty) {
                  return const Center(
                    child: Text('No countries match your filter'),
                  );
                }

                return ListView.builder(
                  itemCount: visibleCountries.length,
                  itemBuilder: (context, i) {
                    final country = visibleCountries[i];
                    final isFavorite = _isFavorite(country);

                    return Card(
                      child: ListTile(
                        leading: country.flagsPng != null
                            ? Image.network(country.flagsPng!, width: 50)
                            : const SizedBox(width: 50),
                        title: Text(country.name),
                        subtitle: Text(
                          '${country.region} • ${country.population}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () {
                                widget.onToggleFavorite(country);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          widget.onAddToHistory(country);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                country: country,
                                isFavorite: _isFavorite(country),
                                onToggleFavorite: () {
                                  widget.onToggleFavorite(country);
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<Country> favoriteCountries;
  final void Function(Country country) onToggleFavorite;

  const FavoritesPage({
    super.key,
    required this.favoriteCountries,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoriteCountries.isEmpty
          ? const Center(child: Text('No favorite countries yet'))
          : ListView.builder(
              itemCount: favoriteCountries.length,
              itemBuilder: (context, index) {
                final country = favoriteCountries[index];
                return Card(
                  child: ListTile(
                    leading: country.flagsPng != null
                        ? Image.network(country.flagsPng!, width: 50)
                        : const SizedBox(width: 50),
                    title: Text(country.name),
                    subtitle: Text(country.region),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => onToggleFavorite(country),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  final List<Country> historyCountries;
  final void Function(Country country) onRemoveHistory;
  final VoidCallback onClearHistory;

  const HistoryPage({
    super.key,
    required this.historyCountries,
    required this.onRemoveHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (historyCountries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear history',
              onPressed: onClearHistory,
            ),
        ],
      ),
      body: historyCountries.isEmpty
          ? const Center(child: Text('No country history yet'))
          : ListView.builder(
              itemCount: historyCountries.length,
              itemBuilder: (context, index) {
                final country = historyCountries[index];
                return Card(
                  child: ListTile(
                    leading: country.flagsPng != null
                        ? Image.network(country.flagsPng!, width: 50)
                        : const SizedBox(width: 50),
                    title: Text(country.name),
                    subtitle: Text(country.region),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Hard delete history',
                      onPressed: () => onRemoveHistory(country),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class Country {
  final String name;
  final String region;
  final String? capital;
  final int population;
  final String? flagsPng;
  final List<dynamic>? languages;
  final List<dynamic>? currencies;

  Country({
    required this.name,
    required this.region,
    required this.population,
    this.capital,
    this.flagsPng,
    this.languages,
    this.currencies,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    List<dynamic>? langs;
    if (json['languages'] != null) {
      langs = (json['languages'] as List)
          .map((l) => l['name'].toString())
          .toList();
    }

    List<dynamic>? cur;
    if (json['currencies'] != null) {
      cur = (json['currencies'] as List)
          .map((c) => c['name'].toString())
          .toList();
    }

    return Country(
      name: json['name'] ?? 'N/A',
      region: json['region'] ?? 'N/A',
      population: json['population'] ?? 0,
      capital: json['capital'],
      flagsPng: json['flags'] != null ? json['flags']['png'] : null,
      languages: langs,
      currencies: cur,
    );
  }
}
