import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart'; // إضافة المكتبة
import 'package:tanzan/second_sign_up_screen.dart';

class FirstSignUpScreen extends StatefulWidget {
  const FirstSignUpScreen({super.key});

  @override
  State<FirstSignUpScreen> createState() => _FirstSignUpScreenState();
}

class _FirstSignUpScreenState extends State<FirstSignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void checkInput() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          // استخدام .tr مع نصوصك الأصلية
          title: Text('Invalid Input'.tr),
          content: Text(
            'please make sure that you have already fill all the gaps'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('Okay'.tr),
            ),
          ],
        ),
      );
    } else if (_passwordController.text != _confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Invalid Input'.tr),
          content: Text(
            'your cofirm password is not the same password you put please correct it'
                .tr,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text('Okay'.tr),
            ),
          ],
        ),
      );
    } else {
      // استخدام Get.to للانتقال بدلاً من Navigator إذا أردت، أو اتركها كما هي
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondSignUpScreen(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            password: _passwordController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية
          Image.asset("assets/background_image.jpg", fit: BoxFit.cover),

          // طبقة تعتيم
          Container(color: Colors.black.withOpacity(0.40)),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 90),

                const Icon(Icons.home_outlined, size: 80, color: Colors.white),

                const SizedBox(height: 13),

                // عنوان التطبيق (ثابت لا يحتاج ترجمة غالباً)
                const Text(
                  "TANZAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // عنوان إنشاء حساب
                Text(
                  "Create Account".tr, // أضفنا .tr
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 35),

                // First Name
                buildInputField(
                  icon: Icons.person,
                  hintText: "First Name".tr, // أضفنا .tr
                  controller: _firstNameController,
                ),
                const SizedBox(height: 15),

                // Last Name
                buildInputField(
                  icon: Icons.person,
                  hintText: "Last Name".tr, // أضفنا .tr
                  controller: _lastNameController,
                ),
                const SizedBox(height: 15),

                // Password
                buildInputField(
                  icon: Icons.lock,
                  hintText: "Password".tr, // أضفنا .tr
                  obscure: true,
                  controller: _passwordController,
                  isPassword: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 15),

                // Confirm Password
                buildInputField1(
                  icon: Icons.lock_outline,
                  hintText: "Confirm Password".tr, // أضفنا .tr
                  obscure: true,
                  controller: _confirmPasswordController,
                  isConfirmPassword: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 35),

                // زر إنشاء حساب (التالي)
                SizedBox(
                  height: 50,
                  width: 165,
                  child: ElevatedButton(
                    onPressed: checkInput,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B609E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Next".tr, // أضفنا .tr (تم تنظيف المسافات الزائدة للنص)
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // نص الانتقال لتسجيل الدخول
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ".tr, // أضفنا .tr
                      style: const TextStyle(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
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
}

// تعديل الدالة المساعدة لتقبل الترجمة في الـ hint
Widget buildInputField({
  required IconData icon,
  required String hintText,
  required TextEditingController controller,
  bool isPassword = false,
  bool isPhoneNumber = false,
  bool obscure = false,
  Widget? suffixIcon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: controller,
      obscureText: isPassword,
      obscuringCharacter: '•',
      style: const TextStyle(color: Colors.white),
      textAlign: TextAlign.left,
      keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhoneNumber
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 10.0,
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
      ),
    ),
  );
}

Widget buildInputField1({
  required IconData icon,
  required String hintText,
  required TextEditingController controller,
  bool isConfirmPassword = false,
  bool isPhoneNumber = false,
  bool obscure = false,
  Widget? suffixIcon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: controller,
      obscureText: isConfirmPassword,
      obscuringCharacter: '•',
      style: const TextStyle(color: Colors.white),
      textAlign: TextAlign.left,
      keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhoneNumber
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 10.0,
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
      ),
    ),
  );
}
