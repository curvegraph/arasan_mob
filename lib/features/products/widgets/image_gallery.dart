import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/image_placeholder.dart';

/// Full-bleed horizontal PageView image gallery with minimal line indicators.
/// Tap to open full-screen pinch-to-zoom viewer. Shows a 360/GIF badge when
/// [gifUrl] is provided.
class ImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final String? gifUrl;
  final double height;

  const ImageGallery({
    super.key,
    required this.imageUrls,
    this.gifUrl,
    this.height = 400,
  });

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<String> get _images {
    final imgs = <String>[];
    if (widget.imageUrls.isNotEmpty) {
      imgs.addAll(widget.imageUrls);
    }
    if (widget.gifUrl != null && !imgs.contains(widget.gifUrl)) {
      imgs.add(widget.gifUrl!);
    }
    return imgs.isNotEmpty ? imgs : [''];
  }

  bool _isGifIndex(int index) {
    if (widget.gifUrl == null) return false;
    return _images[index] == widget.gifUrl;
  }

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
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // Full-bleed PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, index),
                child: ImagePlaceholder(
                  imageUrl:
                      _images[index].isNotEmpty ? _images[index] : null,
                  height: widget.height,
                  width: double.infinity,
                  icon: Icons.phone_android,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),

          // GIF / 360 view badge
          if (_isGifIndex(_currentPage))
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.obsidian.withValues(alpha: 0.7),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusRound),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.threesixty, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '360 View',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Thin line page indicators at the bottom
          if (_images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 3,
                    width: isActive ? 28 : 14,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen pinch-to-zoom viewer
// ---------------------------------------------------------------------------
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: ImagePlaceholder(
                imageUrl: widget.images[index].isNotEmpty
                    ? widget.images[index]
                    : null,
                width: double.infinity,
                icon: Icons.phone_android,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
