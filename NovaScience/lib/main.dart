import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/StartScreen/EditProfileScreen.dart';
import 'package:nova_science/Screens/StartScreen/HomeScreen.dart';
import 'package:nova_science/Screens/StartScreen/JoinScreen.dart';
import 'package:nova_science/Screens/StartScreen/SignIn.dart';
import 'package:nova_science/Screens/StartScreen/onboardingScreen.dart';

import 'Screens/StartScreen/HomePage.dart';
import 'Screens/StartScreen/SplashScreen.dart';

void main() => runApp(const NovaScience());

class NovaScience extends StatelessWidget {
  const NovaScience({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      title: 'Nova Science',
      initialRoute: '/',
      routes: {
        '/':(context) => SplashScreen(),
        '/Join': (context) => JoinScreen(),
        '/signIn':(context) => SignInScreen(),
        '/homeScreen':(context) => HomePage(),
        '/editProfile':(context) =>EditProfileScreen(),
      },
    );
  }
}

