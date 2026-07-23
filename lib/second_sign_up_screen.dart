import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // إضافة المكتبة
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tanzan/login_screen.dart';
import 'package:tanzan/providers/ip_provider.dart';

class SecondSignUpScreen extends ConsumerStatefulWidget {
  const SecondSignUpScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.password,
  });
  final String firstName;
  final String lastName;
  final String password;
  @override
  ConsumerState<SecondSignUpScreen> createState() => _NextPageState();
}

class _NextPageState extends ConsumerState<SecondSignUpScreen> {
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  File? _profileImage;
  File? _idImage;
  DateTime? _dateOfBirth;
  String? isoDate;

  Future<void> _pickImage(bool isProfileImage) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
        } else {
          _idImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2010, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2F66FF),
              onPrimary: Colors.white,
              surface: Colors.black54,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black87,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      isoDate = picked.toIso8601String();
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void register() async {
      final ip = ref.read(ipProvider.notifier).state;
      final url = Uri.parse("http://$ip:8000/api/register");

      var request = http.MultipartRequest("POST", url);

      // Add text fields
      request.fields['first_name'] = widget.firstName;
      request.fields['last_name'] = widget.lastName;
      request.fields['email'] = _emailController.text;
      request.fields['phone_number'] = _phoneNumberController.text;
      request.fields['password'] = widget.password;
      request.fields['date_of_birth'] = isoDate!;

      // Add files
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          _profileImage!.path,
          filename: basename(_profileImage!.path),
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'personal_id',
          _idImage!.path,
          filename: basename(_idImage!.path),
        ),
      );

      // Send request
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('waiting for regestration to be confirmed')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Registration Failed'),
            content: Text('Please check your details and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: Text('Okay'),
              ),
            ],
          ),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/background_image.jpg", fit: BoxFit.cover),
          Container(color: const Color.fromARGB(100, 0, 0, 0)),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 90),
                const Icon(Icons.home_outlined, size: 80, color: Colors.white),
                const SizedBox(height: 13),
                const Text(
                  "TANZAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Create Account".tr, // أضفنا .tr
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 35),

                // Email
                buildInputField(
                  icon: Icons.email,
                  controller: _emailController,
                  hint: "email".tr,
                  keyBoaredType: TextInputType.emailAddress,
                ), // أضفنا .tr
                const SizedBox(height: 15),

                // Phone
                buildInputField(
                  controller: _phoneNumberController,
                  icon: Icons.phone,
                  hint: "phone number".tr,
                  keyBoaredType: TextInputType.number,
                ), // أضفنا .tr
                const SizedBox(height: 15),

                // Date of Birth
                _buildDatePickerField(
                  icon: Icons.calendar_today,
                  hint: "Date of Birth".tr, // أضفنا .tr
                  date: _dateOfBirth,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 15),

                // Profile Picture
                _buildImagePickerField(
                  icon: Icons.image,
                  hint: "Select Profile Picture".tr, // أضفنا .tr
                  imageFile: _profileImage,
                  onTap: () => _pickImage(true),
                ),
                const SizedBox(height: 15),

                // ID Picture
                _buildImagePickerField(
                  icon: Icons.badge,
                  hint: "Select ID Picture".tr, // أضفنا .tr
                  imageFile: _idImage,
                  onTap: () => _pickImage(false),
                ),

                const SizedBox(height: 35),

                // Create Button
                SizedBox(
                  height: 50,
                  width: 175,
                  child: ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B609E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Create".tr, // أضفنا .tr
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ".tr, // أضفنا .tr
                      style: const TextStyle(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Login".tr, // أضفنا .tr
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required IconData icon,
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    String displayDate = date != null
        ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
        : hint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                displayDate,
                style: TextStyle(
                  color: date == null ? Colors.white70 : Colors.white,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerField({
    required IconData icon,
    required String hint,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                imageFile == null
                    ? hint
                    : "${'Image Selected'.tr}: ${imageFile.path.split('/').last}", // أضفنا ترجمة لحالة الاختيار
                style: TextStyle(
                  color: imageFile == null ? Colors.white70 : Colors.white,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (imageFile != null)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.check_circle, color: Colors.greenAccent),
              ),
          ],
        ),
      ),
    );
  }
}

Widget buildInputField({
  required IconData icon,
  required String hint,
  required controller,
  bool obscure = false,
  required TextInputType keyBoaredType,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        icon: Icon(icon, color: Colors.white),
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
      ),
    ),
  );
}
