import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tanzan/languge.dart';
import 'package:tanzan/login_screen.dart';
import 'package:tanzan/edit_screen.dart';
import 'package:tanzan/myapartment_screen.dart';
import 'package:tanzan/booking_history.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';
import 'package:tanzan/wallet_screen.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null || token.isEmpty) {
    throw Exception("No token found");
  }
  final ip = ref.read(ipProvider.notifier).state;
  final url = Uri.http('$ip:8000', 'api/profile');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch profile: ${response.statusCode}');
  }

  try {
    final data = jsonDecode(response.body);
    return data['user'] ?? {};
  } catch (e) {
    throw Exception('Invalid JSON response: ${response.body}');
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showWalletSheet(BuildContext context, walletBalance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MiniWalletSheet(walletBalance: walletBalance),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final token = ref.read(tokenProvider);
    final ip = ref.read(ipProvider.notifier).state;
    final url = Uri.http('$ip:8000', 'api/logout');
    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('Logout error: $e');
    }

    // Clear token
    ref.read(tokenProvider.notifier).state = null;

    if (context.mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Log Out".tr),
          content: Text("Are you sure you want to log out?".tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel".tr),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _logout(context, ref);
              },
              child: Text("OK".tr),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Profile'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              // 🌙 show moon when dark, ☀️ show sun when light
              Get.isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              // toggle between dark and light themes
              Get.changeTheme(
                Get.isDarkMode ? ThemeData.light() : ThemeData.dark(),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: profileAsync.when(
        data: (userInfo) {
          final String walletBalance = userInfo['wallet'].toString();
          final String firstName = userInfo['first_name'] ?? '';
          final String lastName = userInfo['last_name'] ?? '';
          final String email = userInfo['email'] ?? '';
          final String phoneNumber = userInfo['phone_number'] ?? '';
          final String? imagePath = userInfo['profile_picture']['image_path'];

          // Build full image URL from backend path
          // const baseUrl = "http://192.168.1.106:8000";
          final ip = ref.read(ipProvider.notifier).state;
          final fullImageUrl = (imagePath != null && imagePath.isNotEmpty)
              ? "http://$ip:8000/storage/$imagePath"
              : null;

          final List<Map<String, dynamic>> menuItems = [
            {
              'icon': Icons.edit_outlined,
              'title': 'Edit Profile'.tr,
              'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditScreen(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phoneNumber: phoneNumber,
                    imageUrl: fullImageUrl,
                  ),
                ),
              ),
            },
            {
              'icon': Icons.apartment_outlined,
              'title': 'My Apartment'.tr,
              'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyApartmentScreen(),
                ),
              ),
            },
            {
              'icon': Icons.history_rounded,
              'title': 'Booking History'.tr,
              'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingHistoryScreen(),
                ),
              ),
            },
            {
              'icon': Icons.language_outlined,
              'title': 'Language'.tr,
              'onTap': () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
              ),
            },
            {
              'icon': Icons.wallet_outlined,
              'title': 'wallet'.tr,
              'onTap': () => _showWalletSheet(context, walletBalance),
            },
            {
              'icon': Icons.logout_rounded,
              'title': 'Log Out'.tr,
              'onTap': () => _showLogoutDialog(context, ref),
            },
          ];

          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background_image.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(color: Colors.black.withOpacity(0.7)),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: const Color(0xFF3B5998),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: fullImageUrl != null
                                ? NetworkImage(fullImageUrl)
                                : null,
                            child: fullImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 30),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          return _buildSquareMenuItem(
                            icon: menuItems[index]['icon'],
                            title: menuItems[index]['title'],
                            onTap: menuItems[index]['onTap'],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(tokenProvider.notifier).state = null;
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          });
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSquareMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3B5998).withOpacity(0.85),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 35),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
