import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  final ListingModel listing;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(listing.category);
    final categoryIcon = _categoryIcon(listing.category);
    final statusColor = AppConstants.listingStatusColor(listing.status);

    return Opacity(
      opacity: listing.status == AppConstants.soldStatus ? 0.9 : 1,
      child: Material(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.border),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.deepGreen.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ListingCoverImage(
                  imageUrl: listing.imageUrls.isEmpty
                      ? null
                      : listing.imageUrls.first,
                  imageCount: listing.imageUrls.length,
                  statusText: listing.status,
                ),
                Container(height: 5, color: categoryColor),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(categoryIcon, color: categoryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        listing.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: AppConstants.deepGreen,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (onFavoriteTap != null)
                                      _FavoriteButton(
                                        isFavorite: isFavorite,
                                        onTap: onFavoriteTap!,
                                      ),
                                    if (onFavoriteTap == null)
                                      const SizedBox(width: 6),
                                    _StatusBadge(
                                      text: listing.status,
                                      color: statusColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppConstants.mutedText,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${listing.city} / ${listing.district}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppConstants.mutedText,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: AppConstants.mutedText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            text: listing.category,
                            color: categoryColor,
                          ),
                          _InfoChip(text: listing.woodType),
                          _InfoChip(text: listing.moistureStatus),
                          if (listing.hasDelivery)
                            const _InfoChip(
                              text: 'Nakliye',
                              icon: Icons.local_shipping_outlined,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: 'Miktar',
                                value:
                                    '${_formatNumber(listing.amount)} ${listing.unit}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Fiyat',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppConstants.mutedText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatNumber(listing.price)} TL',
                                  style: Theme.of(context).textTheme.titleLarge
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
              ],
            ),
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

class _ListingCoverImage extends StatelessWidget {
  const _ListingCoverImage({
    required this.imageUrl,
    required this.imageCount,
    required this.statusText,
  });

  final String? imageUrl;
  final int imageCount;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 148,
        width: double.infinity,
        color: AppConstants.mossGreen,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppConstants.forestGreen,
              size: 34,
            ),
            SizedBox(height: 8),
            Text(
              'Gorsel eklendiginde burada gorunecek',
              style: TextStyle(
                color: AppConstants.deepGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 148,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return Container(
                color: AppConstants.mossGreen,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: AppConstants.forestGreen,
                      size: 34,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gorsel yuklenemedi',
                      style: TextStyle(
                        color: AppConstants.deepGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }

              return Container(
                color: AppConstants.mossGreen,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.34),
                ],
              ),
            ),
          ),
          if (imageCount > 1)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$imageCount gorsel',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: (isFavorite ? AppConstants.clay : AppConstants.cream),
        borderRadius: BorderRadius.circular(999),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isFavorite ? 'Favoriden cikar' : 'Favorilere ekle',
        onPressed: onTap,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite ? Colors.white : AppConstants.woodBrown,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppConstants.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppConstants.deepGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.text,
    this.color = AppConstants.forestGreen,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppConstants.listingStatusIcon(text), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
