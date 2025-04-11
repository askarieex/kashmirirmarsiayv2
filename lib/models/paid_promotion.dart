import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/sponsored_ad_banner.dart'; // Import for AdBannerItem

class PaidPromotion {
  final String id;
  final String promotionName;
  final String promotionLink;
  final String imageUrl;
  final bool isActive;
  final String createdAt;
  final String promotionTitle;
  final String promotionDescription;

  PaidPromotion({
    required this.id,
    required this.promotionName,
    required this.promotionLink,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.promotionTitle,
    required this.promotionDescription,
  });

  factory PaidPromotion.fromJson(Map<String, dynamic> json) {
    return PaidPromotion(
      id: json['id']?.toString() ?? '',
      promotionName: json['promotion_name'] ?? '',
      promotionLink: json['promotion_link'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == '1',
      createdAt: json['created_at'] ?? '',
      promotionTitle: json['promotion_title'] ?? '',
      promotionDescription: json['promotion_description'] ?? '',
    );
  }

  // Convert PaidPromotion to AdBannerItem for displaying in the UI
  AdBannerItem toAdBannerItem() {
    return AdBannerItem(
      imageUrl: imageUrl,
      title: promotionTitle,
      description: promotionDescription,
      onTap: () async {
        final url = Uri.parse(promotionLink);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  // Fetch paid promotions from API
  static Future<List<PaidPromotion>> fetchPaidPromotions() async {
    try {
      final url = Uri.parse(
        'https://algodream.in/admin/api/get_paid_promotions.php?api_key=MOHAMMADASKERYMALIKFROMNOWLARI',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> promotionsData = jsonData['data'];

          return promotionsData
              .map((item) => PaidPromotion.fromJson(item))
              .where((promo) => promo.isActive) // Only return active promotions
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching paid promotions: $e');
      return [];
    }
  }
}
