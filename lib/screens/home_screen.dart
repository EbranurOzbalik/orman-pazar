import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/listing_card.dart';
import 'add_listing_screen.dart';
import 'favorites_screen.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';
import 'map_explore_screen.dart';
import 'my_listings_screen.dart';
import 'profile_screen.dart';

enum ListingSortOption {
  newest,
  priceAscending,
  priceDescending,
  amountDescending,
}

enum DeliveryFilterOption { all, withDelivery, pickupOnly }

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
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  String _selectedCategory = AppConstants.allCategories;
  String _selectedStatus = AppConstants.allStatuses;
  String _selectedWoodType = AppConstants.allWoodTypes;
  DeliveryFilterOption _deliveryFilter = DeliveryFilterOption.all;
  ListingSortOption _sortOption = ListingSortOption.newest;
  String _searchText = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
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
    final minPrice = _parseNumber(_minPriceController.text);
    final maxPrice = _parseNumber(_maxPriceController.text);

    final filtered = listings.where((listing) {
      final matchesCategory =
          _selectedCategory == AppConstants.allCategories ||
          listing.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == AppConstants.allStatuses ||
          listing.status == _selectedStatus;
      final matchesWoodType =
          _selectedWoodType == AppConstants.allWoodTypes ||
          listing.woodType == _selectedWoodType;
      final matchesDelivery = switch (_deliveryFilter) {
        DeliveryFilterOption.all => true,
        DeliveryFilterOption.withDelivery => listing.hasDelivery,
        DeliveryFilterOption.pickupOnly => !listing.hasDelivery,
      };
      final matchesMinPrice = minPrice == null || listing.price >= minPrice;
      final matchesMaxPrice = maxPrice == null || listing.price <= maxPrice;

      final searchableText = [
        listing.title,
        listing.description,
        listing.category,
        listing.woodType,
        listing.city,
        listing.district,
      ].map(_normalizeForSearch).join(' ');

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesCategory &&
          matchesStatus &&
          matchesWoodType &&
          matchesDelivery &&
          matchesMinPrice &&
          matchesMaxPrice &&
          matchesSearch;
    }).toList();

    filtered.sort((left, right) {
      switch (_sortOption) {
        case ListingSortOption.newest:
          return right.createdAt.compareTo(left.createdAt);
        case ListingSortOption.priceAscending:
          return left.price.compareTo(right.price);
        case ListingSortOption.priceDescending:
          return right.price.compareTo(left.price);
        case ListingSortOption.amountDescending:
          return right.amount.compareTo(left.amount);
      }
    });

    return filtered;
  }

  double? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  int get _activeFilterCount {
    var count = 0;

    if (_selectedCategory != AppConstants.allCategories) {
      count++;
    }
    if (_selectedStatus != AppConstants.allStatuses) {
      count++;
    }
    if (_selectedWoodType != AppConstants.allWoodTypes) {
      count++;
    }
    if (_deliveryFilter != DeliveryFilterOption.all) {
      count++;
    }
    if (_minPriceController.text.trim().isNotEmpty) {
      count++;
    }
    if (_maxPriceController.text.trim().isNotEmpty) {
      count++;
    }
    if (_searchText.trim().isNotEmpty) {
      count++;
    }

    return count;
  }

  void _clearAdvancedFilters() {
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _selectedWoodType = AppConstants.allWoodTypes;
      _deliveryFilter = DeliveryFilterOption.all;
      _sortOption = ListingSortOption.newest;
    });
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
          nextValue
              ? 'Ilan favorilere eklendi'
              : 'Ilan favorilerden cikartildi',
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

  void _openFavorites(User? user) {
    if (user == null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FavoritesScreen()));
  }

  void _openProfile(User? user) {
    if (user == null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen()));
  }

  void _openMyListings(User? user) {
    if (user == null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyListingsScreen()));
  }

  void _openMapExplore() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MapExploreScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        return StreamBuilder<AppUserModel?>(
          stream: user == null
              ? Stream<AppUserModel?>.value(null)
              : _userService.watchUserById(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;

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
                              tooltip: 'Haritada kesfet',
                              onPressed: _openMapExplore,
                              icon: const Icon(Icons.map_outlined),
                            ),
                            IconButton(
                              tooltip: 'Favorilerim',
                              onPressed: () => _openFavorites(user),
                              icon: const Icon(Icons.favorite_border),
                            ),
                            IconButton(
                              tooltip: 'Profilim',
                              onPressed: () => _openProfile(user),
                              icon: const Icon(Icons.account_circle_outlined),
                            ),
                            IconButton(
                              tooltip: 'Benim ilanlarim',
                              onPressed: () => _openMyListings(user),
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

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _SearchAndFilters(
                              controller: _searchController,
                              minPriceController: _minPriceController,
                              maxPriceController: _maxPriceController,
                              searchFocusNode: _searchFocusNode,
                              selectedCategory: _selectedCategory,
                              selectedStatus: _selectedStatus,
                              selectedWoodType: _selectedWoodType,
                              deliveryFilter: _deliveryFilter,
                              sortOption: _sortOption,
                              listingCount: allListings.length,
                              visibleCount: filteredListings.length,
                              locationReadyCount: allListings
                                  .where((listing) => listing.hasCoordinates)
                                  .length,
                              activeFilterCount: _activeFilterCount,
                              user: user,
                              profile: profile,
                              onSearchChanged: _queueSearchUpdate,
                              onCategorySelected: (category) {
                                setState(() => _selectedCategory = category);
                              },
                              onStatusSelected: (status) {
                                setState(() => _selectedStatus = status);
                              },
                              onWoodTypeSelected: (woodType) {
                                setState(() => _selectedWoodType = woodType);
                              },
                              onDeliveryFilterChanged: (value) {
                                setState(() => _deliveryFilter = value);
                              },
                              onSortOptionChanged: (value) {
                                setState(() => _sortOption = value);
                              },
                              onPriceChanged: () => setState(() {}),
                              onClearAdvancedFilters: _clearAdvancedFilters,
                              onOpenFavorites: () => _openFavorites(user),
                              onOpenProfile: () => _openProfile(user),
                              onOpenMyListings: () => _openMyListings(user),
                              onOpenAddListing: () => _openAddListing(user),
                              onOpenLogin: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SliverToBoxAdapter(
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
                                    builder: (_) =>
                                        ListingDetailScreen(listing: listing),
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
      },
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.minPriceController,
    required this.maxPriceController,
    required this.searchFocusNode,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.selectedWoodType,
    required this.deliveryFilter,
    required this.sortOption,
    required this.listingCount,
    required this.visibleCount,
    required this.locationReadyCount,
    required this.activeFilterCount,
    required this.user,
    required this.profile,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onStatusSelected,
    required this.onWoodTypeSelected,
    required this.onDeliveryFilterChanged,
    required this.onSortOptionChanged,
    required this.onPriceChanged,
    required this.onClearAdvancedFilters,
    required this.onOpenFavorites,
    required this.onOpenProfile,
    required this.onOpenMyListings,
    required this.onOpenAddListing,
    required this.onOpenLogin,
  });

  final TextEditingController controller;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final FocusNode searchFocusNode;
  final String selectedCategory;
  final String selectedStatus;
  final String selectedWoodType;
  final DeliveryFilterOption deliveryFilter;
  final ListingSortOption sortOption;
  final int listingCount;
  final int visibleCount;
  final int locationReadyCount;
  final int activeFilterCount;
  final User? user;
  final AppUserModel? profile;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onWoodTypeSelected;
  final ValueChanged<DeliveryFilterOption> onDeliveryFilterChanged;
  final ValueChanged<ListingSortOption> onSortOptionChanged;
  final VoidCallback onPriceChanged;
  final VoidCallback onClearAdvancedFilters;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenMyListings;
  final VoidCallback onOpenAddListing;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    final categories = [AppConstants.allCategories, ...AppConstants.categories];
    final statuses = [
      AppConstants.allStatuses,
      ...AppConstants.listingStatuses,
    ];
    final woodTypes = [AppConstants.allWoodTypes, ...AppConstants.woodTypes];

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.deepGreen,
        border: Border(
          bottom: BorderSide(color: AppConstants.woodBrown, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
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
                      user == null
                          ? 'Orman urunleri pazari'
                          : 'Hos geldin, ${profile?.displayName ?? 'Orman Pazar kullanicisi'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user == null
                          ? 'Odun, tomruk, kereste ve talas ilanlarini kesfet.'
                          : _buildSignedInSubtitle(),
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
          const SizedBox(height: 8),
          _MiniStats(
            listingCount: listingCount,
            visibleCount: visibleCount,
            locationReadyCount: locationReadyCount,
          ),
          const SizedBox(height: 8),
          _HomeActionStrip(
            user: user,
            profile: profile,
            onOpenFavorites: onOpenFavorites,
            onOpenProfile: onOpenProfile,
            onOpenMyListings: onOpenMyListings,
            onOpenAddListing: onOpenAddListing,
            onOpenLogin: onOpenLogin,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SortSelector(
                  value: sortOption,
                  onChanged: onSortOptionChanged,
                ),
              ),
              const SizedBox(width: 10),
              _ActiveFilterBadge(count: activeFilterCount),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          _FilterSection(
            title: 'Ayrintili filtreler',
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderDropdownField<String>(
                          value: selectedWoodType,
                          items: woodTypes,
                          labelBuilder: (value) => value,
                          onChanged: onWoodTypeSelected,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeaderDropdownField<DeliveryFilterOption>(
                          value: deliveryFilter,
                          items: DeliveryFilterOption.values,
                          labelBuilder: _deliveryLabel,
                          onChanged: onDeliveryFilterChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onPriceChanged(),
                          style: const TextStyle(
                            color: AppConstants.deepGreen,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Min fiyat',
                            prefixIcon: Icon(Icons.south_west),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onPriceChanged(),
                          style: const TextStyle(
                            color: AppConstants.deepGreen,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Max fiyat',
                            prefixIcon: Icon(Icons.north_east),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onClearAdvancedFilters,
                      icon: const Icon(
                        Icons.refresh_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Filtreleri temizle',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
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

  String _deliveryLabel(DeliveryFilterOption option) {
    switch (option) {
      case DeliveryFilterOption.all:
        return 'Nakliye fark etmez';
      case DeliveryFilterOption.withDelivery:
        return 'Nakliye var';
      case DeliveryFilterOption.pickupOnly:
        return 'Teslim alinir';
    }
  }

  String _buildSignedInSubtitle() {
    final mode = profile?.userMode ?? AppConstants.buyerSellerMode;
    final label = AppConstants.userModeLabel(mode);
    return '$label modunda kesfet, favori topla ve ilan akisini hizli yonet.';
  }
}

class _HomeActionStrip extends StatelessWidget {
  const _HomeActionStrip({
    required this.user,
    required this.profile,
    required this.onOpenFavorites,
    required this.onOpenProfile,
    required this.onOpenMyListings,
    required this.onOpenAddListing,
    required this.onOpenLogin,
  });

  final User? user;
  final AppUserModel? profile;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenMyListings;
  final VoidCallback onOpenAddListing;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    final mode = profile?.userMode ?? AppConstants.buyerSellerMode;
    final modeLabel = user == null
        ? 'Misafir'
        : 'Mod: ${AppConstants.userModeLabel(mode)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SignalChip(
              icon: AppConstants.userModeIcon(mode),
              label: modeLabel,
            ),
            _SignalChip(
              icon: Icons.verified_user_outlined,
              label: user == null
                  ? 'Giris gerekli'
                  : 'Guven ${profile?.trustScore ?? 0}/3',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CompactActionButton(
              icon: user == null ? Icons.login : Icons.favorite_outline,
              label: user == null ? 'Giris yap' : 'Favorilerim',
              onTap: user == null ? onOpenLogin : onOpenFavorites,
            ),
            _CompactActionButton(
              icon: user == null
                  ? Icons.person_add_alt_1_outlined
                  : Icons.inventory_2_outlined,
              label: user == null ? 'Hesap ac' : 'Benim ilanlarim',
              onTap: user == null ? onOpenLogin : onOpenMyListings,
            ),
            _CompactActionButton(
              icon: user == null ? Icons.lock_open_outlined : Icons.add_box,
              label: user == null ? 'Profil' : 'Ilan ekle',
              onTap: user == null ? onOpenLogin : onOpenAddListing,
            ),
          ],
        ),
        if (user != null) ...[
          const SizedBox(height: 8),
          _HomeSecondaryRow(
            onOpenProfile: onOpenProfile,
            onOpenMyListings: onOpenMyListings,
          ),
        ],
      ],
    );
  }
}

class _HomeSecondaryRow extends StatelessWidget {
  const _HomeSecondaryRow({
    required this.onOpenProfile,
    required this.onOpenMyListings,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenMyListings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onOpenProfile,
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
          label: const Text(
            'Profilim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onOpenMyListings,
          icon: const Icon(Icons.analytics_outlined, color: Colors.white),
          label: const Text(
            'Ilan paneli',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppConstants.amber, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: AppConstants.amber),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _SortSelector extends StatelessWidget {
  const _SortSelector({required this.value, required this.onChanged});

  final ListingSortOption value;
  final ValueChanged<ListingSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ListingSortOption>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          iconEnabledColor: AppConstants.forestGreen,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppConstants.deepGreen,
            fontWeight: FontWeight.w700,
          ),
          items: ListingSortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(_labelFor(option)),
            );
          }).toList(),
          onChanged: (nextValue) {
            if (nextValue != null) {
              onChanged(nextValue);
            }
          },
        ),
      ),
    );
  }

  String _labelFor(ListingSortOption option) {
    switch (option) {
      case ListingSortOption.newest:
        return 'Siralama: En yeni';
      case ListingSortOption.priceAscending:
        return 'Siralama: Fiyat artan';
      case ListingSortOption.priceDescending:
        return 'Siralama: Fiyat azalan';
      case ListingSortOption.amountDescending:
        return 'Siralama: Miktar coktan aza';
    }
  }
}

class _ActiveFilterBadge extends StatelessWidget {
  const _ActiveFilterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: count > 0
            ? AppConstants.amber
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count > 0
              ? AppConstants.amber
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        count > 0 ? '$count filtre aktif' : 'Hazir',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: count > 0 ? AppConstants.deepGreen : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeaderDropdownField<T> extends StatelessWidget {
  const _HeaderDropdownField({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          iconEnabledColor: AppConstants.forestGreen,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppConstants.deepGreen,
            fontWeight: FontWeight.w700,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (nextValue) {
            if (nextValue != null) {
              onChanged(nextValue);
            }
          },
        ),
      ),
    );
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
  const _MiniStats({
    required this.listingCount,
    required this.visibleCount,
    required this.locationReadyCount,
  });

  final int listingCount;
  final int visibleCount;
  final int locationReadyCount;

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('•', style: TextStyle(color: Colors.white70)),
          ),
          const Icon(Icons.map_outlined, color: AppConstants.amber, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$locationReadyCount haritaya hazir',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
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

    final featuredListings = listings
        .where((listing) => listing.status == AppConstants.activeStatus)
        .take(5)
        .toList();
    final categoryItems = _buildCategoryItems(listings);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
      children: [
        if (featuredListings.isNotEmpty) ...[
          _FeaturedListingsSection(
            listings: featuredListings,
            favoriteIds: favoriteIds,
            onOpenListing: onOpenListing,
            onFavoriteTap: onFavoriteTap,
          ),
          const SizedBox(height: 14),
        ],
        if (categoryItems.isNotEmpty) ...[
          _CategoryPulseSection(items: categoryItems),
          const SizedBox(height: 14),
        ],
        _ListingsHeadline(totalCount: listings.length),
        const SizedBox(height: 12),
        ...listings.map((listing) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ListingCard(
              listing: listing,
              isFavorite: favoriteIds.contains(listing.id),
              onFavoriteTap: () => onFavoriteTap(listing),
              onTap: () => onOpenListing(listing),
            ),
          );
        }),
      ],
    );
  }

  List<_CategoryPulseItem> _buildCategoryItems(List<ListingModel> source) {
    final counts = <String, int>{};
    for (final listing in source) {
      counts.update(listing.category, (value) => value + 1, ifAbsent: () => 1);
    }

    final items = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    return items
        .take(4)
        .map(
          (entry) => _CategoryPulseItem(
            category: entry.key,
            count: entry.value,
            icon: _categoryIcon(entry.key),
            color: _categoryColor(entry.key),
          ),
        )
        .toList();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Yakacak Odun':
        return AppConstants.clay;
      case 'Kereste':
        return AppConstants.woodBrown;
      case 'Tomruk':
        return AppConstants.forestGreen;
      case 'Talas':
        return AppConstants.sage;
      default:
        return AppConstants.leafGreen;
    }
  }
}

class _FeaturedListingsSection extends StatelessWidget {
  const _FeaturedListingsSection({
    required this.listings,
    required this.favoriteIds,
    required this.onOpenListing,
    required this.onFavoriteTap,
  });

  final List<ListingModel> listings;
  final Set<String> favoriteIds;
  final ValueChanged<ListingModel> onOpenListing;
  final ValueChanged<ListingModel> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.auto_awesome_outlined,
      title: 'One cikan ilanlar',
      subtitle:
          'Aktif ve dikkat ceken ilanlari hizlica tara, sonra tum listeye gec.',
      child: SizedBox(
        height: 224,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: listings.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final listing = listings[index];

            return SizedBox(
              width: 240,
              child: _FeaturedListingCard(
                listing: listing,
                isFavorite: favoriteIds.contains(listing.id),
                onTap: () => onOpenListing(listing),
                onFavoriteTap: () => onFavoriteTap(listing),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeaturedListingCard extends StatelessWidget {
  const _FeaturedListingCard({
    required this.listing,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final ListingModel listing;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColor(listing.category);

    return Material(
      color: AppConstants.cream,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (listing.imageUrls.isNotEmpty)
                      Image.network(
                        listing.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _FeaturedImageFallback(
                          icon: _categoryIcon(listing.category),
                        ),
                      )
                    else
                      _FeaturedImageFallback(
                        icon: _categoryIcon(listing.category),
                      ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          listing.category,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: onFavoriteTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppConstants.clay
                                  : AppConstants.deepGreen,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 4, color: accent),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppConstants.deepGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppConstants.mutedText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${listing.city} / ${listing.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppConstants.mutedText,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_formatNumber(listing.amount)} ${listing.unit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppConstants.deepGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatNumber(listing.price)} TL',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppConstants.woodBrown,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  IconData _categoryIcon(String category) {
    switch (category) {
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Yakacak Odun':
        return AppConstants.clay;
      case 'Kereste':
        return AppConstants.woodBrown;
      case 'Tomruk':
        return AppConstants.forestGreen;
      case 'Talas':
        return AppConstants.sage;
      default:
        return AppConstants.leafGreen;
    }
  }
}

class _FeaturedImageFallback extends StatelessWidget {
  const _FeaturedImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppConstants.mossGreen,
      child: Center(
        child: Icon(icon, color: AppConstants.forestGreen, size: 34),
      ),
    );
  }
}

class _CategoryPulseSection extends StatelessWidget {
  const _CategoryPulseSection({required this.items});

  final List<_CategoryPulseItem> items;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.hub_outlined,
      title: 'Kategori nabzi',
      subtitle: 'Bugun listede en cok gorunen urun gruplari.',
      child: Row(
        children: items.map((item) {
          final isLast = item == items.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 10),
              child: _CategoryPulseCard(item: item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryPulseCard extends StatelessWidget {
  const _CategoryPulseCard({required this.item});

  final _CategoryPulseItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 18),
          const SizedBox(height: 10),
          Text(
            item.count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.category,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsHeadline extends StatelessWidget {
  const _ListingsHeadline({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tum ilanlar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppConstants.deepGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalCount ilan arasindan detaylari inceleyebilirsin.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Liste',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppConstants.woodBrown,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CategoryPulseItem {
  const _CategoryPulseItem({
    required this.category,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String category;
  final int count;
  final IconData icon;
  final Color color;
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
        child: AppEmptyStateCard(icon: icon, title: title, message: message),
      ),
    );
  }
}
