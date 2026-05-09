import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/services/auth_service.dart';
import '../services/api_client.dart';
import '../screens/home_page.dart';
import '../screens/login_page.dart';

class SignUpController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController  = TextEditingController();

  final ApiClient _apiClient = ApiClient();

  final RxBool  isLoading      = false.obs;
  final RxBool  isVisible      = false.obs;
  final RxnString emailError   = RxnString();   
  final RxnString confirmError = RxnString();
  final RxnString generalError = RxnString();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);
  }

  void onEmailChanged(String value) {
    if (value.isEmpty) {
      emailError.value = 'Email cannot be empty';
    } else if (!_isValidEmail(value)) {
      emailError.value = 'Please enter a valid email address';
    } else {
      emailError.value = null;
    }
  }

  void onConfirmChanged(String value) {
    if (value != passwordController.text) {
      confirmError.value = 'Passwords do not match';
    } else {
      confirmError.value = null;
    }
  }

  void toggleVisibility() => isVisible.value = !isVisible.value;


  Future<void> handleGoogleSignUp() async {
    isLoading.value = true;         

    try {
      final user = await AuthService.signInWithGoogle();

      if (user == null) return;     

      Get.off(() => const MyHomePage()); 
    } catch (e) {
      Get.snackbar(                
        'Google Sign Up Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;      
    }
  }



  Future<void> signUp() async {
    final username = usernameController.text.trim();
    final email    = emailController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      generalError.value = 'Please fill in all fields';
      return;
    }
    if (emailError.value != null) {
      generalError.value = 'Please enter a valid email';
      return;
    }
    if (password != confirmController.text) {
      confirmError.value = 'Passwords do not match';
      return;
    }

    generalError.value = null;
    confirmError.value = null;
    isLoading.value = true;

    try {
      await _apiClient.signUp(
        username: username,
        email: email,
        password: password,
      );
      Get.off(() => const MyHomePage()); 
    } catch (e) {
      Get.snackbar(
        'Sign Up Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  void handleSignIn() => Get.off(() => LoginScreenGetX());

  @override
  void onClose() {
    _apiClient.close();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}