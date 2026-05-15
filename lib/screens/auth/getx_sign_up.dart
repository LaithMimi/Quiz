import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/sign_up_controller.dart';
import 'package:quiz/widgets/auth_header.dart';
import 'package:quiz/widgets/error_text.dart';
import 'package:quiz/widgets/field_decoration.dart';
import 'package:quiz/widgets/labeled_divider.dart';
import 'package:quiz/widgets/google_button.dart';
import 'package:quiz/widgets/primary_button.dart';

class SignUpScreenGetX extends StatelessWidget {
  SignUpScreenGetX({super.key});

  final SignUpController controller = Get.put(SignUpController());

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
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Create Account',
                  subtitle: 'Join us today',
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: controller.usernameController,
                  decoration: fieldDecoration(
                    label: 'Username',
                    hint: 'Enter your username',
                    prefix: Icons.person_outline,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: controller.onEmailChanged,
                  decoration: fieldDecoration(
                    label: 'Email',
                    hint: 'Enter your email',
                    prefix: Icons.email_outlined,
                    error: controller.emailError.value,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: controller.passwordController,
                  obscureText: !controller.isVisible.value,
                  decoration: fieldDecoration(
                    label: 'Password',
                    hint: 'Enter your password',
                    prefix: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: controller.toggleVisibility,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: controller.confirmController,
                  obscureText: !controller.isVisible.value,
                  onChanged: controller.onConfirmChanged,
                  decoration: fieldDecoration(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    prefix: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        controller.isVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: controller.toggleVisibility,
                    ),
                    error: (controller.confirmError.value?.isEmpty ?? true)
                        ? null
                        : controller.confirmError.value,
                  ),
                ),

                ErrorText(message: controller.generalError.value),

                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Create Account',
                  onPressed: controller.signUp,
                  isLoading: controller.isLoading.value,
                ),

                const SizedBox(height: 20),
                const LabeledDivider(label: 'or'),
                const SizedBox(height: 20),

                GoogleButton(
                  onPressed: controller.isLoading.value ? null : controller.handleGoogleSignUp,
                ),

                const SizedBox(height: 36),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?  ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: controller.handleSignIn,
                      child: const Text(
                        'Log in',
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
