import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';

class MyListingsScreen extends StatelessWidget {
  MyListingsScreen({super.key});

  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  final UserService _userService = UserService();

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

          final listings = listingSnapshot.data ?? [];

          return StreamBuilder<AppUserModel?>(
            stream: _userService.watchUserById(user.uid),
            builder: (context, userSnapshot) {
              final hasProfileAccess = !userSnapshot.hasError;
              final profile = userSnapshot.data;

              if (listings.isEmpty) {
                return _StateMessage(
                  icon: Icons.add_business_outlined,
                  title: 'Henuz ilanin yok',
                  message:
                      'Yeni bir ilan eklediginde burada duzenli bir koleksiyon olarak gorunecek.',
                  header: _MyListingsHero(
                    profile: profile,
                    listings: listings,
                    isEmpty: true,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _MyListingsHero(
                    profile: profile,
                    listings: listings,
                    isEmpty: false,
                  ),
                  if (!hasProfileAccess) ...[
                    const SizedBox(height: 12),
                    const _ProfileAccessHint(),
                  ],
                  const SizedBox(height: 14),
                  ...listings.map((listing) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ListingCard(
                        listing: listing,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MyListingsHero extends StatelessWidget {
  const _MyListingsHero({
    required this.profile,
    required this.listings,
    required this.isEmpty,
  });

  final AppUserModel? profile;
  final List<ListingModel> listings;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? 'Hesabin';
    final email = profile?.email ?? '';
    final total = listings.length;
    final categories = listings
        .map((listing) => listing.category)
        .toSet()
        .length;

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.deepGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.woodBrown, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppConstants.deepGreen.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppConstants.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppConstants.deepGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty
                          ? 'Ilanlarini buradan yonetebilirsin.'
                          : email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Aktif ilan',
                  value: total.toString(),
                  icon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Kategori',
                  value: isEmpty ? '0' : categories.toString(),
                  icon: Icons.category_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isEmpty
                ? 'Hesabin hazir. Simdi ilk ilanini ekleyip koleksiyonunu olusturabilirsin.'
                : 'Duzenleme ve silme islemlerini ilan detayindan yonetebilirsin.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAccessHint extends StatelessWidget {
  const _ProfileAccessHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppConstants.woodBrown,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profil dokumanina erisim sinirli oldugu icin ust alanda temel hesap verisi kullaniliyor.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.deepGreen,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    this.header,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (header != null) ...[header!, const SizedBox(height: 28)],
        Container(
          decoration: BoxDecoration(
            color: AppConstants.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppConstants.mossGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 34, color: AppConstants.forestGreen),
              ),
              const SizedBox(height: 14),
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
      ],
    );
  }
}
