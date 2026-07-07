import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.title = 'Ilan gorselleri',
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }

                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppConstants.amber,
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) {
                          return const _GalleryErrorState();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.imageUrls.length > 1)
              _GalleryFooter(
                imageUrls: widget.imageUrls,
                currentIndex: _currentIndex,
                onTapImage: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryFooter extends StatelessWidget {
  const _GalleryFooter({
    required this.imageUrls,
    required this.currentIndex,
    required this.onTapImage,
  });

  final List<String> imageUrls;
  final int currentIndex;
  final ValueChanged<int> onTapImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Text(
            '${currentIndex + 1} / ${imageUrls.length}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isActive = index == currentIndex;

                return GestureDetector(
                  onTap: () => onTapImage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppConstants.amber
                            : Colors.white.withValues(alpha: 0.15),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.06),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
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
      ),
    );
  }
}

class _GalleryErrorState extends StatelessWidget {
  const _GalleryErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.white70, size: 42),
          SizedBox(height: 12),
          Text(
            'Gorsel yuklenemedi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
