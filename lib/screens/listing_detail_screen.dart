import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/report_service.dart';
import '../services/user_service.dart';
import 'edit_listing_screen.dart';
import 'image_gallery_screen.dart';
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
  final ReportService _reportService = ReportService();
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

  Future<void> _openReportDialog() async {
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

    if (user.uid == widget.listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi ilanini raporlayamazsin')),
      );
      return;
    }

    final result = await showDialog<_ReportFormResult>(
      context: context,
      builder: (dialogContext) {
        return _ReportListingDialog(listingTitle: widget.listing.title);
      },
    );

    if (result == null) {
      return;
    }

    final report = ReportModel(
      id: '',
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      sellerId: widget.listing.sellerId,
      reporterId: user.uid,
      reason: result.reason,
      note: result.note,
      status: 'open',
      createdAt: DateTime.now(),
    );

    try {
      await _reportService.addReport(report);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Raporun alindi, inceleme icin kaydedildi'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rapor gonderilemedi: $error')));
    }
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

        return StreamBuilder<AppUserModel?>(
          stream: _userService.watchUserById(widget.listing.sellerId),
          builder: (context, sellerSnapshot) {
            final sellerProfile = sellerSnapshot.data;

            return StreamBuilder<List<ListingModel>>(
              stream: _listingService.getListingsBySeller(
                widget.listing.sellerId,
              ),
              builder: (context, sellerListingsSnapshot) {
                final sellerListings =
                    sellerListingsSnapshot.data ?? const <ListingModel>[];

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Ilan detayi'),
                    actions: [
                      IconButton(
                        tooltip: isFavorite
                            ? 'Favoriden cikar'
                            : 'Favorilere ekle',
                        onPressed: () =>
                            _toggleFavorite(isFavorite: isFavorite),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
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
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
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
                      _ImageGalleryPanel(
                        imageUrls: widget.listing.imageUrls,
                        onOpenImage: (index) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ImageGalleryScreen(
                                imageUrls: widget.listing.imageUrls,
                                initialIndex: index,
                                title: widget.listing.title,
                              ),
                            ),
                          );
                        },
                      ),
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
                        onReportListing: _openReportDialog,
                        isOwner: isOwner,
                      ),
                      const SizedBox(height: 14),
                      _TrustPanel(
                        listing: widget.listing,
                        sellerProfile: sellerProfile,
                        sellerListings: sellerListings,
                        onOpenSellerProfile: () => _openSellerProfile(context),
                      ),
                      const SizedBox(height: 14),
                      _InfoPanel(
                        title: 'Ilan bilgileri',
                        subtitle:
                            'Urunun temel ozellikleri ve satis ayrintilari.',
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
                            icon: Icons.schedule_outlined,
                            label: 'Yayin zamani',
                            value: _formatRelativeDate(
                              widget.listing.createdAt,
                            ),
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
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
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
          },
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

  String _formatRelativeDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes.clamp(1, 59);
      return '$minutes dk once';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} saat once';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} gun once';
    }
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} hafta once';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ay once';
    }

    return '${(difference.inDays / 365).floor()} yil once';
  }
}

class _TrustPanel extends StatelessWidget {
  const _TrustPanel({
    required this.listing,
    required this.sellerProfile,
    required this.sellerListings,
    required this.onOpenSellerProfile,
  });

  final ListingModel listing;
  final AppUserModel? sellerProfile;
  final List<ListingModel> sellerListings;
  final VoidCallback onOpenSellerProfile;

  @override
  Widget build(BuildContext context) {
    final activeCount = sellerListings
        .where((item) => item.status == AppConstants.activeStatus)
        .length;
    final soldCount = sellerListings
        .where((item) => item.status == AppConstants.soldStatus)
        .length;
    final hasPhone =
        (sellerProfile?.phone.trim().isNotEmpty ?? false) ||
        listing.phone.trim().isNotEmpty;
    final hasName = sellerProfile?.name.trim().isNotEmpty ?? false;
    final hasEmail = sellerProfile?.email.trim().isNotEmpty ?? false;
    final persistedTrustScore = sellerProfile?.trustScore ?? 0;
    final trustScore =
        persistedTrustScore + (sellerListings.isNotEmpty ? 1 : 0);
    final memberSince = sellerProfile == null
        ? 'Profil tarihi yok'
        : _formatMemberSince(sellerProfile!.createdAt);

    return _InfoPanel(
      title: 'Guven sinyalleri',
      subtitle: 'Satici ve ilanin karar vermeyi kolaylastiran ozet bilgileri.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TrustChip(
              icon: Icons.verified_user_outlined,
              text: 'Guven puani $trustScore/4',
              color: AppConstants.forestGreen,
            ),
            _TrustChip(
              icon: Icons.badge_outlined,
              text: memberSince,
              color: AppConstants.woodBrown,
            ),
            _TrustChip(
              icon: Icons.inventory_2_outlined,
              text: '${sellerListings.length} ilan gecmisi',
              color: AppConstants.leafGreen,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TrustMetric(
                label: 'Aktif ilan',
                value: activeCount.toString(),
                icon: Icons.bolt_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrustMetric(
                label: 'Satilan ilan',
                value: soldCount.toString(),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DetailRow(
          icon: Icons.phone_outlined,
          label: 'Telefon durumu',
          value: hasPhone ? 'Telefon paylasilmis' : 'Telefon eksik',
          valueColor: hasPhone ? AppConstants.leafGreen : AppConstants.clay,
        ),
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Profil doluluk',
          value: sellerProfile?.profileCompleted == true
              ? 'Profil temel bilgileri tamam'
              : _profileCompletenessText(
                  hasName: hasName,
                  hasEmail: hasEmail,
                  hasPhone: hasPhone,
                ),
        ),
        _DetailRow(
          icon: Icons.schedule_outlined,
          label: 'Ilan tazeligi',
          value: _formatListingAge(listing.createdAt),
          isLast: true,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onOpenSellerProfile,
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Satici profilini incele'),
        ),
      ],
    );
  }

  String _formatMemberSince(DateTime date) {
    final months = ((DateTime.now().difference(date).inDays) / 30).floor();
    if (months <= 0) {
      return 'Yeni uye';
    }
    if (months < 12) {
      return '$months aydir uye';
    }

    final years = (months / 12).floor();
    return '$years yildir uye';
  }

  String _formatListingAge(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays <= 0) {
      return 'Bugun eklendi';
    }
    if (difference.inDays == 1) {
      return 'Dun eklendi';
    }
    return '${difference.inDays} gun once eklendi';
  }

  String _profileCompletenessText({
    required bool hasName,
    required bool hasEmail,
    required bool hasPhone,
  }) {
    final count = [hasName, hasEmail, hasPhone].where((item) => item).length;
    if (count == 3) {
      return 'Profil temel bilgileri tamam';
    }
    if (count == 2) {
      return 'Profil buyuk oranda dolu';
    }
    if (count == 1) {
      return 'Profil kismen dolu';
    }
    return 'Profil bilgileri sinirli';
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
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

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppConstants.deepGreen,
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

class _ImageGalleryPanel extends StatefulWidget {
  const _ImageGalleryPanel({
    required this.imageUrls,
    required this.onOpenImage,
  });

  final List<String> imageUrls;
  final ValueChanged<int> onOpenImage;

  @override
  State<_ImageGalleryPanel> createState() => _ImageGalleryPanelState();
}

class _ImageGalleryPanelState extends State<_ImageGalleryPanel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => widget.onOpenImage(index),
                      child: Container(
                        color: AppConstants.mossGreen,
                        child: Image.network(
                          widget.imageUrls[index],
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

                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
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
                          Icons.open_in_full,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tam ekran',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.imageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isActive = index == _currentIndex;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppConstants.forestGreen
                            : AppConstants.border,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return Container(
                          color: AppConstants.mossGreen,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppConstants.forestGreen,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
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
    required this.onReportListing,
    required this.isOwner,
  });

  final ListingModel listing;
  final VoidCallback onOpenSellerProfile;
  final VoidCallback onReportListing;
  final bool isOwner;

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
          if (!isOwner) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onReportListing,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Ilani rapor et'),
            ),
          ],
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

class _ReportFormResult {
  const _ReportFormResult({required this.reason, required this.note});

  final String reason;
  final String note;
}

class _ReportListingDialog extends StatefulWidget {
  const _ReportListingDialog({required this.listingTitle});

  final String listingTitle;

  @override
  State<_ReportListingDialog> createState() => _ReportListingDialogState();
}

class _ReportListingDialogState extends State<_ReportListingDialog> {
  final _noteController = TextEditingController();
  String _selectedReason = AppConstants.reportReasons.first;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ilani rapor et'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.listingTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppConstants.deepGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Rapor nedeni',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: AppConstants.reportReasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Ek not',
                hintText: 'Kisa bir aciklama ekleyebilirsin',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgec'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(
              _ReportFormResult(
                reason: _selectedReason,
                note: _noteController.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.send_outlined),
          label: const Text('Gonder'),
        ),
      ],
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
