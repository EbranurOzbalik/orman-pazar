import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';
import '../widgets/listing_card.dart';
import 'add_listing_screen.dart';
import 'listing_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: StreamBuilder<List<ListingModel>>(
        stream: _listingService.getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              title: 'İlanlar yüklenemedi',
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
                        builder: (_) => ListingDetailScreen(listing: listing),
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
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddListingScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('İlan ekle'),
      ),
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
      color: AppConstants.cream,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Başlık, şehir veya ağaç türü ara',
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
                  selectedColor: AppConstants.forestGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  side: const BorderSide(color: AppConstants.leafGreen),
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
        title: 'Henüz ilan yok',
        message: 'İlk orman ürünleri ilanını ekleyerek başlayabilirsin.',
      );
    }

    if (listings.isEmpty) {
      return const _StateMessage(
        icon: Icons.filter_alt_off_outlined,
        title: 'Sonuç bulunamadı',
        message: 'Arama veya kategori filtresini değiştirerek tekrar dene.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
          Text('İlanlar yükleniyor...'),
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
