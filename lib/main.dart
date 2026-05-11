import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz/screens/auth/getx_login_page.dart';
import 'package:quiz/screens/auth/getx_sign_up.dart';
import 'package:quiz/screens/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quiz/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/signup',
      getPages: [
        GetPage(name: '/signup', page: () => GetXSignUp()),
        GetPage(name: '/login', page: () => LoginScreenGetX()),
        GetPage(name: '/home', page: () => const MyHomePage()),
      ],
    );
  }
}
