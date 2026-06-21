import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import 'edit_listing_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  ListingDetailScreen({super.key, required this.listing});

  final ListingModel listing;
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();

  Future<void> _openEditScreen(BuildContext context) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditListingScreen(listing: listing)),
    );

    if (wasUpdated == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteListing(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ilani sil'),
          content: const Text('Bu ilani silmek istedigine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgec'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _listingService.deleteListing(listing.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ilan silindi')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ilan silinemedi: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isOwner = user != null && user.uid == listing.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilan detayi'),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditScreen(context);
                }
                if (value == 'delete') {
                  _deleteListing(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Duzenle'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppConstants.deepGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      listing.category,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppConstants.amber,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Senin ilanin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  listing.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${listing.city} / ${listing.district}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoPanel(
            children: [
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Fiyat',
                value: '${_formatNumber(listing.price)} TL',
              ),
              _DetailRow(
                icon: Icons.inventory_2_outlined,
                label: 'Miktar',
                value: '${_formatNumber(listing.amount)} ${listing.unit}',
              ),
              _DetailRow(
                icon: Icons.park_outlined,
                label: 'Agac turu',
                value: listing.woodType,
              ),
              _DetailRow(
                icon: Icons.water_drop_outlined,
                label: 'Nem durumu',
                value: listing.moistureStatus,
              ),
              _DetailRow(
                icon: Icons.local_shipping_outlined,
                label: 'Nakliye',
                value: listing.hasDelivery ? 'Var' : 'Yok',
              ),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Telefon',
                value: listing.phone,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoPanel(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aciklama',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppConstants.deepGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listing.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.deepGreen,
                  height: 1.35,
                ),
              ),
            ],
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

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.children});

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
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppConstants.mossGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConstants.forestGreen, size: 19),
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
                const SizedBox(height: 2),
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
