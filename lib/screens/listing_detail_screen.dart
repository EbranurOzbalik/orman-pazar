import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan detayı')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppConstants.forestGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                    icon: Icons.location_on_outlined,
                    label: 'Konum',
                    value: '${listing.city} / ${listing.district}',
                  ),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: listing.category,
                  ),
                  _DetailRow(
                    icon: Icons.park_outlined,
                    label: 'Ağaç türü',
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
            ),
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
          Icon(icon, color: AppConstants.leafGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppConstants.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
