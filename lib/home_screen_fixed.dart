import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/sponsored_ad_banner.dart'; // Import for AdBannerItem

final List<AdBannerItem> _adItems = [
  AdBannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1569949381669-ecf31ae8e613',
    title: 'Special Muharram Collection',
    description: 'Explore our vast collection of exclusive marsiya and noha',
    onTap: () {
      // Handle ad tap with proper navigation or action
      launchUrl(Uri.parse('https://example.com/special-collection'));
    },
  ),
  AdBannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1566296412153-9de7ba8b6825',
    title: 'Karbala Memorial Event',
    description: 'Join us for a special gathering this Muharram',
    onTap: () {
      // Handle ad tap with proper navigation or action
      launchUrl(Uri.parse('https://example.com/karbala-event'));
    },
  ),
  AdBannerItem(
    imageUrl: 'https://images.unsplash.com/photo-1488372759477-a7f4aa078cb6',
    title: 'Premium Islamic Books',
    description: 'Exclusive collection of religious literature',
    onTap: () {
      // Handle ad tap with proper navigation or action
      launchUrl(Uri.parse('https://example.com/islamic-books'));
    },
  ),
];
