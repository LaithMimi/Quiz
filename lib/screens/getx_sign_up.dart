import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/controllers/sign_up_controller.dart';
import '../services/api_client.dart';

class SignUpScreenGetX extends StatelessWidget {
  SignUpScreenGetX({super.key});

  final SignUpController controller = Get.put(SignUpController());


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign Up')),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 14, 66, 109),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.face, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create an account',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: controller.usernameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    labelText: 'Username',
                    hintText: 'Enter your Username',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: controller.emailController,
                  onChanged: controller.onEmailChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    labelText: 'Email',
                    hintText: 'Enter your Email',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: controller.passwordController,
                  obscureText: !controller.isVisible.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isVisible.value ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        controller.toggleVisibility();
                      },
                    ),
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextField(
                  controller: controller.confirmController,
                  onChanged: (value) {
                    controller.onConfirmChanged(value);
                  },
                  obscureText: !controller.isVisible.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isVisible.value ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        controller.toggleVisibility();
                      },
                    ),
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    errorText: controller.confirmError.value.isEmpty ? null : controller.confirmError.value,
                  ),
                ),
              ),
              if (controller.generalError.value != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    controller.generalError.value!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => controller.signUp(),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign Up'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      endIndent: 12,
                      color: Color(0xFFD9D9D9),
                    ),
                  ),
                  Text(
                    'Or sign up with',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      indent: 12,
                      color: Color(0xFFD9D9D9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                    onPressed:  controller.handleGoogleSignUp, 
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account? ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                GestureDetector(
                  onTap: controller.handleSignIn,
                  child: Text("Log in", style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 14, 66, 109), fontWeight: FontWeight.w500)),
                ),
              ],
            )
            ],
          ),
        ),
      ),
    );
  }
}

}