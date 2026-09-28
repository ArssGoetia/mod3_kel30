import 'package:flutter/material.dart';

import '../screens/home.dart';
import '../screens/profile.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _currentIndex = 0;
  final List<Country> _favoriteCountries = [];
  final List<Country> _historyCountries = [];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleFavorite(Country country) {
    setState(() {
      final isFavorite = _favoriteCountries.any(
        (item) => item.name == country.name,
      );
      if (isFavorite) {
        _favoriteCountries.removeWhere((item) => item.name == country.name);
      } else {
        _favoriteCountries.add(country);
      }
    });
  }

  void _addToHistory(Country country) {
    setState(() {
      final existingIndex = _historyCountries.indexWhere(
        (item) => item.name == country.name,
      );
      if (existingIndex != -1) {
        _historyCountries.removeAt(existingIndex);
      }
      _historyCountries.insert(0, country);
    });
  }

  void _removeHistory(Country country) {
    setState(() {
      _historyCountries.removeWhere((item) => item.name == country.name);
    });
  }

  void _clearHistory() {
    setState(() {
      _historyCountries.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        favoriteCountries: _favoriteCountries,
        historyCountries: _historyCountries,
        onToggleFavorite: _toggleFavorite,
        onAddToHistory: _addToHistory,
      ),
      FavoritesPage(
        favoriteCountries: _favoriteCountries,
        onToggleFavorite: _toggleFavorite,
      ),
      HistoryPage(
        historyCountries: _historyCountries,
        onRemoveHistory: _removeHistory,
        onClearHistory: _clearHistory,
      ),
      ProfilePage(onHomeTap: () => _onTabTapped(0)),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
