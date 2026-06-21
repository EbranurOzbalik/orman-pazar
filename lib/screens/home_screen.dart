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

      final searchableText = [
        listing.title,
        listing.description,
        listing.category,
        listing.woodType,
        listing.city,
        listing.district,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesCategory && matchesSearch;
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

              return Column(
                children: [
                  _SearchAndFilters(
                    controller: _searchController,
                    selectedCategory: _selectedCategory,
                    onSearchChanged: (value) {
                      setState(() => _searchText = value);
                    },
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
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
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final TextEditingController controller;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final categories = [AppConstants.allCategories, ...AppConstants.categories];

    return Container(
      color: AppConstants.deepGreen,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orman urunleri pazari',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Odun, tomruk, kereste ve talas ilanlarini kesfet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Baslik, sehir veya agac turu ara',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return ChoiceChip(
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
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
