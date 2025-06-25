import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class SponsoredAdBanner extends StatefulWidget {
  final List<AdBannerItem> adItems;
  final double height;
  final EdgeInsetsGeometry? margin;

  const SponsoredAdBanner({
    super.key,
    required this.adItems,
    this.height = 150,
    this.margin,
  });

  @override
  State<SponsoredAdBanner> createState() => _SponsoredAdBannerState();
}

class _SponsoredAdBannerState extends State<SponsoredAdBanner>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.92,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _animationController.addListener(() {
      if (_animationController.isCompleted) {
        _animationController.reset();
        _nextPage();
      }
    });

    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _nextPage();
    });
    _animationController.forward(from: 0.0);
  }

  void _nextPage() {
    if (widget.adItems.length > 1) {
      final nextPage = (_currentPage + 1) % widget.adItems.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.adItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              bottom: 8.0,
              right: 16.0,
            ),
            child: Row(
              children: [
                Container(
                  height: 16,
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Sponsored",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _indicatorAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _indicatorAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            height: widget.height,
            constraints: BoxConstraints(maxHeight: widget.height),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.adItems.length,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = widget.adItems[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: HoverableAdCard(
                    onTap: () => item.onTap?.call(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Ad Image
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                    ),
                                  ),
                            ),
                          ),
                          // Gradient overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Ad Content
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.description != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      item.description!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                // Visit Link Button with Pulse Animation
                                PulseAnimatedButton(
                                  onTap: () => item.onTap?.call(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class AdBannerItem {
  final String imageUrl;
  final String title;
  final String? description;
  final VoidCallback? onTap;

  AdBannerItem({
    required this.imageUrl,
    required this.title,
    this.description,
    this.onTap,
  });
}

// Add HoverableAdCard widget for enhanced hover effect
class HoverableAdCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HoverableAdCard({super.key, required this.child, this.onTap});

  @override
  State<HoverableAdCard> createState() => _HoverableAdCardState();
}

class _HoverableAdCardState extends State<HoverableAdCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform:
              _isHovered
                  ? (Matrix4.identity()..scale(1.03))
                  : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    _isHovered
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                blurRadius: _isHovered ? 15 : 10,
                spreadRadius: _isHovered ? 2 : 0,
                offset: _isHovered ? const Offset(0, 5) : const Offset(0, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Add this new widget for pulsing button animation
class PulseAnimatedButton extends StatefulWidget {
  final VoidCallback? onTap;

  const PulseAnimatedButton({super.key, this.onTap});

  @override
  State<PulseAnimatedButton> createState() => _PulseAnimatedButtonState();
}

class _PulseAnimatedButtonState extends State<PulseAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHovered ? 1.05 : _scaleAnimation.value,
            child: ElevatedButton.icon(
              onPressed: widget.onTap,
              icon: const Icon(Icons.launch_rounded, size: 16),
              label: const Text('Visit Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                elevation: _isHovered ? 5 : 3,
                shadowColor: Colors.black.withOpacity(_isHovered ? 0.4 : 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
