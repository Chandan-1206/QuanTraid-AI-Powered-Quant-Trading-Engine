import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  List<String> _watchlist = ['RELIANCE.NS', 'TCS.NS'];

  bool get isDarkMode => _isDarkMode;
  List<String> get watchlist => _watchlist;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleWatchlist(String stock) {
    if (_watchlist.contains(stock)) {
      _watchlist.remove(stock);
    } else {
      _watchlist.add(stock);
    }
    notifyListeners();
  }

  bool isInWatchlist(String stock) {
    return _watchlist.contains(stock);
  }
}
