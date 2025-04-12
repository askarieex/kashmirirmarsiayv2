import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/sponsored_ad_banner.dart'; // Import for AdBannerItem
import 'models/popup_message.dart'; // Import PopupMessage
import 'widgets/beautiful_popup.dart'; // Import BeautifulPopup
import 'dart:convert';
import 'package:http/http.dart' as http;

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

// Popup Message Methods
void setupPopupMessage(BuildContext context) {
  fetchPopupMessage(context);
}

Future<void> fetchPopupMessage(BuildContext context) async {
  try {
    final url = Uri.parse(
      'https://algodream.in/admin/api/get_popup_message.php',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success') {
        final messageData = jsonData['data'];
        final popupMessage = PopupMessage.fromJson(messageData);

        if (popupMessage.display) {
          Future.delayed(const Duration(milliseconds: 800), () {
            showBeautifulPopup(context, popupMessage.message);
          });
        }
      }
    } else {
      debugPrint('Failed to load popup message: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching popup message: $e');
  }
}

void showBeautifulPopup(BuildContext context, String message) {
  showGeneralDialog(
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    context: context,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, animation, secondaryAnimation) => Container(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuad,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: BeautifulPopup(
            message: message,
            onClose: () {
              Navigator.of(ctx).pop();
            },
          ),
        ),
      );
    },
  );
}
