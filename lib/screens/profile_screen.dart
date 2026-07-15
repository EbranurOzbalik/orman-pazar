import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';
import '../widgets/app_surfaces.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ListingService _listingService = ListingService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profilim')),
        body: _ProfileLockedState(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: StreamBuilder<AppUserModel?>(
        stream: _userService.watchUserById(user.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasProfileAccess = !userSnapshot.hasError;

          final profile =
              userSnapshot.data ??
              AppUserModel(
                id: user.uid,
                name: '',
                email: user.email ?? '',
                phone: '',
                createdAt: DateTime.now(),
                userMode: AppConstants.buyerSellerMode,
                profileCompleted: false,
                trustScore: 0,
              );

          return StreamBuilder<List<ListingModel>>(
            stream: _listingService.getListingsBySeller(user.uid),
            builder: (context, listingSnapshot) {
              final listings = listingSnapshot.data ?? const <ListingModel>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _ProfileHero(profile: profile, listingCount: listings.length),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(profile: profile),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Profili duzenle'),
                    ),
                  ),
                  if (!hasProfileAccess) ...[
                    const SizedBox(height: 12),
                    const _ProfileAccessNote(),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileStatCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Aktif ilan',
                          value: listings.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileStatCard(
                          icon: Icons.favorite_outline,
                          label: 'Favori',
                          value: profile.favoriteListingIds.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileStatCard(
                          icon: Icons.calendar_month_outlined,
                          label: 'Mod',
                          value: AppConstants.userModeLabel(profile.userMode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProfilePanel(
                    title: 'Hesap bilgileri',
                    subtitle: 'Pazaryerindeki gorunen temel bilgiler.',
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.person_outline,
                        label: 'Ad soyad',
                        value: profile.displayName,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.mail_outline,
                        label: 'E-posta',
                        value: profile.email,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Telefon',
                        value: profile.phone.isEmpty ? '-' : profile.phone,
                      ),
                      _ProfileInfoTile(
                        icon: AppConstants.userModeIcon(profile.userMode),
                        label: 'Hesap modu',
                        value: AppConstants.userModeLabel(profile.userMode),
                      ),
                      _ProfileInfoTile(
                        icon: Icons.verified_user_outlined,
                        label: 'Kullanici kimligi',
                        value: profile.id,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProfilePanel(
                    title: 'Hesap durumu',
                    subtitle: 'Bir sonraki adimlarda genisleyecek alanlar.',
                    children: const [
                      _StatusPillRow(
                        items: [
                          _StatusPillData(
                            icon: Icons.check_circle_outline,
                            text: 'Auth bagli',
                          ),
                          _StatusPillData(
                            icon: Icons.cloud_done_outlined,
                            text: 'Firestore hazir',
                          ),
                          _StatusPillData(
                            icon: Icons.favorite_outline,
                            text: 'Favoriler aktif',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProfilePanel(
                    title: 'Mod aciklamasi',
                    subtitle: 'Hesabin uygulamada nasil davrandigini gosterir.',
                    children: [_ModeSummaryCard(mode: profile.userMode)],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileLockedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppConstants.mossGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.border),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppConstants.forestGreen,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Giris yapman gerekiyor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppConstants.deepGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Profil bilgilerini gormek ve hesap verilerini yonetmek icin once hesabina gir.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.mutedText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              icon: const Icon(Icons.login),
              label: const Text('Giris yap'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAccessNote extends StatelessWidget {
  const _ProfileAccessNote();

  @override
  Widget build(BuildContext context) {
    return const AppInfoBanner(
      icon: Icons.info_outline,
      message:
          'Profil dokumanina erisim sinirli. Bu ekranda su an giris hesabindaki temel bilgiler gosteriliyor.',
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.listingCount});

  final AppUserModel profile;
  final int listingCount;

  @override
  Widget build(BuildContext context) {
    return AppHeroSection(
      title: profile.displayName,
      subtitle: profile.email,
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppConstants.amber,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          _initials(profile.displayName),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppConstants.deepGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppConstants.userModeColor(
            profile.userMode,
          ).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppConstants.userModeIcon(profile.userMode),
              size: 15,
              color: AppConstants.amber,
            ),
            const SizedBox(width: 6),
            Text(
              AppConstants.userModeLabel(profile.userMode),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _HeroTag(icon: Icons.forest_outlined, text: '$listingCount ilan'),
          const _HeroTag(
            icon: Icons.storefront_outlined,
            text: 'Orman Pazar saticisi',
          ),
          const _HeroTag(icon: Icons.shield_outlined, text: 'Hesap baglandi'),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return 'OP';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _ModeSummaryCard extends StatelessWidget {
  const _ModeSummaryCard({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.userModeColor(mode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(AppConstants.userModeIcon(mode), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.userModeLabel(mode),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.deepGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.userModeDescription(mode),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.mutedText,
                    height: 1.35,
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

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
          Icon(icon, color: AppConstants.amber, size: 15),
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

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppMetricTile(icon: icon, label: label, value: value);
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.dashboard_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
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
    return Container(
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

class _StatusPillRow extends StatelessWidget {
  const _StatusPillRow({required this.items});

  final List<_StatusPillData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) => _StatusPill(data: item)).toList(),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.data});

  final _StatusPillData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppConstants.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: AppConstants.forestGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            data.text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppConstants.deepGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPillData {
  const _StatusPillData({required this.icon, required this.text});

  final IconData icon;
  final String text;
}
