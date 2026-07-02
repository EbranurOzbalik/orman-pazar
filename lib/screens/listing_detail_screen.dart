import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import 'edit_listing_screen.dart';
import 'login_screen.dart';
import 'seller_profile_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final ListingModel listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  final UserService _userService = UserService();

  Future<void> _openEditScreen(BuildContext context) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditListingScreen(listing: widget.listing),
      ),
    );

    if (wasUpdated == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openSellerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SellerProfileScreen(
          sellerId: widget.listing.sellerId,
          sellerName: widget.listing.sellerName,
          phone: widget.listing.phone,
        ),
      ),
    );
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
      await _listingService.deleteListing(widget.listing.id);

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

  Future<void> _toggleFavorite({required bool isFavorite}) async {
    final user = _authService.currentUser;
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
      listingId: widget.listing.id,
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isOwner = user != null && user.uid == widget.listing.sellerId;

    return StreamBuilder<Set<String>>(
      stream: user == null
          ? Stream<Set<String>>.value(<String>{})
          : _userService.watchFavoriteIds(user.uid),
      builder: (context, favoriteSnapshot) {
        final favoriteIds = favoriteSnapshot.data ?? <String>{};
        final isFavorite = favoriteIds.contains(widget.listing.id);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ilan detayi'),
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Favoriden cikar' : 'Favorilere ekle',
                onPressed: () => _toggleFavorite(isFavorite: isFavorite),
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ImageGalleryPanel(imageUrls: widget.listing.imageUrls),
              const SizedBox(height: 14),
              _DetailHero(
                listing: widget.listing,
                isOwner: isOwner,
                isFavorite: isFavorite,
              ),
              const SizedBox(height: 14),
              _ContactPanel(
                listing: widget.listing,
                onOpenSellerProfile: () => _openSellerProfile(context),
              ),
              const SizedBox(height: 14),
              _InfoPanel(
                title: 'Ilan bilgileri',
                subtitle: 'Urunun temel ozellikleri ve satis ayrintilari.',
                children: [
                  _DetailRow(
                    icon: Icons.favorite_outline,
                    label: 'Favori durumu',
                    value: isFavorite ? 'Kaydedildi' : 'Kayitli degil',
                    valueColor: isFavorite ? AppConstants.clay : null,
                  ),
                  _DetailRow(
                    icon: Icons.bolt_outlined,
                    label: 'Durum',
                    value: widget.listing.status,
                    valueColor: AppConstants.listingStatusColor(
                      widget.listing.status,
                    ),
                  ),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Satici',
                    value: widget.listing.sellerName.isEmpty
                        ? 'Kullanici'
                        : widget.listing.sellerName,
                    onTap: () => _openSellerProfile(context),
                  ),
                  _DetailRow(
                    icon: Icons.park_outlined,
                    label: 'Agac turu',
                    value: widget.listing.woodType,
                  ),
                  _DetailRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Nem durumu',
                    value: widget.listing.moistureStatus,
                  ),
                  _DetailRow(
                    icon: Icons.local_shipping_outlined,
                    label: 'Nakliye',
                    value: widget.listing.hasDelivery ? 'Var' : 'Yok',
                  ),
                  _DetailRow(
                    icon: Icons.sell_outlined,
                    label: 'Kategori',
                    value: widget.listing.category,
                  ),
                  _DetailRow(
                    icon: Icons.scale_outlined,
                    label: 'Olcu',
                    value:
                        '${_formatNumber(widget.listing.amount)} ${widget.listing.unit}',
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoPanel(
                title: 'Aciklama',
                subtitle: 'Saticinin urun icin ekledigi notlar.',
                children: [
                  Text(
                    widget.listing.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConstants.deepGreen,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _ImageGalleryPanel extends StatelessWidget {
  const _ImageGalleryPanel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppConstants.mossGreen,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppConstants.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: AppConstants.forestGreen,
              size: 42,
            ),
            SizedBox(height: 10),
            Text(
              'Bu ilan icin henuz gorsel eklenmedi',
              style: TextStyle(
                color: AppConstants.deepGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              color: AppConstants.mossGreen,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: AppConstants.forestGreen,
                          size: 42,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Gorsel yuklenemedi',
                          style: TextStyle(
                            color: AppConstants.deepGreen,
                            fontWeight: FontWeight.w700,
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

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.listing,
    required this.isOwner,
    required this.isFavorite,
  });

  final ListingModel listing;
  final bool isOwner;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppConstants.listingStatusColor(listing.status);

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeroChip(
                icon: _categoryIcon(listing.category),
                text: listing.category,
              ),
              _HeroChip(
                icon: AppConstants.listingStatusIcon(listing.status),
                text: listing.status,
                accentColor: statusColor,
              ),
              if (isFavorite)
                const _HeroChip(
                  icon: Icons.favorite,
                  text: 'Favorinde',
                  accentColor: AppConstants.clay,
                ),
              if (isOwner)
                const _HeroChip(
                  icon: Icons.verified_user_outlined,
                  text: 'Senin ilanin',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            listing.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.1,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Fiyat',
                  value: '${_formatNumber(listing.price)} TL',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Miktar',
                  value: '${_formatNumber(listing.amount)} ${listing.unit}',
                  icon: Icons.inventory_2_outlined,
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
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.text,
    this.accentColor = AppConstants.amber,
  });

  final IconData icon;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _ContactPanel extends StatelessWidget {
  const _ContactPanel({
    required this.listing,
    required this.onOpenSellerProfile,
  });

  final ListingModel listing;
  final VoidCallback onOpenSellerProfile;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppConstants.listingStatusColor(listing.status);

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.mossGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.call_outlined,
                  color: AppConstants.forestGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iletisim',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppConstants.deepGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.phone,
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenSellerProfile,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Saticinin diger ilanlari'),
          ),
          if (listing.status != AppConstants.activeStatus) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    AppConstants.listingStatusIcon(listing.status),
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      listing.status == AppConstants.soldStatus
                          ? 'Bu ilan satildi olarak isaretlenmis.'
                          : 'Bu ilan su anda rezerve olarak isaretlenmis.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.deepGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.children,
    required this.title,
    required this.subtitle,
  });

  final List<Widget> children;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.mutedText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.cream,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.mossGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppConstants.forestGreen, size: 18),
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
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: valueColor ?? AppConstants.deepGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppConstants.mutedText),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
