import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tanzan/property_details_screen.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';

// ✅ Import the global favoritesProvider
import 'package:tanzan/home_page.dart'; // adjust the path if needed

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Map<String, dynamic>> _currentFavorites = [];
  bool _isLoading = true;

  final Color _cardColor = const Color(0xFF282A3A);
  final Color _blueAccent = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    final token = ref.read(tokenProvider);
    if (token == null) return;
    final ip = ref.read(ipProvider.notifier).state;
    final url = Uri.http('$ip:8000', 'api/user/favorites');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List apartmentsJson = data['apartments'] ?? [];

        setState(() {
          final ip = ref.read(ipProvider.notifier).state;
          _currentFavorites = apartmentsJson.map<Map<String, dynamic>>((apt) {
            return {
              'id': apt['id'],
              'title': apt['title'],
              'description': apt['description'],
              'price': apt['price_per_night'],
              'beds': apt['number_of_bedrooms'],
              'baths': apt['number_of_bathrooms'],
              'address': '${apt['city']}, ${apt['state']}',
              'images': (apt['images'] as List? ?? [])
                  .map((img) => "http://$ip:8000/storage/${img['image_path']}")
                  .toList(),
              'area': apt['area'] ?? 0,
            };
          }).toList();
          _isLoading = false;

          // ✅ Sync global favoritesProvider with backend
          final ids = _currentFavorites.map((p) => p['id'] as int).toSet();
          ref.read(favoritesProvider.notifier).state = ids;
        });
      } else {
        debugPrint("Failed to fetch favorites: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching favorites: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int apartmentId) async {
    final token = ref.read(tokenProvider);
    if (token == null) return;
    final ip = ref.read(ipProvider.notifier).state;
    final url = Uri.http('$ip:8000', 'api/user/favorites/$apartmentId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentFavorites.removeWhere((prop) => prop['id'] == apartmentId);
        });
        // ✅ Update global favoritesProvider
        final current = ref.read(favoritesProvider);
        final next = Set<int>.from(current)..remove(apartmentId);
        ref.read(favoritesProvider.notifier).state = next;
      } else {
        debugPrint("Failed to remove favorite: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error removing favorite: $e");
    }
  }

  Widget _buildFeatureIcon(IconData icon, dynamic value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(
    BuildContext context,
    Map<String, dynamic> property,
  ) {
    final List<dynamic> images = property['images'] ?? [];
    final String? firstImage = images.isNotEmpty ? images[0].toString() : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: _cardColor.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) =>
                  PropertyDetailsScreen(apartmentId: property['id']),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  firstImage != null
                      ? Image.network(
                          firstImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.apartment,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.apartment,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await _removeFavorite(property['id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      property['price'].toString(),
                      style: TextStyle(
                        color: _blueAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property['title'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFeatureIcon(Icons.bed, property['beds']),
                        _buildFeatureIcon(Icons.bathtub, property['baths']),
                        _buildFeatureIcon(
                          Icons.square_foot,
                          '${property['area']} Sq.ft',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Favorites'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF3B609E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _currentFavorites.isEmpty
          ? Center(
              child: Text(
                'No properties found in favorites.'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                itemCount: _currentFavorites.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return _buildPropertyCard(context, _currentFavorites[index]);
                },
              ),
            ),
    );
  }
}
