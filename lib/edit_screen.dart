import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/profile_screen.dart';
import 'package:tanzan/providers/ip_provider.dart';
import 'package:tanzan/providers/token_provider.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.imageUrl,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? imageUrl;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    firstNameController.text = widget.firstName;
    lastNameController.text = widget.lastName;
    emailController.text = widget.email;
    phoneController.text = widget.phoneNumber;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (selectedImage != null) {
        setState(() {
          _image = File(selectedImage.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e".tr);
    }
  }

  Future<void> _saveChanges(BuildContext context, WidgetRef ref) async {
    final token = ref.read(tokenProvider);

    // ✅ Check if anything changed (ignore phone number, always send it)
    final bool changed =
        firstNameController.text != widget.firstName ||
        lastNameController.text != widget.lastName ||
        phoneController.text != widget.phoneNumber ||
        _image != null;

    if (!changed) {
      // Nothing changed → just go back safely
      Navigator.pop(context);
      return;
    }
    final ip = ref.read(ipProvider.notifier).state;
    // Otherwise send update request
    final url = Uri.http('$ip:8000', 'api/update-profile');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['first_name'] = firstNameController.text;
    request.fields['last_name'] = lastNameController.text;
    request.fields['phone_number'] =
        phoneController.text; // ✅ only phone, no email

    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', _image!.path),
      );
    }

    final response = await request.send();
    print(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Changes Saved Successfully!".tr)));

      // Refresh profileProvider so ProfileScreen reloads new data
      ref.refresh(profileProvider);

      Navigator.pop(context); // go back to ProfileScreen
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save changes".tr)));
      print(response.statusCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          appBar: AppBar(
            title: Text(
              'Edit Profile'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            backgroundColor: const Color(0xFF16213E),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3B5998),
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey[900],
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (widget.imageUrl != null &&
                                        widget.imageUrl!.isNotEmpty)
                                  ? NetworkImage(widget.imageUrl!)
                                  : const AssetImage('assets/tanzan.png')
                                        as ImageProvider,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF3B5998),
                              radius: 18,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tap to change photo".tr,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    "First Name".tr,
                    Icons.person_outline,
                    firstNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Last Name".tr,
                    Icons.person_outline,
                    lastNameController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Email Address".tr,
                    Icons.email_outlined,
                    emailController,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Phone Number".tr,
                    Icons.phone_android_outlined,
                    phoneController,
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5998),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () => _saveChanges(context, ref),
                      child: Text(
                        "SAVE CHANGES".tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF3B5998)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF3B5998), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
