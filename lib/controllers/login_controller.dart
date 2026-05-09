import 'package:get/get.dart';
import 'package:flutter/material.dart';

class LoginController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxString message = ''.obs;

  void login() {
    message.value =
        'Username: ${usernameController.text}\nPassword: ${passwordController.text}';
        update();
  }

  void clearFields() {
    usernameController.clear();
    passwordController.clear();
    message.value = '';
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
