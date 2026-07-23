import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Filter extends StatefulWidget {
  const Filter({super.key});

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  final Color _darkBackground = const Color(0xFF1B1C27);
  final Color _cardColor = const Color(0xFF282A3A);
  final Color _blueAccent = Colors.blueAccent;

  final minimumPriceController = TextEditingController();
  final maximumPriceController = TextEditingController();
  final areaController = TextEditingController();
  final numberOfRoomsController = TextEditingController();
  final numberOfBathRoomsController = TextEditingController();

  String? _selectedTitle; // e.g., Apartment, Villa (canonical English)
  String? _selectedGovernorate; // backend key (e.g., damascus)
  String? _selectedCity; // backend key (e.g., douma)

  final List<String> _titleOptions = <String>[
    'Apartment',
    'Villa',
    'Chalet',
    'Studio',
    'Duplex',
  ];

  // Canonical governorate keys -> English labels (UI only)
  final Map<String, String> governorates = <String, String>{
    'damascus': 'Damascus',

    'aleppo': 'Aleppo',
    'homs': 'Homs',
    'hama': 'Hama',
    'latakia': 'Latakia',
    'tartus': 'Tartus',
    'raqqa': 'Raqqa',
    'deir_ezzor': 'Deir_ezzor',
    'al_hasakah': 'Al_hasakah',
    'daraa': 'Daraa',
    'as_suwayda': 'As_suwayda',
    'idlib': 'Idlib',
    'quneitra': 'Quneitra',
  };

  // Canonical city keys per governorate (backend receives these keys)
  // Canonical city keys per governorate (backend receives these keys)
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

  InputDecoration _getInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText.tr,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: _cardColor.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _blueAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return n != null && n >= 0 ? n : null;
  }

  @override
  void dispose() {
    minimumPriceController.dispose();
    maximumPriceController.dispose();
    areaController.dispose();
    numberOfRoomsController.dispose();
    numberOfBathRoomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyBoaredspace = MediaQuery.of(context).viewInsets.bottom;
    final currentCities = _selectedGovernorate != null
        ? governorateCities[_selectedGovernorate] ?? <String>[]
        : <String>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: _darkBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, (keyBoaredspace + 16)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Settings / Filter'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white12, height: 25),
              const SizedBox(height: 10),

              // Title
              DropdownButtonFormField<String>(
                value: _selectedTitle,
                decoration: _getInputDecoration('Property Type (Title)'.tr),
                dropdownColor: _cardColor,
                icon: Icon(Icons.arrow_drop_down, color: _blueAccent),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: _titleOptions
                    .map<DropdownMenuItem<String>>(
                      (String t) =>
                          DropdownMenuItem<String>(value: t, child: Text(t.tr)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedTitle = value),
              ),
              const SizedBox(height: 12),

              // Governorate
              DropdownButtonFormField<String>(
                value: _selectedGovernorate,
                decoration: _getInputDecoration('Governorate'.tr),
                dropdownColor: _cardColor,
                icon: Icon(Icons.arrow_drop_down, color: _blueAccent),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: governorates.keys
                    .map<DropdownMenuItem<String>>(
                      (String govKey) => DropdownMenuItem<String>(
                        value: govKey,
                        child: Text(governorates[govKey]!.tr),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGovernorate = value;
                    _selectedCity = null;
                  });
                },
              ),
              const SizedBox(height: 12),

              // City
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: _getInputDecoration(
                  _selectedGovernorate == null
                      ? 'Select Governorate first'.tr
                      : 'City'.tr,
                ),
                dropdownColor: _cardColor,
                icon: Icon(Icons.arrow_drop_down, color: _blueAccent),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: currentCities.map<DropdownMenuItem<String>>((cityKey) {
                  final key = cityKey as String;
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(key.tr),
                  );
                }).toList(),
                onChanged: _selectedGovernorate == null
                    ? null
                    : (value) => setState(() => _selectedCity = value),
              ),
              const SizedBox(height: 12),

              // Min price
              TextField(
                controller: minimumPriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration('Minimum price'.tr),
              ),
              const SizedBox(height: 12),

              // Max price
              TextField(
                controller: maximumPriceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration('Maximum price'.tr),
              ),
              const SizedBox(height: 12),

              // Area
              TextField(
                controller: areaController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration('Area (m²)'.tr),
              ),
              const SizedBox(height: 12),

              // Bedrooms
              TextField(
                controller: numberOfRoomsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration('Bedrooms'.tr),
              ),
              const SizedBox(height: 12),

              // Bathrooms
              TextField(
                controller: numberOfBathRoomsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration('Bathrooms'.tr),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF3B609E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final result = <String, dynamic>{};

                        if (_selectedTitle != null) {
                          result['title'] = _selectedTitle;
                        }
                        if (_selectedGovernorate != null) {
                          result['governorate'] =
                              _selectedGovernorate; // backend: city
                        }
                        if (_selectedCity != null) {
                          result['city'] = _selectedCity; // backend: state
                        }

                        final minPrice = _parseInt(minimumPriceController.text);
                        final maxPrice = _parseInt(maximumPriceController.text);
                        final area = _parseInt(areaController.text);
                        final rooms = _parseInt(numberOfRoomsController.text);
                        final baths = _parseInt(
                          numberOfBathRoomsController.text,
                        );

                        if (minPrice != null)
                          result['minPrice'] = minPrice.toString();
                        if (maxPrice != null)
                          result['maxPrice'] = maxPrice.toString();
                        if (area != null) result['area'] = area.toString();
                        if (rooms != null) result['rooms'] = rooms.toString();
                        if (baths != null)
                          result['bathrooms'] = baths.toString();

                        Navigator.pop(context, result);
                      },
                      child: Text(
                        'Apply'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedTitle = null;
                          _selectedGovernorate = null;
                          _selectedCity = null;
                          minimumPriceController.clear();
                          maximumPriceController.clear();
                          areaController.clear();
                          numberOfRoomsController.clear();
                          numberOfBathRoomsController.clear();
                        });

                        // Return an empty filter map so HomePage resets to all apartments
                        Navigator.pop(context, <String, dynamic>{});
                      },
                      child: Text(
                        'Clear'.tr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
