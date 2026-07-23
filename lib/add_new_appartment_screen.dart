import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddNewAppartmentScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? apartmentData;
  final int? index;

  const AddNewAppartmentScreen({
    super.key,
    this.isEditing = false,
    this.apartmentData,
    this.index,
  });

  @override
  ConsumerState<AddNewAppartmentScreen> createState() =>
      _AddNewAppartmentScreenState();
}

class _AddNewAppartmentScreenState
    extends ConsumerState<AddNewAppartmentScreen> {
  // Backend canonical selections
  String? _selectedTitleType; // e.g., Apartment, Villa...
  String? _selectedGovernorate; // backend governorate key (e.g., damascus)
  String? _selectedCity; // backend city key (e.g., douma)

  // Titles (canonical English keys; UI displays localized via .tr)
  final List<String> _titleOptions = <String>[
    'Apartment',
    'Villa',
    'Chalet',
    'Studio',
    'Duplex',
  ];

  // Governorates (backend keys → labels)
  final Map<String, String> governorates = <String, String>{
    'damascus': 'Damascus',
    'damascus_countryside': 'Damascus Countryside',
    'aleppo': 'Aleppo',
    'homs': 'Homs',
    'hama': 'Hama',
    'latakia': 'Latakia',
    'tartus': 'Tartus',
    'raqqa': 'Raqqa',
    'deir_ezzor': 'Deir ez-Zor',
    'al_hasakah': 'Al-Hasakah',
    'daraa': 'Daraa',
    'as_suwayda': 'As-Suwayda',
    'idlib': 'Idlib',
    'quneitra': 'Quneitra',
  };

  // Governorate → Cities mapping (backend keys)
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

  // Governorate options list
  late final List<String> _governorateOptions = governorates.keys.toList(
    growable: false,
  );

  int _bedrooms = 2;
  int _bathrooms = 2;
  final List<File> _pickedImages = <File>[];
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.apartmentData != null) {
      _selectedTitleType = widget.apartmentData!['title'];
      _priceController.text =
          widget.apartmentData!['price']?.toString().replaceAll(' \$', '') ??
          '';
      _descriptionController.text = widget.apartmentData!['description'] ?? '';
      _areaController.text = widget.apartmentData!['area'] ?? '';
      _addressController.text = widget.apartmentData!['address'] ?? '';
      _bedrooms = widget.apartmentData!['bedrooms'] ?? 2;
      _bathrooms = widget.apartmentData!['bathrooms'] ?? 2;

      // Expect backend canonical keys for governorate/city
      final govField = widget.apartmentData!['city'];
      final cityField = widget.apartmentData!['state'];
      if (govField is String) _selectedGovernorate = govField;
      if (cityField is String) _selectedCity = cityField;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage(
      imageQuality: 70,
    );
    if (selectedImages.isNotEmpty) {
      setState(() {
        for (final XFile xFile in selectedImages) {
          _pickedImages.add(File(xFile.path));
        }
      });
    }
  }

  void _addApartmentToDataBase() async {
    final token = ref.watch(tokenProvider);
    final ip = ref.read(ipProvider.notifier).state;
    final url = Uri.http('$ip:8000', 'api/user/apartments');

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Send canonical keys to backend
    request.fields['title'] = _selectedTitleType ?? '-';
    request.fields['description'] = _descriptionController.text;
    request.fields['address'] = _addressController.text;

    // Backend expects: city = governorate, state = city
    request.fields['city'] = _selectedGovernorate ?? '-';
    request.fields['state'] = _selectedCity ?? '-';

    request.fields['price_per_night'] = _priceController.text;
    request.fields['number_of_bedrooms'] = _bedrooms.toString();
    request.fields['number_of_bathrooms'] = _bathrooms.toString();
    request.fields['area'] = _areaController.text;

    for (final File image in _pickedImages) {
      request.files.add(
        await http.MultipartFile.fromPath('images[]', image.path),
      );
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);
    final data = json.decode(responseBody.body);
    if (data['success'] == true) {
      Navigator.of(context).pop();
    } else {
      final String errorMessage = data['errors'].toString();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Failed to add apartment'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Okay'.tr),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF1B1C27),
      appBar: _buildAppBar(context),
      body: Stack(
        children: <Widget>[
          _buildBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 100,
              left: 18.0,
              right: 18.0,
              bottom: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSectionTitle('Property Information'.tr),
                _buildDropdownField(
                  label: 'Property Type (Title)'.tr,
                  value: _selectedTitleType,
                  hint: 'Select Property Type'.tr,
                  items: _titleOptions,
                  onChanged: (String? newValue) =>
                      setState(() => _selectedTitleType = newValue),
                  icon: Icons.home_work,
                ),
                _buildMultiLineTextField(
                  'Description'.tr,
                  hint: 'Detail all features and amenities'.tr,
                  controller: _descriptionController,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Property Photos'.tr),
                _buildPhotosSection(),
                const SizedBox(height: 30),
                _buildSectionTitle('Location Details'.tr),

                // Governorate dropdown (design label kept as "State")
                _buildDropdownField(
                  label: 'State'.tr,
                  value: _selectedGovernorate,
                  hint: 'Select State'.tr,
                  items: _governorateOptions,
                  onChanged: (String? newValue) => setState(() {
                    _selectedGovernorate = newValue;
                    _selectedCity = null;
                  }),
                  icon: Icons.location_city,
                ),

                // City dropdown (depends on selected governorate)
                _buildDropdownField(
                  label: 'City'.tr,
                  value: _selectedCity,
                  hint: _selectedGovernorate == null
                      ? 'Select State first'.tr
                      : 'Select City'.tr,
                  items: _selectedGovernorate != null
                      ? (governorateCities[_selectedGovernorate] ??
                            const <String>[])
                      : const <String>[],
                  onChanged: (String? newValue) =>
                      setState(() => _selectedCity = newValue),
                  icon: Icons.landscape,
                  isEnabled: _selectedGovernorate != null,
                ),

                _buildTextField(
                  'Address (Major Area)'.tr,
                  hint: 'Enter street name or major landmark'.tr,
                  icon: Icons.location_on,
                  controller: _addressController,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('Features & Specs'.tr),
                _buildFeaturesRow(),
                _buildTextField(
                  'Area (m²)'.tr,
                  hint: 'Total area'.tr,
                  keyboardType: TextInputType.number,
                  controller: _areaController,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('Pricing'.tr),
                _buildPriceField(controller: _priceController),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 100,
      leading: Padding(
        padding: const EdgeInsets.only(left: 23.5, top: 5.0, bottom: 8.0),
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF3B609E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Cancel'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
      title: Text(
        widget.isEditing ? 'Edit Apartment'.tr : 'Add new appartment'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      centerTitle: true,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: TextButton(
            onPressed: _addApartmentToDataBase,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3B609E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              widget.isEditing ? 'Update'.tr : 'Post'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- UI helpers (unchanged design) ---
  Widget _buildBackground() => Container(color: const Color(0xFF1B1C27));

  Widget _buildPhotosSection() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _buildAddPhotoButton(),
          const SizedBox(width: 15),
          ..._pickedImages
              .asMap()
              .entries
              .map((e) => _buildPhotoCard(e.value, e.key))
              .toList(),
          if (_pickedImages.isEmpty) _buildPhotoPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(File file, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: Stack(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: InkWell(
              onTap: () => setState(() => _pickedImages.removeAt(index)),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF282A3A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.add_a_photo, color: Colors.blue, size: 30),
            Text(
              'Upload Photos'.tr,
              style: const TextStyle(color: Colors.blue, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() => Container(
    width: 120,
    decoration: BoxDecoration(
      color: const Color(0xFF282A3A).withOpacity(0.8),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Center(
      child: Icon(Icons.image_outlined, color: Colors.grey, size: 30),
    ),
  );

  Widget _buildTextField(
    String label, {
    IconData? icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF282A3A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none,
                prefixIcon: icon != null
                    ? Icon(icon, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // String-only dropdown to avoid type mismatch errors
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool isEnabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFF282A3A).withOpacity(0.8)
                  : const Color(0xFF282A3A).withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.grey
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                isExpanded: true,
                dropdownColor: const Color(0xFF282A3A),
                style: const TextStyle(color: Colors.white),
                items: items
                    .map<DropdownMenuItem<String>>(
                      (String item) => DropdownMenuItem<String>(
                        value: item,
                        // Localized display for canonical keys
                        child: Text(item.tr),
                      ),
                    )
                    .toList(),
                onChanged: isEnabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLineTextField(
    String label, {
    String? hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF282A3A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStepperField(
              'Bedrooms'.tr,
              Icons.king_bed,
              _bedrooms,
              (val) => setState(() => _bedrooms = val),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStepperField(
              'Bathrooms'.tr,
              Icons.bathtub,
              _bathrooms,
              (val) => setState(() => _bathrooms = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperField(
    String label,
    IconData icon,
    int currentValue,
    Function(int) onChanged, {
    int minLimit = 1,
    int maxLimit = 10,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF282A3A).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey, size: 20),
              const SizedBox(width: 5),
              Text(
                '$currentValue',
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              InkWell(
                onTap: () => currentValue > minLimit
                    ? onChanged(currentValue - 1)
                    : null,
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => currentValue < maxLimit
                    ? onChanged(currentValue + 1)
                    : null,
                child: const Icon(Icons.add_circle_outline, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField({required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF282A3A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter daily rental price'.tr,
                suffixText: '\$/Day'.tr,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
