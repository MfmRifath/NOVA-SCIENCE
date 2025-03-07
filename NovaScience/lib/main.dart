import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/AdminPanal/EnrollUsersScreen.dart';
import 'package:nova_science/Screens/AdminPanal/ManageAdvertisementsScreen.dart';
import 'package:nova_science/Screens/AdminPanal/TeacherPaymentsScreen.dart';
import 'package:nova_science/Screens/StartScreen/ForgertPasswordScreen.dart';
import 'package:nova_science/Screens/StartScreen/HomeScreen.dart';
import 'package:nova_science/Screens/StartScreen/NotificationScreen.dart';
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
import 'Service/AdvertisementProvider.dart';
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
  AuthService authService = AuthService();
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      authService.storeFCMToken();
      authService.listenForTokenChanges();
    }
  });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CourseProvider()),
        ChangeNotifierProvider(create: (context) => service.AuthService()), // Correct instantiation
        ChangeNotifierProvider(create: (_) => AdvertisementProvider()),
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
  static const String enrollUsersScreen = '/enrollUsers';
  static const String notifications = '/notifications';
  static const String manageAdvertisements = '/manageAdvertisements';
  static const String forgetPassword = '/forgotPassword';
  static const String teachersPayments = '/teachersPayment';

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
            if (settings.arguments is String) {
              final courseId = settings.arguments as String;
              builder = (context) => CourseScreen(courseId: courseId);
            } else {
              builder = (context) => const ErrorScreen();
            }
            break;
          case Routes.editProfile:
            builder = (context) => EditProfileScreen();
            break;
          case Routes.dashboardOverview:
            builder = (context) => AdminDashboard();
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
          case Routes.enrollUsersScreen:
            builder = (context) => EnrollUsersScreen();
            break;
          case Routes.notifications:
            builder = (context) => NotificationScreen();
            break;
          case Routes.manageAdvertisements :
            builder = (context) => ManageAdvertisementsScreen();
            break;
          case Routes.teachersPayments :
            builder = (context) => TeacherPaymentsScreen();
            break;
           // Optional: break here for clarity
          case Routes.forgetPassword :
            builder = (context) => ForgotPasswordScreen();
            break;
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
