import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/listing_card.dart';
import 'add_listing_screen.dart';
import 'favorites_screen.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';
import 'my_listings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  String _selectedCategory = AppConstants.allCategories;
  String _selectedStatus = AppConstants.allStatuses;
  String _searchText = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _queueSearchUpdate(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchText = value);
      }
    });
  }

  String _normalizeForSearch(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('\u0307', '')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  List<ListingModel> _filterListings(List<ListingModel> listings) {
    final query = _normalizeForSearch(_searchText);

    return listings.where((listing) {
      final matchesCategory =
          _selectedCategory == AppConstants.allCategories ||
          listing.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == AppConstants.allStatuses ||
          listing.status == _selectedStatus;

      final searchableText = [
        listing.title,
        listing.description,
        listing.category,
        listing.woodType,
        listing.city,
        listing.district,
      ].map(_normalizeForSearch).join(' ');

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesCategory && matchesStatus && matchesSearch;
    }).toList();
  }

  void _openAddListing(User? user) {
    if (user == null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddListingScreen()));
  }

  Future<void> _toggleFavorite({
    required User? user,
    required ListingModel listing,
    required bool isFavorite,
  }) async {
    if (user == null) {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final nextValue = await _userService.toggleFavorite(
      userId: user.uid,
      listingId: listing.id,
      isFavorite: isFavorite,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextValue ? 'Ilan favorilere eklendi' : 'Ilan favorilerden cikartildi',
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cikis yapildi')));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        return StreamBuilder<Set<String>>(
          stream: user == null
              ? Stream<Set<String>>.value(<String>{})
              : _userService.watchFavoriteIds(user.uid),
          builder: (context, favoritesSnapshot) {
            final favoriteIds = favoritesSnapshot.data ?? <String>{};

            return Scaffold(
              appBar: AppBar(
                title: const Text(AppConstants.appName),
                actions: [
                  if (user == null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          'Giris',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Favorilerim',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FavoritesScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                        ),
                        IconButton(
                          tooltip: 'Profilim',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.account_circle_outlined),
                        ),
                        IconButton(
                          tooltip: 'Benim ilanlarim',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MyListingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                        IconButton(
                          tooltip: 'Cikis yap',
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                        ),
                      ],
                    ),
                ],
              ),
              body: StreamBuilder<List<ListingModel>>(
                stream: _listingService.getListings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingState();
                  }

                  if (snapshot.hasError) {
                    return _StateMessage(
                      icon: Icons.error_outline,
                      title: 'Ilanlar yuklenemedi',
                      message: snapshot.error.toString(),
                    );
                  }

                  final allListings = snapshot.data ?? [];
                  final filteredListings = _filterListings(allListings);

                  return Column(
                    children: [
                      _SearchAndFilters(
                        controller: _searchController,
                        searchFocusNode: _searchFocusNode,
                        selectedCategory: _selectedCategory,
                        selectedStatus: _selectedStatus,
                        listingCount: allListings.length,
                        visibleCount: filteredListings.length,
                        onSearchChanged: _queueSearchUpdate,
                        onCategorySelected: (category) {
                          setState(() => _selectedCategory = category);
                        },
                        onStatusSelected: (status) {
                          setState(() => _selectedStatus = status);
                        },
                      ),
                      Expanded(
                        child: _ListingsContent(
                          listings: filteredListings,
                          favoriteIds: favoriteIds,
                          hasAnyListing: allListings.isNotEmpty,
                          onFavoriteTap: (listing) {
                            _toggleFavorite(
                              user: user,
                              listing: listing,
                              isFavorite: favoriteIds.contains(listing.id),
                            );
                          },
                          onOpenListing: (listing) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(
                                  listing: listing,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openAddListing(user),
                icon: const Icon(Icons.add),
                label: const Text('Ilan ekle'),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.searchFocusNode,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.listingCount,
    required this.visibleCount,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onStatusSelected,
  });

  final TextEditingController controller;
  final FocusNode searchFocusNode;
  final String selectedCategory;
  final String selectedStatus;
  final int listingCount;
  final int visibleCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final categories = [AppConstants.allCategories, ...AppConstants.categories];
    final statuses = [AppConstants.allStatuses, ...AppConstants.listingStatuses];

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.deepGreen,
        border: Border(
          bottom: BorderSide(color: AppConstants.woodBrown, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConstants.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.forest_outlined,
                  color: AppConstants.deepGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orman urunleri pazari',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Odun, tomruk, kereste ve talas ilanlarini kesfet.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 10),
          _MiniStats(listingCount: listingCount, visibleCount: visibleCount),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            focusNode: searchFocusNode,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Baslik, sehir, ilce veya agac turu ara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayi temizle',
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 10),
          _FilterSection(
            title: 'Kategori',
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;

                  return ChoiceChip(
                    avatar: Icon(
                      _categoryIcon(category),
                      size: 16,
                      color: isSelected
                          ? AppConstants.deepGreen
                          : AppConstants.forestGreen,
                    ),
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => onCategorySelected(category),
                    selectedColor: AppConstants.amber,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppConstants.deepGreen
                          : AppConstants.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppConstants.amber : Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FilterSection(
            title: 'Durum',
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: statuses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final isSelected = status == selectedStatus;
                  final chipColor = status == AppConstants.allStatuses
                      ? Colors.white
                      : AppConstants.listingStatusColor(status);

                  return ChoiceChip(
                    avatar: Icon(
                      status == AppConstants.allStatuses
                          ? Icons.tune_outlined
                          : AppConstants.listingStatusIcon(status),
                      size: 16,
                      color: isSelected
                          ? AppConstants.deepGreen
                          : chipColor == Colors.white
                          ? AppConstants.forestGreen
                          : chipColor,
                    ),
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => onStatusSelected(status),
                    selectedColor: AppConstants.amber,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppConstants.deepGreen
                          : chipColor == Colors.white
                          ? AppConstants.forestGreen
                          : chipColor,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppConstants.amber : Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case AppConstants.allCategories:
        return Icons.grid_view_outlined;
      case 'Yakacak Odun':
        return Icons.local_fire_department_outlined;
      case 'Kereste':
        return Icons.carpenter_outlined;
      case 'Tomruk':
        return Icons.forest_outlined;
      case 'Talas':
        return Icons.grass_outlined;
      default:
        return Icons.eco_outlined;
    }
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MiniStats extends StatelessWidget {
  const _MiniStats({required this.listingCount, required this.visibleCount});

  final int listingCount;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: AppConstants.amber,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$listingCount toplam',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('•', style: TextStyle(color: Colors.white70)),
          ),
          const Icon(
            Icons.search_outlined,
            color: AppConstants.amber,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$visibleCount gorunen',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsContent extends StatelessWidget {
  const _ListingsContent({
    required this.listings,
    required this.favoriteIds,
    required this.hasAnyListing,
    required this.onOpenListing,
    required this.onFavoriteTap,
  });

  final List<ListingModel> listings;
  final Set<String> favoriteIds;
  final bool hasAnyListing;
  final ValueChanged<ListingModel> onOpenListing;
  final ValueChanged<ListingModel> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyListing) {
      return const _StateMessage(
        icon: Icons.forest_outlined,
        title: 'Henuz ilan yok',
        message: 'Ilk orman urunleri ilanini ekleyerek baslayabilirsin.',
      );
    }

    if (listings.isEmpty) {
      return const _StateMessage(
        icon: Icons.filter_alt_off_outlined,
        title: 'Sonuc bulunamadi',
        message: 'Arama veya filtreleri degistirerek tekrar dene.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final listing = listings[index];

        return ListingCard(
          listing: listing,
          isFavorite: favoriteIds.contains(listing.id),
          onFavoriteTap: () => onFavoriteTap(listing),
          onTap: () => onOpenListing(listing),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Ilanlar yukleniyor...'),
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
            Icon(icon, size: 48, color: AppConstants.leafGreen),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}
