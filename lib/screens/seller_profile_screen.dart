import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.phone,
  });

  final String sellerId;
  final String sellerName;
  final String phone;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ListingService _listingService = ListingService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Satici profili')),
      body: StreamBuilder<AppUserModel?>(
        stream: _userService.watchUserById(sellerId),
        builder: (context, userSnapshot) {
          final profile = userSnapshot.data;
          final displayName = profile?.displayName ?? sellerName;
          final displayPhone = profile?.phone.trim().isNotEmpty == true
              ? profile!.phone
              : phone;
          final displayEmail = profile?.email ?? '';

          return StreamBuilder<Set<String>>(
            stream: currentUser == null
                ? Stream<Set<String>>.value(<String>{})
                : _userService.watchFavoriteIds(currentUser.uid),
            builder: (context, favoriteSnapshot) {
              final favoriteIds = favoriteSnapshot.data ?? <String>{};

              return StreamBuilder<List<ListingModel>>(
                stream: _listingService.getListingsBySeller(sellerId),
                builder: (context, listingSnapshot) {
                  if (listingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (listingSnapshot.hasError) {
                    return _StateMessage(
                      icon: Icons.error_outline,
                      title: 'Satici bilgileri yuklenemedi',
                      message: listingSnapshot.error.toString(),
                    );
                  }

                  final listings = listingSnapshot.data ?? [];
                  final activeCount = listings
                      .where((listing) => listing.status == AppConstants.activeStatus)
                      .length;
                  final soldCount = listings
                      .where((listing) => listing.status == AppConstants.soldStatus)
                      .length;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _SellerHero(
                        sellerName: displayName.isEmpty ? 'Kullanici' : displayName,
                        email: displayEmail,
                        phone: displayPhone,
                        totalCount: listings.length,
                        activeCount: activeCount,
                        soldCount: soldCount,
                      ),
                      const SizedBox(height: 14),
                      _SectionPanel(
                        title: 'Satici bilgileri',
                        subtitle: 'Ilan sahibinin paylasilan temel bilgileri.',
                        children: [
                          _InfoTile(
                            icon: Icons.person_outline,
                            label: 'Ad soyad',
                            value: displayName.isEmpty ? 'Kullanici' : displayName,
                          ),
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Telefon',
                            value: displayPhone.isEmpty ? '-' : displayPhone,
                          ),
                          _InfoTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'Toplam ilan',
                            value: listings.length.toString(),
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionPanel(
                        title: 'Saticinin ilanlari',
                        subtitle: 'Bu saticinin yayinda olan ve gecmis ilanlari.',
                        children: [
                          if (listings.isEmpty)
                            const _EmptyListingsState()
                          else
                            ...listings.map((listing) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ListingCard(
                                  listing: listing,
                                  isFavorite: favoriteIds.contains(listing.id),
                                  onFavoriteTap: currentUser == null
                                      ? null
                                      : () async {
                                          await _userService.toggleFavorite(
                                            userId: currentUser.uid,
                                            listingId: listing.id,
                                            isFavorite: favoriteIds.contains(
                                              listing.id,
                                            ),
                                          );
                                        },
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ListingDetailScreen(
                                          listing: listing,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                        ],
                      ),
                    ],
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

class _SellerHero extends StatelessWidget {
  const _SellerHero({
    required this.sellerName,
    required this.email,
    required this.phone,
    required this.totalCount,
    required this.activeCount,
    required this.soldCount,
  });

  final String sellerName;
  final String email;
  final String phone;
  final int totalCount;
  final int activeCount;
  final int soldCount;

  @override
  Widget build(BuildContext context) {
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppConstants.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(sellerName),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppConstants.deepGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone.isEmpty ? 'Telefon bilgisi yok' : phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                  label: 'Toplam',
                  value: totalCount.toString(),
                  icon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Aktif',
                  value: activeCount.toString(),
                  icon: Icons.bolt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Satildi',
                  value: soldCount.toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return 'OP';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
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

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.mutedText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppConstants.mossGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConstants.forestGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppConstants.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppConstants.deepGreen,
                    fontWeight: FontWeight.w800,
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

class _EmptyListingsState extends StatelessWidget {
  const _EmptyListingsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppConstants.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: AppConstants.forestGreen,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'Bu saticinin henuz goruntulenecek ilani yok.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w700,
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
  });

  final IconData icon;
  final String title;
  final String message;

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
          ],
        ),
      ),
    );
  }
}
