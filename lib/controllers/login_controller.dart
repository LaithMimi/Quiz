import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/services/user_service.dart';

class LoginController extends GetxController {
  // Text controllers for the email and password input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Observable state variables — the UI will react when these change
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxnString generalError = RxnString();

  // Toggle the password field between hidden and visible
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  // Try to log in the user with their email and password
  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Make sure both fields are filled in before trying to log in
    if (email.isEmpty || password.isEmpty) {
      generalError.value = 'Please fill in all fields';
      return;
    }

    generalError.value = null;
    isLoading.value = true;

    try {
      // Sign in using Firebase Authentication
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the user's profile so other users can find them by email
      await UserService.saveProfile(credential.user!);

      // Go to the home screen after a successful login
      Get.offNamed('/home');
    } on FirebaseAuthException catch (e) {
      generalError.value = e.message ?? 'Login failed';
    } catch (e) {
      generalError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Clear all the form fields and any error messages
  void clearFields() {
    emailController.clear();
    passwordController.clear();
    generalError.value = null;
  }

  // Navigate to the sign-up screen
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
