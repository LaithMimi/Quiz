import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/screens/auth/getx_login_page.dart';
import 'package:quiz/screens/kanban/kanban_screen.dart';
import 'package:quiz/services/auth_service.dart';
import 'package:quiz/services/user_service.dart';

class SignUpController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isVisible = false.obs;
  final RxnString emailError = RxnString();
  final RxnString confirmError = RxnString();
  final RxnString generalError = RxnString();

  bool _isValidEmail(String email) {
    RegExp emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
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

  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  Future<void> handleGoogleSignUp() async {
    isLoading.value = true;

    try {
      User? user = await AuthService.signInWithGoogle();

      if (user == null) {
        return;
      }

      // Save the user's profile so other users can find them by email
      await UserService.saveProfile(user);

      Get.off(() => KanbanScreen());
    } catch (e) {
      Get.snackbar(
        'Google Sign Up Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new account with email and password
  Future<void> signUp() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Make sure all fields are filled in
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      generalError.value = 'Please fill in all fields';
      return;
    }

    // Make sure the email format is valid
    if (emailError.value != null) {
      generalError.value = 'Please enter a valid email';
      return;
    }

    // Make sure the two password fields match
    if (password != confirmController.text) {
      confirmError.value = 'Passwords do not match';
      return;
    }

    generalError.value = null;
    confirmError.value = null;
    isLoading.value = true;

    try {
      // Create the account in Firebase Authentication
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save the username to the Firebase Auth user profile
      await credential.user?.updateDisplayName(username);

      // Save the user's profile so other users can find them by email
      await UserService.saveProfile(credential.user!);

      Get.off(() => KanbanScreen());
    } on FirebaseAuthException catch (e) {
      generalError.value = e.message ?? 'Sign up failed';
    } catch (e) {
      generalError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Navigate back to the sign-in screen
  void handleSignIn() {
    Get.off(() => LoginScreenGetX());
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
