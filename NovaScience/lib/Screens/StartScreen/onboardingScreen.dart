import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/StartScreen/JoinScreen.dart';
import 'StartScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  double _pageOffset = 0;

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
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Parallax PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => currentPage = index),
            itemBuilder: (context, index) {
              final delta = (index - _pageOffset).abs();
              final parallaxOffset = delta * 100;

              return FadeInRight(
                duration: Duration(milliseconds: 600),
                child: Transform.translate(
                  offset: Offset(parallaxOffset, 0),
                  child: _pages[index],
                ),
              );
            },
          ),

          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.1, 0.9],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Column(
                children: [
                  // Animated Dots
                  SlideInUp(
                    duration: Duration(milliseconds: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                            (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          width: currentPage == index ? 24.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: currentPage == index
                                ? Colors.blue
                                : Colors.white.withOpacity(0.5),
                            boxShadow: [
                              if (currentPage == index)
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Navigation Row
                  FadeInUp(
                    duration: Duration(milliseconds: 800),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        if (currentPage != 0)
                          ElasticIn(
                            duration: Duration(milliseconds: 600),
                            child: IconButton(
                              onPressed: () => _pageController.previousPage(
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              ),
                              icon: Icon(
                                CupertinoIcons.back,
                                color: Colors.white,
                                size: 32,
                              ),
                              splashColor: Colors.blue.withOpacity(0.2),
                            ),
                          )
                        else
                          SizedBox(width: 48),

                        // Next/Get Started Button
                        ElasticIn(
                          delay: Duration(milliseconds: 200),
                          duration: Duration(milliseconds: 600),
                          child: ElevatedButton(
                            onPressed: () {
                              if (currentPage == _pages.length - 1) {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: Duration(milliseconds: 800),
                                    pageBuilder: (_, __, ___) => JoinScreen(),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset(0.0, 0.5),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              } else {
                                _pageController.nextPage(
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff58B9A8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 35,
                                vertical: 18,
                              ),
                              shadowColor: Colors.blue.withOpacity(0.3),
                            ),
                            child: Text(
                              currentPage == _pages.length - 1 ? "Get Started" : "Next",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}