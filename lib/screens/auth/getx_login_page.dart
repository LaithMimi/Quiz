import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/login_controller.dart';
import 'package:quiz/widgets/auth_header.dart';
import 'package:quiz/widgets/error_text.dart';
import 'package:quiz/widgets/field_decoration.dart';
import 'package:quiz/widgets/labeled_divider.dart';
import 'package:quiz/widgets/google_button.dart';
import 'package:quiz/widgets/primary_button.dart';

class LoginScreenGetX extends StatelessWidget {
  LoginScreenGetX({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                const AuthHeader(
                  icon: Icons.lock_open_rounded,
                  title: 'Welcome Back',
                  subtitle: 'Sign in to your account',
                ),

                const SizedBox(height: 40),

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
                      icon: Icon(controller.isPasswordVisible.value
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
                  label: 'Sign In',
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                ),

                const SizedBox(height: 20),
                const LabeledDivider(label: 'or'),
                const SizedBox(height: 20),

                GoogleButton(
                  onPressed: controller.isLoading.value ? null : controller.signInWithGoogle,
                ),

                const SizedBox(height: 36),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?  ",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: controller.goToSignUp,
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color.fromARGB(255, 14, 66, 109),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

