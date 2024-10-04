import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/StartScreen/JoinScreen.dart';
import 'StartScreen.dart';

class Onboardingscreen extends StatefulWidget {
  const Onboardingscreen({super.key});

  @override
  State<Onboardingscreen> createState() => _OnboardingscreenState();
}

class _OnboardingscreenState extends State<Onboardingscreen>
    with SingleTickerProviderStateMixin {
  PageController _pageController = PageController();
  int currentPage = 0;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Widget> _pages = [
    Startscreen(
      img: 'start1',
      heading: 'Embark on a Journey to Excellence',
      description:
      'Welcome to NOVA SCIENCE! Your guide to mastering A/L Science and O/L Maths and Science. Access expert resources to excel in your studies. Start your journey to academic success today!',
    ),
    Startscreen(
      img: 'start2',
      heading: 'Explore the World of Knowledge',
      description:
      'Welcome to NOVA SCIENCE! Discover resources for A/L Science and O/L Maths and Science. Access interactive lessons and expert insights to excel in your exams.',
    ),
    Startscreen(
      img: 'start3',
      heading: 'Unlock Your Potential with NOVA SCIENCE!',
      description:
      'At NOVA SCIENCE, we believe in your potential. Our tailored resources for A/L Science and O/L Maths and Science will help you unlock your capabilities. Dive into our lessons and achieve academic success!',
    ),
    Startscreen(
      img: 'start4',
      heading: 'Begin Your Path to Academic Excellence',
      description:
      'NOVA SCIENCE guides your academic journey with a focus on A/L Science and O/L Maths and Science. Equip yourself with the knowledge and tools to master your subjects and excel in your exams. Start today!',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller and animation
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _pageController.addListener(() {
      _animationController.reset();
      _animationController.forward();
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _pages[index],
                ),
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button animation and visibility control
                AnimatedOpacity(
                  opacity: currentPage == 0 ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 500),
                  child: currentPage == 0
                      ? SizedBox.shrink()
                      : IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    },
                    icon: Icon(CupertinoIcons.back, color: Colors.blue),
                  ),
                ),
                // Dots indicator with animation
                Row(
                  children: List.generate(
                    _pages.length,
                        (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      width: currentPage == index ? 12.0 : 8.0,
                      height: currentPage == index ? 12.0 : 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPage == index
                            ? Colors.blue
                            : Colors.grey,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4.0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Next or Finish button
                currentPage == _pages.length - 1
                    ? TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinScreen(),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color(0xff58B9A8),
                    ),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  child: Text(
                    "Finish",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : IconButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                  },
                  icon: Icon(CupertinoIcons.forward, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
