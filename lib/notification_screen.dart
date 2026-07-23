import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final Color _backgroundColor = const Color(0xFF1B1C27);
  final Color _cardColor = const Color(0xFF282A3A);
  final Color _blueAccent = Colors.blueAccent;

  // بيانات وهمية للإشعارات
  final List<Map<String, dynamic>> _dummyNotifications = const [
    {
      'title': 'تمت الموافقة على عقارك',
      'subtitle': 'تم قبول إعلان "Modern Apartment" بنجاح.',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
      'time': 'منذ 5 دقائق',
    },
    {
      'title': 'عروض جديدة لك',
      'subtitle': 'تمت إضافة 10 عقارات جديدة تتناسب مع تفضيلاتك في دبي.',
      'icon': Icons.flash_on,
      'color': Colors.orangeAccent,
      'time': 'قبل ساعة',
    },
    {
      'title': 'خصم حصري!',
      'subtitle': 'احصل على خصم 10% على رسوم أول عملية تأجير.',
      'icon': Icons.local_offer_outlined,
      'color': Colors.redAccent,
      'time': 'أمس',
    },
    {
      'title': 'رسالة جديدة',
      'subtitle': 'لديك رسالة من المشتري بخصوص عقار Luxury Villa.',
      'icon': Icons.message_outlined,
      'color': Colors.blueAccent,
      'time': 'منذ يومين',
    },
    {
      'title': 'تذكير: تحديث الملف الشخصي',
      'subtitle': 'الرجاء إكمال بيانات ملفك الشخصي لتعزيز المصداقية.',
      'icon': Icons.person_outline,
      'color': Colors.white70,
      'time': '2025/11/25',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _backgroundColor,

      // ************ AppBar ************
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF3B609E).withOpacity(0.9), // شبه شفاف قليلاً
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // زر لقراءة كل الإشعارات
          TextButton(
            onPressed: () {
              // منطق وضع كل الإشعارات كـ "مقروءة"
            },
            child: Text(
              'قراءة الكل',
              style: TextStyle(color: _blueAccent, fontSize: 14),
            ),
          ),
        ],
      ),

      // ************ Body ************
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: _dummyNotifications.length,
          itemBuilder: (context, index) {
            final notification = _dummyNotifications[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: notification['color'].withOpacity(0.2),
                    child: Icon(
                      notification['icon'],
                      color: notification['color'],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notification['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['subtitle'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // وقت الإشعار
                      Text(
                        notification['time'],
                        style: TextStyle(
                          color: _blueAccent.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // منطق التعامل مع الإشعار (الانتقال إلى التفاصيل)
                    print('تم النقر على الإشعار: ${notification['title']}');
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}