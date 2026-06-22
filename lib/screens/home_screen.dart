import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../widgets/listing_card.dart';
import 'add_listing_screen.dart';
import 'listing_detail_screen.dart';
import 'login_screen.dart';
import 'my_listings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = AppConstants.allCategories;
  String _selectedCity = AppConstants.allCities;
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ListingModel> _filterListings(List<ListingModel> listings) {
    final query = _searchText.trim().toLowerCase();

    return listings.where((listing) {
      final matchesCategory =
          _selectedCategory == AppConstants.allCategories ||
          listing.category == _selectedCategory;

      final matchesCity =
          _selectedCity == AppConstants.allCities ||
          listing.city == _selectedCity;

      final searchableText = [
        listing.title,
        listing.description,
        listing.category,
        listing.woodType,
        listing.city,
        listing.district,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesCategory && matchesCity && matchesSearch;
    }).toList();
  }

  List<String> _getCities(List<ListingModel> listings) {
    final cities =
        listings
            .map((listing) => listing.city.trim())
            .where((city) => city.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return [AppConstants.allCities, ...cities];
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
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                      tooltip: 'Benim ilanlarim',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MyListingsScreen()),
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
              final cities = _getCities(allListings);

              if (!cities.contains(_selectedCity)) {
                _selectedCity = AppConstants.allCities;
              }

              return Column(
                children: [
                  _SearchAndFilters(
                    controller: _searchController,
                    selectedCategory: _selectedCategory,
                    selectedCity: _selectedCity,
                    cities: cities,
                    listingCount: allListings.length,
                    visibleCount: filteredListings.length,
                    onSearchChanged: (value) {
                      setState(() => _searchText = value);
                    },
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                    onCitySelected: (city) {
                      setState(() => _selectedCity = city);
                    },
                  ),
                  Expanded(
                    child: _ListingsContent(
                      listings: filteredListings,
                      hasAnyListing: allListings.isNotEmpty,
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
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.selectedCategory,
    required this.selectedCity,
    required this.cities,
    required this.listingCount,
    required this.visibleCount,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onCitySelected,
  });

  final TextEditingController controller;
  final String selectedCategory;
  final String selectedCity;
  final List<String> cities;
  final int listingCount;
  final int visibleCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onCitySelected;

  @override
  Widget build(BuildContext context) {
    final categories = [AppConstants.allCategories, ...AppConstants.categories];

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.deepGreen,
        border: Border(
          bottom: BorderSide(color: AppConstants.woodBrown, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Odun, tomruk, kereste ve talas ilanlarini kesfet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
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
                child: _HeroStat(
                  label: 'Toplam ilan',
                  value: listingCount.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Gorunen',
                  value: visibleCount.toString(),
                  icon: Icons.search_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            style: const TextStyle(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Baslik, sehir veya agac turu ara',
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
          const SizedBox(height: 12),
          _CityFilter(
            selectedCity: selectedCity,
            cities: cities,
            onCitySelected: onCitySelected,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
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
                    size: 17,
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

class _CityFilter extends StatelessWidget {
  const _CityFilter({
    required this.selectedCity,
    required this.cities,
    required this.onCitySelected,
  });

  final String selectedCity;
  final List<String> cities;
  final ValueChanged<String> onCitySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCity,
          isExpanded: true,
          dropdownColor: AppConstants.cardBackground,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: AppConstants.deepGreen,
            fontWeight: FontWeight.w800,
          ),
          selectedItemBuilder: (context) {
            return cities.map((city) {
              return Row(
                children: [
                  const Icon(
                    Icons.location_city_outlined,
                    color: AppConstants.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: cities.map((city) {
            return DropdownMenuItem<String>(value: city, child: Text(city));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCitySelected(value);
            }
          },
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
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

class _ListingsContent extends StatelessWidget {
  const _ListingsContent({
    required this.listings,
    required this.hasAnyListing,
    required this.onOpenListing,
  });

  final List<ListingModel> listings;
  final bool hasAnyListing;
  final ValueChanged<ListingModel> onOpenListing;

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
        message: 'Arama veya kategori filtresini degistirerek tekrar dene.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final listing = listings[index];

        return ListingCard(
          listing: listing,
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
