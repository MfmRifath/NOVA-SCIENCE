import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/StartScreen/HomeScreen.dart';
import 'package:nova_science/Screens/StartScreen/ProfileScreen.dart';
import 'package:nova_science/Screens/StartScreen/SignUpScreen.dart';
import 'package:provider/provider.dart';
import 'package:nova_science/Service/AuthService.dart' as service;
import 'Modals/CourseAndSectionAndVideos.dart';
import 'Screens/AdminPanal/CourseManagement.dart';
import 'Screens/AdminPanal/DashboardOverview.dart';
import 'Screens/AdminPanal/Reports and Analytics.dart';
import 'Screens/AdminPanal/SystemSettingsScreen.dart';
import 'Screens/AdminPanal/UserManagement.dart';
import 'Screens/CourseScreen.dart';
import 'Screens/StartScreen/EditProfileScreen.dart';
import 'Screens/StartScreen/HomePage.dart';
import 'Screens/StartScreen/JoinScreen.dart';
import 'Screens/StartScreen/SignIn.dart';
import 'Screens/StartScreen/onboardingScreen.dart';
import 'Screens/StartScreen/SplashScreen.dart';
import 'Service/CourseProvider.dart';
import 'Service/AuthService.dart'; // Make sure to import your AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDfFK6mjHHGxmPyYfGq2srARJXgI5fPkz8',
      appId: '1:118096250417:android:38bfba3829b06d38d53710',
      messagingSenderId: '118096250417',
      projectId: 'novascience-31488',
      storageBucket: 'novascience-31488.appspot.com',
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CourseProvider()),
        ChangeNotifierProvider(create: (context) => service.AuthService()), // Correct instantiation
      ],
      child: const NovaScience(),
    ),
  );
}

class Routes {
  static const String splash = '/';
  static const String join = '/join';
  static const String signIn = '/signIn';
  static const String homeScreen = '/homeScreen';
  static const String editProfile = '/editProfile';
  static const String dashboardOverview = '/dashboardOverview';
  static const String userManagement = '/userManagement';
  static const String courseManagement = '/courseManagement';
  static const String reports = '/reports';
  static const String signUp = '/signUp';
  static const String systemSettings = '/systemSettings';
  static const String courseScreen = '/courseScreen';
}

class NovaScience extends StatelessWidget {
  const NovaScience({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nova Science',
      initialRoute: Routes.splash,
      onGenerateRoute: (settings) {
        WidgetBuilder builder = (context) => const ErrorScreen(); // Default value

        switch (settings.name) {

          case Routes.splash:
            builder = (context) => SplashScreen();
            break;
          case Routes.join:
            builder = (context) => const JoinScreen();
            break;
          case Routes.signIn:
            builder = (context) => SignInScreen();
            break;
          case Routes.homeScreen:
            builder = (context) => HomePage();
            break;
          case Routes.courseScreen:
            builder= (context) => CourseScreen(courseId: selectedCourseId!);
            break;
          case Routes.editProfile:
            builder = (context) => EditProfileScreen();
            break;
          case Routes.dashboardOverview:
            builder = (context) => DashboardOverviewScreen();
            break;
          case Routes.userManagement:
            builder = (context) => UserManagementScreen();
            break;
          case Routes.courseManagement:
            builder = (context) => CourseManagementScreen();
            break;
          case Routes.reports:
            builder = (context) => ReportsAnalyticsScreen();
            break;
          case Routes.signUp:
            builder = (context) => SignUpScreen();
            break;
          case Routes.systemSettings:
            builder = (context) => SystemSettingsScreen();
            break;
           // Optional: break here for clarity
        }
        return MaterialPageRoute(builder: builder);
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: const Center(child: Text('Page not found!')),
    );
  }
}
