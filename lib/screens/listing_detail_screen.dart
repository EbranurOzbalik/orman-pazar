import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ilan detayi')),
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
                Text(
                  listing.category,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppConstants.amber,
                    fontWeight: FontWeight.w800,
                  ),
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
