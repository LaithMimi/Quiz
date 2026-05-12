import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/login_controller.dart';
import 'package:quiz/widgets/auth_header.dart';
import 'package:quiz/widgets/error_text.dart';
import 'package:quiz/widgets/field_decoration.dart';
import 'package:quiz/widgets/labeled_divider.dart';
import 'package:quiz/widgets/primary_button.dart';

class LoginScreenGetX extends StatelessWidget {
  LoginScreenGetX({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AuthHeader(
                  icon: Icons.home_rounded,
                  title: 'Welcome Back!',
                  subtitle: 'Sign in to continue',
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration(
                    label: 'Email',
                    hint: 'Enter your email',
                    prefix: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: fieldDecoration(
                    label: 'Password',
                    hint: 'Enter your password',
                    prefix: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),
                ErrorText(message: controller.generalError.value),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Sign in',
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: controller.isLoading.value ? null : controller.clearFields,
                    child: Text(
                      'Clear fields',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const LabeledDivider(label: 'New here?'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: controller.isLoading.value ? null : controller.goToSignUp,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Create an account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 14, 66, 109),
                      side: const BorderSide(color: Color.fromARGB(255, 14, 66, 109)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  '© Copyright Laith',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
