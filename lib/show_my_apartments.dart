import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tanzan/edit_apartment_screen.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'dart:convert';
import 'package:tanzan/providers/token_provider.dart';

/// --- Apartments Provider ---
final apartmentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final token = ref.read(tokenProvider);

      if (token == null || token.isEmpty) {
        throw Exception("Missing auth token. Please log in.");
      }
      final ip = ref.read(ipProvider.notifier).state;

      final response = await http.get(
        Uri.parse("http://$ip:8000/api/user/ownerapartments"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        print(response.body);
        throw Exception("Failed to load apartments: ${response.statusCode}");
      }

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (!jsonResponse.containsKey('apartments') ||
          jsonResponse['apartments'] == null) {
        throw Exception("Invalid response: 'apartments' key not found.");
      }

      final List data = jsonResponse['apartments'];
      return List<Map<String, dynamic>>.from(data);
    });

/// --- Show My Apartment Screen ---
class ShowMyApartmentScreen extends ConsumerWidget {
  const ShowMyApartmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apartmentsAsync = ref.watch(apartmentsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Apartments'.tr,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background_image.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: Colors.black.withOpacity(0.8)),
          ),
          SafeArea(
            child: apartmentsAsync.when(
              data: (apartments) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.refresh(apartmentsProvider.future);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: apartments.length,
                    itemBuilder: (context, index) =>
                        _buildApartmentCard(context, ref, apartments[index]),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApartmentCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> property,
  ) {
    String? imageUrl;
    final images = property['images'];
    if (images is List &&
        images.isNotEmpty &&
        images[0]['image_path'] != null) {
      final ip = ref.read(ipProvider.notifier).state;
      imageUrl = "http://$ip:8000/storage/${images[0]['image_path']}";
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: const Color(0xFF1E1F2E).withOpacity(0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Apartment image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
          ),
          // Apartment info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['title']?.toString().tr ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${property['city'] ?? ''}, ${property['state'] ?? ''}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  "Price per night:".tr +
                      " ${property['price_per_night']?.toString() ?? ''} \$",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_note,
                  color: Colors.greenAccent,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditApartmentScreen(apartmentData: property),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 28,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("Confirm Delete".tr),
                      content: Text(
                        "Are you sure you want to delete this apartment?".tr,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text("Cancel".tr),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      final token = ref.read(tokenProvider);
                      final ip = ref.read(ipProvider.notifier).state;
                      final response = await http.delete(
                        Uri.parse(
                          "http://$ip:8000/api/user/apartments/${property['id']}",
                        ),
                        headers: {
                          "Accept": "application/json",
                          "Authorization": "Bearer $token",
                        },
                      );

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Apartment deleted successfully"),
                          ),
                        );
                        // Refresh apartments list
                        ref.refresh(apartmentsProvider);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Failed to delete: ${response.statusCode}",
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
