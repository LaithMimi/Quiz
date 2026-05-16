import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/services/auth_service.dart';
import 'package:quiz/services/user_service.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxnString generalError = RxnString();

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      generalError.value = 'Please fill in all fields';
      return;
    }

    generalError.value = null;
    isLoading.value = true;

    try {
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await UserService.saveProfile(credential.user!);

      Get.offNamed('/home');
    } on FirebaseAuthException catch (e) {
      generalError.value = e.message ?? 'Login failed';
    } catch (e) {
      generalError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    generalError.value = null;
    isLoading.value = true;

    try {
      User? user = await AuthService.signInWithGoogle();

      if (user == null) { //user cancelled the Google picker
        return;
      }

      await UserService.saveProfile(user);
      Get.offNamed('/home');
    } catch (e) {
      generalError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    generalError.value = null;
  }

  void goToSignUp() {
    Get.offNamed('/signup');
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
