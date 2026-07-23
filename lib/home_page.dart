import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:tanzan/add_new_appartment_screen.dart';
import 'package:tanzan/filter.dart';
import 'package:tanzan/profile_screen.dart';
import 'package:tanzan/notification_screen.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';
import 'package:tanzan/search_screen.dart';
import 'package:tanzan/favorites_screen.dart';
import 'package:tanzan/property_details_screen.dart';

// ------------------ MODEL ------------------
class Apartment {
  final int id;
  final String title; // English key from backend
  final String description;
  final String address;
  final Map<String, dynamic> city; // localized map {en:..., ar:...}
  final Map<String, dynamic> state; // localized map {en:..., ar:...}
  final String pricePerNight;
  final int bedrooms;
  final int bathrooms;
  final List<String> images;

  Apartment({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.pricePerNight,
    required this.bedrooms,
    required this.bathrooms,
    required this.images,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: (json['city'] ?? {}) as Map<String, dynamic>,
      state: (json['state'] ?? {}) as Map<String, dynamic>,
      pricePerNight: json['price_per_night']?.toString() ?? '0',
      bedrooms: json['number_of_bedrooms'] ?? 0,
      bathrooms: json['number_of_bathrooms'] ?? 0,
      images: ((json['images'] ?? []) as List)
          .map((img) => (img['image_path'] ?? '').toString())
          .toList(),
    );
  }

  String localizedCity(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    return city[langCode] ?? city['en'] ?? '';
  }

  String localizedState(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    return state[langCode] ?? state['en'] ?? '';
  }
}

// ------------------ PROVIDERS ------------------
final favoritesProvider = StateProvider<Set<int>>((ref) => <int>{});

final favoritesSyncProvider = FutureProvider<void>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null) {
    ref.read(favoritesProvider.notifier).state = <int>{};
    return;
  }
  final ip = ref.read(ipProvider.notifier).state;
  final url = Uri.http('$ip:8000', 'api/user/favorites');
  final response = await http.get(
    url,
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List apartmentsJson = data['apartments'] ?? [];
    final ids = apartmentsJson.map((apt) => apt['id'] as int).toSet();
    ref.read(favoritesProvider.notifier).state = ids;
  } else {
    ref.read(favoritesProvider.notifier).state = <int>{};
  }
});

final filterProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final apartmentsProvider = FutureProvider<List<Apartment>>((ref) async {
  final token = ref.watch(tokenProvider);
  if (token == null) {
    ref.read(favoritesProvider.notifier).state = <int>{};
    throw Exception("No token found");
  }
  final ip = ref.read(ipProvider.notifier).state;

  final filters = ref.watch(filterProvider);
  final queryParams = <String, dynamic>{};

  int? _parseInt(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return n != null && n >= 0 ? n : null;
  }

  if (filters != null) {
    final governorate = (filters['governorate'] ?? '').toString();
    final city = (filters['city'] ?? '').toString();
    final title = (filters['title'] ?? '').toString();

    if (governorate.isNotEmpty) queryParams['city'] = governorate;
    if (city.isNotEmpty) queryParams['state'] = city;
    if (title.isNotEmpty) queryParams['title'] = title;

    final minPrice = _parseInt(filters['minPrice']?.toString());
    final maxPrice = _parseInt(filters['maxPrice']?.toString());
    final area = _parseInt(filters['area']?.toString());
    final bedrooms = _parseInt(filters['rooms']?.toString());
    final bathrooms = _parseInt(filters['bathrooms']?.toString());

    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (area != null) queryParams['area'] = area.toString();
    if (bedrooms != null)
      queryParams['number_of_bedrooms'] = bedrooms.toString();
    if (bathrooms != null)
      queryParams['number_of_bathrooms'] = bathrooms.toString();
  }

  final url = Uri.http('$ip:8000', 'api/user/apartments', queryParams);
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    final List apartmentsJson = responseData['apartments'] ?? [];
    return apartmentsJson
        .map((apartmentJson) => Apartment.fromJson(apartmentJson))
        .toList();
  } else {
    throw Exception("Failed: ${response.statusCode} - ${response.body}");
  }
});

// ------------------ API CALLS FOR FAVORITES ------------------
Future<void> addFavorite(WidgetRef ref, int apartmentId) async {
  final token = ref.read(tokenProvider);
  if (token == null) {
    ref.read(favoritesProvider.notifier).state = <int>{};
    throw Exception("No token found");
  }
  final ip = ref.read(ipProvider.notifier).state;

  final url = Uri.http('$ip:8000', 'api/user/favorites/$apartmentId');
  final response = await http.post(
    url,
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    final current = ref.read(favoritesProvider);
    final next = Set<int>.from(current)..add(apartmentId);
    ref.read(favoritesProvider.notifier).state = next;
  } else {
    throw Exception(
      "Failed to add favorite: ${response.statusCode} - ${response.body}",
    );
  }
}

Future<void> removeFavorite(WidgetRef ref, int apartmentId) async {
  final token = ref.read(tokenProvider);
  if (token == null) {
    ref.read(favoritesProvider.notifier).state = <int>{};
    throw Exception("No token found");
  }
  final ip = ref.read(ipProvider.notifier).state;
  final url = Uri.http('$ip:8000', 'api/user/favorites/$apartmentId');
  final response = await http.delete(
    url,
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final current = ref.read(favoritesProvider);
    final next = Set<int>.from(current)..remove(apartmentId);
    ref.read(favoritesProvider.notifier).state = next;
  } else {
    throw Exception(
      "Failed to remove favorite: ${response.statusCode} - ${response.body}",
    );
  }
}

// ------------------ HOME PAGE ------------------
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  PageRouteBuilder _createSlideRoute(Widget targetScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await ref.refresh(apartmentsProvider.future);
    await ref.refresh(favoritesSyncProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger favorites sync for current user
    ref.watch(favoritesSyncProvider);

    final apartmentsAsync = ref.watch(apartmentsProvider);
    final favorites = ref.watch(favoritesProvider);
    final Color backgroundColor = const Color(0xFF1B1C27);
    final Color cardColor = const Color(0xFF282A3A);
    final Color blueAccent = Colors.blueAccent;
    final double appBarHeight =
        AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,

      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            final result = await showModalBottomSheet<Map<String, dynamic>>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => const Filter(),
            );
            if (result != null) {
              // result contains English-only values from Filter
              ref.read(filterProvider.notifier).state = result;
              await ref.refresh(apartmentsProvider.future);
            }
          },
          icon: Icon(Icons.filter_list_rounded, color: blueAccent, size: 28),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(_createSlideRoute(const NotificationScreen()));
            },
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white70,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
        ],
        title: Text(
          'Home Page'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF3B609E),
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.home, color: Colors.white),
              iconSize: 30,
            ),
            IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(_createSlideRoute(const SearchScreen()));
              },
              icon: const Icon(Icons.search, color: Colors.white70),
              iconSize: 30,
            ),
            const SizedBox(width: 40),
            IconButton(
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(_createSlideRoute(const FavoritesScreen()));
                await ref.refresh(favoritesSyncProvider.future);
              },
              icon: const Icon(Icons.favorite_border, color: Colors.white70),
              iconSize: 30,
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              icon: const Icon(Icons.person_outline, color: Colors.white70),
              iconSize: 30,
            ),
          ],
        ),
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background_image.jpg', fit: BoxFit.cover),
          Container(color: const Color(0xAA1B1C27)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: appBarHeight),

              // Search bar (local only; backend filters come from Filter sheet)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Search for a property (e.g., Villa, Apartment, Damascus)'
                            .tr,
                    hintStyle: TextStyle(
                      color: Colors.white70.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: cardColor.withOpacity(0.8),
                    prefixIcon: Icon(Icons.search, color: blueAccent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {},
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(color: blueAccent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 10.0,
                    ),
                  ),
                  onSubmitted: (value) {
                    debugPrint('Search submitted: $value');
                  },
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 10,
                  ),
                  child: apartmentsAsync.when(
                    data: (apartments) => NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is OverscrollNotification &&
                            notification.overscroll > 0) {
                          _refresh(ref);
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        color: blueAccent,
                        backgroundColor: cardColor,
                        onRefresh: () => _refresh(ref),
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: apartments.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 0.75,
                              ),
                          itemBuilder: (context, index) {
                            final apartment = apartments[index];
                            final isFavorite = favorites.contains(apartment.id);
                            final ip = ref.read(ipProvider.notifier).state;

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              color: cardColor.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 5,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => PropertyDetailsScreen(
                                        apartmentId: apartment.id,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          apartment.images.isNotEmpty
                                              ? Image.network(
                                                  "http://$ip:8000/storage/${apartment.images[0]}",
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Center(
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
                                                try {
                                                  if (isFavorite) {
                                                    await removeFavorite(
                                                      ref,
                                                      apartment.id,
                                                    );
                                                  } else {
                                                    await addFavorite(
                                                      ref,
                                                      apartment.id,
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Failed to update favorite',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  isFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isFavorite
                                                      ? Colors.redAccent
                                                      : Colors.white,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "\$${apartment.pricePerNight}",
                                              style: TextStyle(
                                                color: blueAccent,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              apartment.title.tr,
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.bed,
                                                      color: Colors.grey,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      apartment.bedrooms
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.bathtub,
                                                      color: Colors.grey,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      apartment.bathrooms
                                                          .toString(),
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
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
                          },
                        ),
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text(
                        "Error: $err",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNewAppartmentScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF3B609E),
        child: const Icon(Icons.add_rounded, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
