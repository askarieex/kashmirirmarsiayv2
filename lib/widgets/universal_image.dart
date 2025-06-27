import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  // Function to get CORS-enabled URL for web
  String _getCorsEnabledUrl(String originalUrl) {
    if (kIsWeb && originalUrl.isNotEmpty) {
      // Try multiple CORS proxy services as fallback
      // Option 1: allorigins.hexlet.app (more reliable)
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = _getCorsEnabledUrl(imageUrl);

    // For web platform, use Image.network with CORS proxy
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          effectiveImageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1DB954),
                      ),
                    ),
                  ),
                );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Image loading error on web: $error');
            print('Original URL: $imageUrl');
            print('Proxied URL: $effectiveImageUrl');
            return errorWidget ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.grey, size: 32),
                      if (width != null && width! > 80)
                        const SizedBox(height: 4),
                      if (width != null && width! > 80)
                        Text(
                          'Artist',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                );
          },
        ),
      );
    }

    // For mobile platforms, use CachedNetworkImage
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder:
            (context, url) =>
                placeholder ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1DB954),
                      ),
                    ),
                  ),
                ),
        errorWidget: (context, url, error) {
          print('Image loading error on mobile: $error');
          print('Image URL: $url');
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 32),
                    if (width != null && width! > 80) const SizedBox(height: 4),
                    if (width != null && width! > 80)
                      Text(
                        'Artist',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              );
        },
      ),
    );
  }
}

// Helper widget for circular avatar images
class UniversalCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const UniversalCircleAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      child: ClipOval(
        child: UniversalImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget:
              errorWidget ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: radius * 0.8, color: Colors.grey),
                  if (radius > 30)
                    Text(
                      'Artist',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: radius * 0.2,
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}
