import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ListingService _listingService = ListingService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorilerim')),
        body: _StateMessage(
          icon: Icons.favorite_border,
          title: 'Giris yapman gerekiyor',
          message: 'Favori ilanlarini gormek icin once hesabina gir.',
          action: FilledButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            icon: const Icon(Icons.login),
            label: const Text('Giris yap'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: StreamBuilder<Set<String>>(
        stream: _userService.watchFavoriteIds(user.uid),
        builder: (context, favoriteSnapshot) {
          if (favoriteSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoriteSnapshot.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: 'Favoriler yuklenemedi',
              message: favoriteSnapshot.error.toString(),
            );
          }

          final favoriteIds = favoriteSnapshot.data ?? <String>{};

          return StreamBuilder<List<ListingModel>>(
            stream: _listingService.getListings(),
            builder: (context, listingSnapshot) {
              if (listingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (listingSnapshot.hasError) {
                return _StateMessage(
                  icon: Icons.error_outline,
                  title: 'Ilanlar yuklenemedi',
                  message: listingSnapshot.error.toString(),
                );
              }

              final allListings = listingSnapshot.data ?? [];
              final favorites = allListings
                  .where((listing) => favoriteIds.contains(listing.id))
                  .toList();

              if (favoriteIds.isEmpty || favorites.isEmpty) {
                return _StateMessage(
                  icon: Icons.favorite_outline,
                  title: 'Henuz favori ilanin yok',
                  message:
                      'Begendigin ilanlari kalp ikonuyla kaydettiginde burada goreceksin.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: favorites.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final listing = favorites[index];

                  return ListingCard(
                    listing: listing,
                    isFavorite: true,
                    onFavoriteTap: () async {
                      await _userService.removeFavorite(
                        userId: user.uid,
                        listingId: listing.id,
                      );
                    },
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(listing: listing),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppConstants.mossGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 34, color: AppConstants.forestGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppConstants.deepGreen,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.mutedText,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
