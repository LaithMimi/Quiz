import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:quiz/screens/auth/getx_login_page.dart';
import 'package:quiz/screens/auth/getx_sign_up.dart';
import 'package:quiz/screens/kanban/kanban_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quiz/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //loading the .env file so API keys are available throughout the app
  await dotenv.load(fileName: '.env');

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
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/signup', page: () => SignUpScreenGetX()),
        GetPage(name: '/login', page: () => LoginScreenGetX()),
        GetPage(name: '/home', page: () => KanbanScreen()),
      ],
    );
  }
}
