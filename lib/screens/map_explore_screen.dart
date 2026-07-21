import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_constants.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';
import '../widgets/app_surfaces.dart';
import 'listing_detail_screen.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  final ListingService _listingService = ListingService();

  ListingModel? _selectedListing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haritada kesfet')),
      body: StreamBuilder<List<ListingModel>>(
        stream: _listingService.getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return AppEmptyStateCard(
              icon: Icons.error_outline,
              title: 'Harita yuklenemedi',
              message: snapshot.error.toString(),
            );
          }

          final listings = snapshot.data ?? const <ListingModel>[];
          final mapReadyListings = listings
              .where((listing) => listing.hasCoordinates)
              .toList();

          if (mapReadyListings.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: AppEmptyStateCard(
                icon: Icons.map_outlined,
                title: 'Haritaya hazir ilan yok',
                message:
                    'Koordinat girilen ilanlar bu ekranda marker olarak gorunecek.',
              ),
            );
          }

          final ListingModel selectedListing =
              _selectedListing != null &&
                  mapReadyListings.any(
                    (listing) => listing.id == _selectedListing!.id,
                  )
              ? _selectedListing!
              : mapReadyListings.first;

          final markers = mapReadyListings.map((listing) {
            final markerColor = switch (listing.status) {
              AppConstants.soldStatus => BitmapDescriptor.hueOrange,
              AppConstants.reservedStatus => BitmapDescriptor.hueYellow,
              _ => BitmapDescriptor.hueGreen,
            };

            return Marker(
              markerId: MarkerId(listing.id),
              position: LatLng(listing.latitude!, listing.longitude!),
              infoWindow: InfoWindow(
                title: listing.title,
                snippet: '${_formatNumber(listing.price)} TL - ${listing.city}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
              onTap: () {
                setState(() => _selectedListing = listing);
              },
            );
          }).toSet();

          return Stack(
            children: [
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: AppInfoBanner(
                      icon: Icons.info_outline,
                      message:
                          'Bu ekran Google Maps API anahtari eklendiginde tam harita deneyimi sunar. Marker yapisi ve ilan akisi bugunden hazir.',
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              selectedListing.latitude!,
                              selectedListing.longitude!,
                            ),
                            zoom: 7.2,
                          ),
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          markers: markers,
                          onTap: (_) {
                            setState(() => _selectedListing = null);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: _MapListingSummary(
                  listing: selectedListing,
                  totalCount: mapReadyListings.length,
                  onOpenListing: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailScreen(listing: selectedListing),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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

class _MapListingSummary extends StatelessWidget {
  const _MapListingSummary({
    required this.listing,
    required this.totalCount,
    required this.onOpenListing,
  });

  final ListingModel listing;
  final int totalCount;
  final VoidCallback onOpenListing;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.place_outlined,
      title: listing.title,
      subtitle:
          '$totalCount koordinatli ilan icinden secildi. Detaya gecerek tum bilgileri inceleyebilirsin.',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppConstants.mossGreen,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          listing.status,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppConstants.deepGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Konum',
                  value: listing.locationLabel,
                  icon: Icons.location_on_outlined,
                  caption: listing.coordinatesLabel,
                  compact: true,
                  color: AppConstants.forestGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppMetricTile(
                  label: 'Fiyat',
                  value: '${_formatNumber(listing.price)} TL',
                  icon: Icons.payments_outlined,
                  caption:
                      '${_formatNumber(listing.amount)} ${listing.unit} - ${listing.category}',
                  compact: true,
                  color: AppConstants.woodBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onOpenListing,
            icon: const Icon(Icons.arrow_outward_outlined),
            label: const Text('Ilan detayini ac'),
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
