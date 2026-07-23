import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanzan/home_page.dart';
import 'package:tanzan/first_sign_up_screen.dart';
import 'package:tanzan/providers/token_provider.dart';
import 'package:tanzan/providers/ip_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isPasswordVisible = false;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> login() async {
    final ip = ref.read(ipProvider.notifier).state;
    final url = Uri.http("$ip:8000", "/api/login");
    print(ip);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phone_number': _phoneController.text,
        'password': _passwordController.text,
      }),
    );

    print('Login status: ${response.statusCode}');
    print('Login body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        final token = data['token'];

        // ✅ Save token reactively in Riverpod
        ref.read(tokenProvider.notifier).state = token;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const HomePage()),
        );
      } catch (e) {
        print('JSON decode error: $e');
        _showErrorDialog('Invalid server response');
      }
    } else {
      try {
        final message = json.decode(response.body);
        _showErrorDialog(message['message'] ?? 'Login failed');
      } catch (e) {
        _showErrorDialog('Login failed: ${response.body}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Login Failed'.tr),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Okay'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundImage(),
          _buildOverlay(),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background_image.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(color: Colors.black.withOpacity(0.4));
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            const Icon(Icons.home_outlined, color: Colors.white, size: 70.0),
            const SizedBox(height: 20),
            const Text(
              'TANZAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Your Swift Key to the Dream Home....'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 50),
            _buildInputField(
              hintText: 'phone number'.tr,
              icon: Icons.phone_outlined,
              isPhoneNumber: true,
              controller: _phoneController,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              hintText: 'Password'.tr,
              controller: _passwordController,
              icon: Icons.lock_outline,
              isPassword: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot Password?'.tr,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B609E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'LOGIN'.tr,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?".tr,
                  style: const TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FirstSignUpScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Create Account'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isPhoneNumber = false,
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
}
