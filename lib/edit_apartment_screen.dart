import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';

class EditApartmentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> apartmentData;

  const EditApartmentScreen({super.key, required this.apartmentData});

  @override
  ConsumerState<EditApartmentScreen> createState() =>
      _EditApartmentScreenState();
}

class _EditApartmentScreenState extends ConsumerState<EditApartmentScreen> {
  late TextEditingController descriptionController;
  late TextEditingController addressController;
  late TextEditingController priceController;
  late TextEditingController bedroomsController;
  late TextEditingController bathroomsController;

  String? selectedTitle;
  String? selectedGovernorate;
  String? selectedCity;

  // Titles remain canonical English; UI displays Arabic via .tr
  final List<String> _titleOptions = [
    'Apartment',
    'Villa',
    'Chalet',
    'Studio',
    'Duplex',
  ];

  // Canonical governorate → cities (snake_case, lowercase)
  final Map<String, List<String>> governorateCities = <String, List<String>>{
    'damascus': [
      'shalan',
      'quakeymariyah',
      'thawra_street',
      'bab_toma',
      'bab_sharqi',
      'damar_project',
      'douma',
      'darayya',
      'qatana',
      'qara',
      'deir_atiyah',
      'an_nabk',
      'al_qutayfah',
      'yabroud',
    ],
    'aleppo': [
      'aleppo_city',
      'manbij',
      'afrin',
      'azaz',
      'al_bab',
      'jarabulus',
      'as_safira',
      'dayr_hafir',
      'maskanah',
      'tall_rifat',
      'nabl',
      'zahra',
    ],
    'homs': [
      'homs_city',
      'tadmur',
      'al_qaryatayn',
      'al_sukhna',
      'al_rastan',
      'talbiseh',
      'al_mukharram',
      'al_qusayr',
      'tal_duhoor',
    ],
    'hama': [
      'hama_city',
      'salamiyah',
      'mhardeh',
      'souran',
      'kafr_zeita',
      'taybat_al_imam',
      'qalaat_al_madiq',
      'al_suqaylabiyah',
    ],
    'latakia': [
      'latakia_city',
      'jableh',
      'qardaha',
      'al_haffah',
      'slunfeh',
      'kasab',
    ],
    'tartus': [
      'tartus_city',
      'banyas',
      'safita',
      'dreikish',
      'tal_kalakh',
      'al_hamidiyah',
      'al_qadmus',
    ],
    'raqqa': [
      'raqqa_city',
      'tal_abyad',
      'al_thaawrah',
      'al_karama',
      'al_mansoura',
      'al_jarniyah',
    ],
    'deir_ezzor': [
      'deir_ezzor_city',
      'al_bukamal',
      'al_mayadeen',
      'al_ashara',
      'abu_kamal',
      'al_quriya',
      'subaykhan',
    ],
    'al_hasakah': [
      'al_hasakah_city',
      'qamishli',
      'al_malikiyah',
      'ras_al_ain',
      'amuda',
      'derik',
      'shaddadi',
      'al_hol',
      'al_yarubiyah',
    ],
    'daraa': [
      'daraa_city',
      'izra',
      'al_sanamayn',
      'nawa',
      'tasil',
      'dael',
      'al_harrah',
      'busra_al_sham',
      'al_musayfirah',
    ],
    'as_suwayda': [
      'as_suwayda_city',
      'shahba',
      'salkhad',
      'al_qurayya',
      'attil',
      'al_majdal',
    ],
    'idlib': [
      'idlib_city',
      'ariha',
      'saraqib',
      'maarat_al_numan',
      'jisr_al_shughur',
      'khan_sheikhun',
      'salqin',
      'darkush',
      'armenaz',
      'harem',
    ],
    'quneitra': [
      'quneitra_city',
      'al_baath',
      'khan_arnabeh',
      'al_harra',
      'juba',
      'al_razi',
    ],
  };

  // Arabic→English normalization (extend as needed)
  final Map<String, String> _arToEn = {
    // Titles
    'شقة': 'Apartment',
    'فيلا': 'Villa',
    'شاليه': 'Chalet',
    'استوديو': 'Studio',
    'دوبلكس': 'Duplex',

    // Governorates
    'دمشق': 'damascus',
    'حلب': 'aleppo',
    'حمص': 'homs',
    'حماة': 'hama',
    'اللاذقية': 'latakia',
    'طرطوس': 'tartus',
    'الرقة': 'raqqa',
    'دير الزور': 'deir_ezzor',
    'الحسكة': 'al_hasakah',
    'درعا': 'daraa',
    'السويداء': 'as_suwayda',
    'إدلب': 'idlib',
    'القنيطرة': 'quneitra',

    // Cities (partial; extend as needed)
    'شعلان': 'shalan',
    'باب توما': 'bab_toma',
    'باب شرقي': 'bab_sharqi',
    'دوما': 'douma',
    'داريا': 'darayya',
    'يبرود': 'yabroud',
    'حلب (مدينة)': 'aleppo_city',
    'منبج': 'manbij',
    'عفرين': 'afrin',
    'اعزاز': 'azaz',
    'الباب': 'al_bab',
    'جرابلس': 'jarabulus',
    'السفيرة': 'as_safira',
    'دير حافر': 'dayr_hafir',
    'مسكنة': 'maskanah',
    'تل رفعت': 'tall_rifat',
    'نبل': 'nabl',
    'الزهراء': 'zahra',
    'حمص (مدينة)': 'homs_city',
    'تدمر': 'tadmur',
    'الرستن': 'al_rastan',
    'تلبيسة': 'talbiseh',
    'القصير': 'al_qusayr',
    'حماة (مدينة)': 'hama_city',
    'سلمية': 'salamiyah',
    'محردة': 'mhardeh',
    'صوران': 'souran',
    'كفر زيتا': 'kafr_zeita',
    'طيبة الإمام': 'taybat_al_imam',
    'قلعة المضيق': 'qalaat_al_madiq',
    'السقيلبية': 'al_suqaylabiyah',
    'اللاذقية (مدينة)': 'latakia_city',
    'جبلة': 'jableh',
    'القرداحة': 'qardaha',
    'الحفة': 'al_haffah',
    'صلنفة': 'slunfeh',
    'كسب': 'kasab',
    'طرطوس (مدينة)': 'tartus_city',
    'بانياس': 'banyas',
    'صافيتا': 'safita',
    'دريكيش': 'dreikish',
    'تل كلخ': 'tal_kalakh',
    'الحميدية': 'al_hamidiyah',
    'القدموس': 'al_qadmus',
    'الرقة (مدينة)': 'raqqa_city',
    'تل أبيض': 'tal_abyad',
    'الثورة': 'al_thaawrah',
    'الكرامة': 'al_karama',
    'المنصورة': 'al_mansoura',
    'الجرنية': 'al_jarniyah',
    'دير الزور (مدينة)': 'deir_ezzor_city',
    'البوكمال': 'al_bukamal',
    'الميادين': 'al_mayadeen',
    'العشارة': 'al_ashara',
    'أبو كمال': 'abu_kamal',
    'القورية': 'al_quriya',
    'صبخان': 'subaykhan',
    'الحسكة (مدينة)': 'al_hasakah_city',
    'القامشلي': 'qamishli',
    'المالكية': 'al_malikiyah',
    'رأس العين': 'ras_al_ain',
    'عامودا': 'amuda',
    'ديريك': 'derik',
    'الشدادي': 'shaddadi',
    'الهول': 'al_hol',
    'اليعربية': 'al_yarubiyah',
    'درعا (مدينة)': 'daraa_city',
    'إزرع': 'izra',
    'الصنمين': 'al_sanamayn',
    'نوى': 'nawa',
    'تسيل': 'tasil',
    'داعل': 'dael',
    'الحارة': 'al_harrah',
    'بصرى الشام': 'busra_al_sham',
    'المسيفرة': 'al_musayfirah',
    'السويداء (مدينة)': 'as_suwayda_city',
    'شهبا': 'shahba',
    'صلخد': 'salkhad',
    'القريا': 'al_qurayya',
    'عتيل': 'attil',
    'المجدل': 'al_majdal',
    'إدلب (مدينة)': 'idlib_city',
    'أريحا': 'ariha',
    'سراقب': 'saraqib',
    'معرة النعمان': 'maarat_al_numan',
    'جسر الشغور': 'jisr_al_shughur',
    'خان شيخون': 'khan_sheikhun',
    'سلقين': 'salqin',
    'دركوش': 'darkush',
    'أرمناز': 'armenaz',
    'حارم': 'harem',
    'القنيطرة (مدينة)': 'quneitra_city',
    'البعث': 'al_baath',
    'خان أرنبة': 'khan_arnabeh',
    'جوبا': 'juba',
    'الرازي': 'al_razi',
  };

  // Convert any English input to canonical snake_case (lowercase, spaces→underscores)
  String _toCanonicalKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll('-', '_');
  }

  String? _normalizeTitle(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    final mapped = _arToEn[raw] ?? raw;
    final lower = mapped.toLowerCase();
    for (final t in _titleOptions) {
      if (t.toLowerCase() == lower) return t;
    }
    return null;
  }

  String? _normalizeGovernorate(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    final candidate = _arToEn[raw] ?? _toCanonicalKey(raw);
    return governorateCities.keys.contains(candidate) ? candidate : null;
  }

  String? _normalizeCity(String? value, String? governorate) {
    if (value == null || governorate == null) return null;
    final cities = governorateCities[governorate] ?? const <String>[];
    final raw = value.trim();
    final candidate = _arToEn[raw] ?? _toCanonicalKey(raw);
    return cities.contains(candidate) ? candidate : null;
  }

  // Reverse lookup: find governorate for a given city
  String? _findGovernorateForCity(String? cityRaw) {
    if (cityRaw == null) return null;
    final candidate = _arToEn[cityRaw.trim()] ?? _toCanonicalKey(cityRaw);
    for (final entry in governorateCities.entries) {
      if (entry.value.contains(candidate)) return entry.key;
    }
    return null;
  }

  // Try both schemas: {governorate, city} OR {city, state}
  void _initLocationSelections(Map<String, dynamic> data) {
    final rawGov = data['governorate'] ?? data['city'];
    final rawCity = data['city'] ?? data['state'];

    print('[Edit] incoming rawGov=$rawGov rawCity=$rawCity');

    // First pass: assume rawGov is governorate, rawCity is city
    final gov1 = _normalizeGovernorate(rawGov?.toString());
    final city1 = _normalizeCity(rawCity?.toString(), gov1);
    print('[Edit] pass1 gov1=$gov1 city1=$city1');

    if (gov1 != null && city1 != null) {
      selectedGovernorate = gov1;
      selectedCity = city1;
      return;
    }

    // Second pass: if backend swapped, try rawCity as governorate and rawGov as city
    final gov2 = _normalizeGovernorate(rawCity?.toString());
    final city2 = _normalizeCity(rawGov?.toString(), gov2);
    print('[Edit] pass2 gov2=$gov2 city2=$city2');

    if (gov2 != null && city2 != null) {
      selectedGovernorate = gov2;
      selectedCity = city2;
      return;
    }

    // Third pass: if only city is provided, infer governorate by reverse lookup
    final inferredGov =
        _findGovernorateForCity(rawCity?.toString()) ??
        _findGovernorateForCity(rawGov?.toString());
    print('[Edit] inferredGov=$inferredGov');

    if (inferredGov != null) {
      selectedGovernorate = inferredGov;
      selectedCity =
          _normalizeCity(rawCity?.toString(), inferredGov) ??
          _normalizeCity(rawGov?.toString(), inferredGov);
      print('[Edit] final gov=$selectedGovernorate city=$selectedCity');
      return;
    }

    // Fallbacks: set whichever is valid
    selectedGovernorate = gov1 ?? gov2;
    if (selectedGovernorate != null) {
      final c1 = _normalizeCity(rawCity?.toString(), selectedGovernorate);
      final c2 = _normalizeCity(rawGov?.toString(), selectedGovernorate);
      selectedCity = c1 ?? c2;
    } else {
      selectedCity = null;
    }
    print('[Edit] fallback gov=$selectedGovernorate city=$selectedCity');
  }

  @override
  void initState() {
    super.initState();
    final data = widget.apartmentData;

    descriptionController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    addressController = TextEditingController(
      text: data['address']?.toString() ?? '',
    );
    priceController = TextEditingController(
      text: data['price_per_night']?.toString() ?? '',
    );
    bedroomsController = TextEditingController(
      text: data['number_of_bedrooms']?.toString() ?? '',
    );
    bathroomsController = TextEditingController(
      text: data['number_of_bathrooms']?.toString() ?? '',
    );

    selectedTitle = _normalizeTitle(data['title']?.toString());

    // Robust preselection across both schemas
    _initLocationSelections(data);
  }

  @override
  void dispose() {
    descriptionController.dispose();
    addressController.dispose();
    priceController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
    super.dispose();
  }

  Future<void> submitChanges() async {
    final updatedApartment = {
      "title": selectedTitle, // canonical English
      "description": descriptionController.text,
      "address": addressController.text,
      "governorate": selectedGovernorate, // canonical snake_case
      "city": selectedCity, // canonical snake_case
      "price_per_night": double.tryParse(priceController.text) ?? 0,
      "number_of_bedrooms": int.tryParse(bedroomsController.text) ?? 0,
      "number_of_bathrooms": int.tryParse(bathroomsController.text) ?? 0,
    };

    try {
      final token = ref.read(tokenProvider);
      final ip = ref.read(ipProvider.notifier).state;
      final response = await http.put(
        Uri.parse(
          "http://$ip:8000/api/user/apartments/${widget.apartmentData['id']}",
        ),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode(updatedApartment),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apartment updated successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityOptions = selectedGovernorate != null
        ? (governorateCities[selectedGovernorate!] ?? const <String>[])
        : const <String>[];

    // If current selectedCity isn’t valid for the selectedGovernorate, clear it.
    if (selectedCity != null && !cityOptions.contains(selectedCity)) {
      selectedCity = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Apartment".tr),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title (English value, Arabic display)
            DropdownButtonFormField<String>(
              value: _titleOptions.contains(selectedTitle)
                  ? selectedTitle
                  : null,
              items: _titleOptions.map((title) {
                return DropdownMenuItem<String>(
                  value: title, // English canonical
                  child: Text(title.tr), // Arabic display
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTitle = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Title".tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            _buildField("Description".tr, descriptionController),
            _buildField("Address".tr, addressController),

            // Governorate (English canonical, Arabic display)
            DropdownButtonFormField<String>(
              value: governorateCities.keys.contains(selectedGovernorate)
                  ? selectedGovernorate
                  : null,
              items: governorateCities.keys.map((gov) {
                return DropdownMenuItem<String>(
                  value: gov,
                  child: Text(gov.tr),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGovernorate = value;
                  selectedCity = null; // reset city when governorate changes
                });
              },
              decoration: InputDecoration(
                labelText: "Governorate".tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // City (depends on governorate; English canonical, Arabic display)
            DropdownButtonFormField<String>(
              value: cityOptions.contains(selectedCity) ? selectedCity : null,
              items: cityOptions.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city.tr),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                });
              },
              decoration: InputDecoration(
                labelText: "City".tr,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),
            _buildField(
              "Price per night".tr,
              priceController,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              "Number of bedrooms".tr,
              bedroomsController,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              "Number of bathrooms".tr,
              bathroomsController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitChanges,
              child: Text("Save Changes".tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
