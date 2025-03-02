import 'package:flutter/material.dart';

class TahtUlLafzScreen extends StatelessWidget {
  const TahtUlLafzScreen({super.key});

  static const Color accentTeal = Color(0xFF008F41);

  final List<Map<String, String>> marsiyaList = const [
    {
      'title': 'مضمون قرآن نویں',
      'author': 'Irfan Haider',
      'duration': '4:08',
      'views': '9.2K',
      'language': 'Urdu',
      'type': 'pdf',
      'hasDownload': 'false',
    },
    {
      'title': 'مضمون ساز حمید',
      'author': 'Syed Raza Abbas Zaidi',
      'duration': '3:45',
      'views': '7.8K',
      'language': 'Urdu',
      'type': 'pdf',
      'hasDownload': 'false',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal.shade50,
        title: const Text(
          'تحت اللفظ - Taht ul Lafz',
          style: TextStyle(
            color: accentTeal,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentTeal, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: marsiyaList.length,
          itemBuilder: (context, index) {
            final item = marsiyaList[index];
            return _buildMarsiyaItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildMarsiyaItem(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentTeal, accentTeal.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          item['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'By ${item['author'] ?? ''}',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item['duration'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  item['views'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.play_arrow_rounded,
            color: accentTeal,
            size: 32,
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}
