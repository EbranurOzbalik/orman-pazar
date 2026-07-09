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

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  final UserService _userService = UserService();

  String _selectedStatus = AppConstants.allStatuses;

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
          final filteredListings = _filterListings(listings);

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
                    filteredCount: filteredListings.length,
                    selectedStatus: _selectedStatus,
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
                    filteredCount: filteredListings.length,
                    selectedStatus: _selectedStatus,
                    isEmpty: false,
                  ),
                  const SizedBox(height: 14),
                  _SellerDashboard(
                    listings: listings,
                    selectedStatus: _selectedStatus,
                    onStatusSelected: (status) {
                      setState(() => _selectedStatus = status);
                    },
                  ),
                  if (!hasProfileAccess) ...[
                    const SizedBox(height: 12),
                    const _ProfileAccessHint(),
                  ],
                  const SizedBox(height: 14),
                  if (filteredListings.isEmpty)
                    _EmptyFilteredState(
                      selectedStatus: _selectedStatus,
                      onReset: () {
                        setState(
                          () => _selectedStatus = AppConstants.allStatuses,
                        );
                      },
                    )
                  else
                    ...filteredListings.map((listing) {
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

  List<ListingModel> _filterListings(List<ListingModel> listings) {
    if (_selectedStatus == AppConstants.allStatuses) {
      return listings;
    }

    return listings
        .where((listing) => listing.status == _selectedStatus)
        .toList();
  }
}

class _MyListingsHero extends StatelessWidget {
  const _MyListingsHero({
    required this.profile,
    required this.listings,
    required this.filteredCount,
    required this.selectedStatus,
    required this.isEmpty,
  });

  final AppUserModel? profile;
  final List<ListingModel> listings;
  final int filteredCount;
  final String selectedStatus;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? 'Hesabin';
    final email = profile?.email ?? '';
    final total = listings.length;
    final activeCount = listings
        .where((listing) => listing.status == AppConstants.activeStatus)
        .length;
    final reservedCount = listings
        .where((listing) => listing.status == AppConstants.reservedStatus)
        .length;
    final soldCount = listings
        .where((listing) => listing.status == AppConstants.soldStatus)
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
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            children: [
              _HeroMetric(
                label: 'Toplam ilan',
                value: total.toString(),
                icon: Icons.storefront_outlined,
              ),
              _HeroMetric(
                label: 'Aktif',
                value: activeCount.toString(),
                icon: Icons.bolt_outlined,
              ),
              _HeroMetric(
                label: 'Rezerve',
                value: reservedCount.toString(),
                icon: Icons.schedule_outlined,
              ),
              _HeroMetric(
                label: 'Satildi',
                value: soldCount.toString(),
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isEmpty
                ? 'Hesabin hazir. Simdi ilk ilanini ekleyip koleksiyonunu olusturabilirsin.'
                : selectedStatus == AppConstants.allStatuses
                ? '$filteredCount ilan listeleniyor. Durum filtreleriyle panelini hizli yonetebilirsin.'
                : '$selectedStatus durumundaki $filteredCount ilan gorunuyor.',
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

class _SellerDashboard extends StatelessWidget {
  const _SellerDashboard({
    required this.listings,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final List<ListingModel> listings;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final totalValue = listings.fold<double>(
      0,
      (sum, listing) => sum + listing.price,
    );
    final totalAmount = listings.fold<double>(
      0,
      (sum, listing) => sum + listing.amount,
    );
    final activeValue = listings
        .where((listing) => listing.status == AppConstants.activeStatus)
        .fold<double>(0, (sum, listing) => sum + listing.price);
    final statusItems = [
      AppConstants.allStatuses,
      ...AppConstants.listingStatuses,
    ];

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppConstants.mossGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppConstants.forestGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Satici paneli',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppConstants.deepGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ilan durumlarini izle, portfoyunu ozetle ve listeyi hizli filtrele.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Toplam portfoy',
                  value: '${_formatNumber(totalValue)} TL',
                  caption: 'Tum ilan fiyatlari',
                  color: AppConstants.woodBrown,
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Aktif deger',
                  value: '${_formatNumber(activeValue)} TL',
                  caption: 'Yayindaki ilanlar',
                  color: AppConstants.leafGreen,
                  icon: Icons.trending_up_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Toplam miktar',
                  value: _formatNumber(totalAmount),
                  caption: 'Birlesik stok gorunumu',
                  color: AppConstants.forestGreen,
                  icon: Icons.scale_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Hizli filtre',
                  value: selectedStatus,
                  caption: 'Durum bazli listeleme',
                  color: AppConstants.amber,
                  icon: Icons.filter_alt_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Duruma gore gorunum',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusItems.map((status) {
              final isSelected = status == selectedStatus;
              final chipColor = status == AppConstants.allStatuses
                  ? AppConstants.forestGreen
                  : AppConstants.listingStatusColor(status);

              return ChoiceChip(
                label: Text(status),
                avatar: Icon(
                  status == AppConstants.allStatuses
                      ? Icons.grid_view_outlined
                      : AppConstants.listingStatusIcon(status),
                  size: 16,
                  color: isSelected ? AppConstants.deepGreen : chipColor,
                ),
                selected: isSelected,
                onSelected: (_) => onStatusSelected(status),
                selectedColor: AppConstants.amber,
                backgroundColor: AppConstants.cream,
                side: BorderSide(
                  color: isSelected ? AppConstants.amber : AppConstants.border,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppConstants.deepGreen : chipColor,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.mutedText,
              height: 1.3,
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

class _EmptyFilteredState extends StatelessWidget {
  const _EmptyFilteredState({
    required this.selectedStatus,
    required this.onReset,
  });

  final String selectedStatus;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppConstants.mossGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.filter_alt_off_outlined,
              color: AppConstants.forestGreen,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$selectedStatus durumunda ilan bulunamadi',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Baska bir durum secerek ya da tum ilanlara donerek listeyi tekrar inceleyebilirsin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Tum ilanlari goster'),
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
