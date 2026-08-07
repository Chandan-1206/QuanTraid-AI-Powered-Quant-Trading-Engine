import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: provider.watchlist.isEmpty
          ? const Center(child: Text('No stocks in watchlist'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.watchlist.length,
              itemBuilder: (context, index) {
                 String stock = provider.watchlist[index];
                 return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                       title: Text(stock, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                       subtitle: const Text('Volatile • AI Medium Risk'),
                       trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.loss),
                          onPressed: () => provider.toggleWatchlist(stock),
                       ),
                       onTap: () {
                          // Navigate to analysis
                       }
                    )
                 );
              }
          ),
    );
  }
}
