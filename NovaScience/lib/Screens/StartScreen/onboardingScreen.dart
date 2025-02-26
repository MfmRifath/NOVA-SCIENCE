import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nova_science/Screens/StartScreen/JoinScreen.dart';
import 'StartScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  int _currentPage = 0;

  // Using the specified color palette for all upcoming screens
  static const Color darkGreen = Color(0xFF11261f);
  static const Color darkYellow = Color(0xFF123755);
  static const Color maroon = Color(0xFF722626);

  // Onboarding content data
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'start1',
      'heading': 'Personalized Learning Pathways',
      'description': 'NOVA LEARN offers tailored educational resources designed to optimize your learning journey. Leverage expert-curated content to transform your academic potential.',
      'icon': 'assets/icons/personalized.png',
    },
    {
      'image': 'start2',
      'heading': 'Advanced Learning Strategies',
      'description': 'Discover comprehensive study resources meticulously crafted for A/L Science and O/L Mathematics. Our interactive lessons provide deep insights and strategic learning approaches.',
      'icon': 'assets/icons/strategy.png',
    },
    {
      'image': 'start3',
      'heading': 'Cutting-Edge Educational Technology',
      'description': 'Embrace a revolutionary learning experience with NOVA LEARN. Our adaptive technology and expert-designed curriculum empower you to exceed academic expectations.',
      'icon': 'assets/icons/technology.png',
    },
    {
      'image': 'start4',
      'heading': 'Your Academic Success Starts Here',
      'description': 'Unlock your full potential with data-driven learning strategies. NOVA LEARN provides the tools, insights, and support to help you achieve exceptional academic excellence.',
      'icon': 'assets/icons/success.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToJoinScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => JoinScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkGreen, darkYellow],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo and skip button
              _buildHeader(screenSize),

              // Main content area with page view
              Expanded(
                child: _buildPageView(screenSize),
              ),

              // Bottom navigation section
              _buildBottomNavigation(screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
              ),
              SizedBox(width: 12),
              Text(
                'NOVA SCIENCE',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          // Skip button
          TextButton(
            onPressed: _navigateToJoinScreen,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.8),
            ),
            child: Text(
              'SKIP',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(Size screenSize) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _onboardingData.length,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemBuilder: (context, index) {
        return _buildOnboardingPage(screenSize, _onboardingData[index]);
      },
    );
  }

  Widget _buildOnboardingPage(Size screenSize, Map<String, String> data) {
    return Column(
      children: [
        // Top section with illustration
        Expanded(
          flex: 4,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: darkGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: darkGreen.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/${data['image']}.png',
                fit: BoxFit.contain,
                height: screenSize.height * 0.3,
              ),
            ),
          ),
        ),

        // Bottom section with content
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section indicator
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: maroon,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),

                // Heading
                Text(
                  data['heading'] ?? '',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 16),

                // Description
                Expanded(
                  child: Text(
                    data['description'] ?? '',
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
                  (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? maroon
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(height: 32),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              _currentPage > 0
                  ? _buildNavigationButton(
                icon: Icons.arrow_back,
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              )
                  : SizedBox(width: 48),

              // Next/Get Started button
              _buildPrimaryButton(
                text: _currentPage == _onboardingData.length - 1
                    ? "GET STARTED"
                    : "NEXT",
                onPressed: () {
                  if (_currentPage == _onboardingData.length - 1) {
                    _navigateToJoinScreen();
                  } else {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return MaterialButton(
      onPressed: onPressed,
      height: 48,
      minWidth: 48,
      color: darkGreen.withOpacity(0.3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}