import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';

class MyListingsScreen extends StatelessWidget {
  MyListingsScreen({super.key});

  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Benim ilanlarim')),
        body: _StateMessage(
          icon: Icons.lock_outline,
          title: 'Giris yapman gerekiyor',
          message: 'Kendi ilanlarini gormek icin once hesabina gir.',
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
      appBar: AppBar(title: const Text('Benim ilanlarim')),
      body: StreamBuilder<List<ListingModel>>(
        stream: _listingService.getListingsBySeller(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: 'Ilanlar yuklenemedi',
              message: snapshot.error.toString(),
            );
          }

          final listings = snapshot.data ?? [];
          if (listings.isEmpty) {
            return const _StateMessage(
              icon: Icons.add_business_outlined,
              title: 'Henuz ilanin yok',
              message: 'Ekledigin ilanlar burada duzenli sekilde listelenecek.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.deepGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.woodBrown, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppConstants.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppConstants.deepGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${listings.length} aktif ilan',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Duzenleme ve silme islemlerini ilan detayindan yapabilirsin.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.76),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...listings.map((listing) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListingCard(
                    listing: listing,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(listing: listing),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppConstants.mossGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 34, color: AppConstants.forestGreen),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppConstants.mutedText),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
