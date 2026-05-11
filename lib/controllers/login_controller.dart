import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/services/api_client.dart';

class LoginController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final ApiClient _apiClient = ApiClient();

  final RxBool isLoading          = false.obs;
  final RxBool isPasswordVisible  = false.obs;
  final RxnString generalError    = RxnString();

  void togglePasswordVisibility() => isPasswordVisible.toggle();

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      generalError.value = 'Please fill in all fields';
      return;
    }

    generalError.value = null;
    isLoading.value = true;

    try {
      await _apiClient.login(username: username, password: password);
      Get.offNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    usernameController.clear();
    passwordController.clear();
    generalError.value = null;
  }

  void goToSignUp() => Get.offNamed('/signup');

  @override
  void onClose() {
    _apiClient.close();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
