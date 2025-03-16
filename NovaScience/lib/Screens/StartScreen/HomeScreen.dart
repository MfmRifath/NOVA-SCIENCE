import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nova_science/Screens/AddCourseScreen.dart';

import '../../Service/AdvertisementProvider.dart';
import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
import '../AdminPanal/AdvertismenrtCourousal.dart';
import 'AppTheme.dart';
import 'RatingUtils.dart';
import 'StarRating.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Timers
  Timer? _debounce;

  // State variables
  String _searchQuery = '';
  bool isAdmin = false;
  bool _isLoading = true;
  bool _isSearching = false;
  List<QueryDocumentSnapshot<Object?>> _searchResults = [];

  // Filter selections
  String _selectedCategory = "All";
  String _selectedMedium = "All";
  String _searchType = "All";

  // Lists for filters and tabs
  final List<String> _categories = [
    "All",
    "Science",
    "Math",
    "Language",
    "Technology",
    "Arts",
    "History"
  ];
  final List<String> _mediumOptions = ["All", "Tamil", "English", "Sinhala"];
  final List<String> _searchTypes = ["All", "Title", "Instructor", "Subject"];
  final List<String> _tabs = ["Explore", "My Learning", "Popular", "New"];

  // Services
  AuthService authService = AuthService();

  // Stats for dashboard
  int _enrolledCoursesCount = 0;
  int _totalCoursesAvailable = 0;
  double _averageRating = 0.0;
  int _coursesWithHighRating = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _checkAdminStatus();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  void _handleTabChange() {
    // Close search if tab changes
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchController.clear();
        _searchQuery = '';
        _searchResults.clear();
        _isSearching = false;
      });
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch courses
      await Provider.of<CourseProvider>(context, listen: false).fetchCourses();

      // Get user data if logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userEnrolledCourses = await Provider.of<CourseProvider>(
            context, listen: false)
            .getEnrolledCourses(currentUser.uid);

        setState(() {
          _enrolledCoursesCount = userEnrolledCourses?.length ?? 0;
        });
      }

      // Fetch stats for the dashboard
      await _fetchCourseStats();
    } catch (e) {
      print('Error fetching initial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCourseStats() async {
    try {
      final courseProvider = Provider.of<CourseProvider>(
          context, listen: false);

      // Get counts for different course types
      final freeCourses = await courseProvider.getFreeCourses();
      final premiumCourses = await courseProvider.getPremiumCourses();

      _totalCoursesAvailable =
          (freeCourses?.length ?? 0) + (premiumCourses.length);

      // Calculate average rating from available courses
      double totalRating = 0;
      int ratedCoursesCount = 0;
      int highRatedCount = 0;

      // Process free courses ratings
      if (freeCourses != null) {
        for (var doc in freeCourses) {
          final data = doc.data() as Map<String, dynamic>;
          // Use RatingUtils to ensure consistent rating data
          final processedData = RatingUtils.ensureRatingData(data);
          if (processedData['averageRating'] > 0) {
            double rating = processedData['averageRating'];
            totalRating += rating;
            ratedCoursesCount++;

            if (rating >= 4.0) {
              highRatedCount++;
            }
          }
        }
      }

      // Process premium courses ratings
      for (var doc in premiumCourses) {
        final data = doc.data() as Map<String, dynamic>;
        // Use RatingUtils to ensure consistent rating data
        final processedData = RatingUtils.ensureRatingData(data);
        if (processedData['averageRating'] > 0) {
          double rating = processedData['averageRating'];
          totalRating += rating;
          ratedCoursesCount++;

          if (rating >= 4.0) {
            highRatedCount++;
          }
        }
      }

      setState(() {
        _averageRating =
        ratedCoursesCount > 0 ? totalRating / ratedCoursesCount : 0;
        _coursesWithHighRating = highRatedCount;
      });
    } catch (e) {
      print('Error fetching course stats: $e');
    }
  }


  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
          if (_searchQuery.isNotEmpty) {
            _performSearch();
          }
        });
      }
    });
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Get courses collection reference
      final coursesRef = FirebaseFirestore.instance.collection('courses');

      // Get all courses that are approved
      final querySnapshot = await coursesRef
          .where('isApproved', isEqualTo: true)
          .get();

      // Filter locally based on search type and query
      _searchResults = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['courseTitle'] ?? '').toString().toLowerCase();
        final instructor = (data['instructor'] ?? '').toString().toLowerCase();
        final subject = (data['subject'] ?? '').toString().toLowerCase();

        // Apply medium filter if selected
        if (_selectedMedium != "All") {
          final medium = (data['medium'] ?? '').toString().toLowerCase();
          if (medium != _selectedMedium.toLowerCase()) {
            return false;
          }
        }

        // Apply category filter if selected
        if (_selectedCategory != "All") {
          final category = (data['category'] ?? '').toString().toLowerCase();
          if (category != _selectedCategory.toLowerCase()) {
            return false;
          }
        }

        // Apply search type filter
        switch (_searchType) {
          case "Title":
            return title.contains(_searchQuery);
          case "Instructor":
            return instructor.contains(_searchQuery);
          case "Subject":
            return subject.contains(_searchQuery);
          case "All":
          default:
            return title.contains(_searchQuery) ||
                instructor.contains(_searchQuery) ||
                subject.contains(_searchQuery);
        }
      }).toList();
    } catch (e) {
      print('Error searching courses: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            isAdmin = userDoc.data()?['role'] == 'Admin';
          });
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<CourseProvider>(context, listen: false).fetchCourses();
    await _fetchCourseStats();

    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults.clear();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final adProvider = Provider.of<AdvertisementProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : RefreshIndicator(
          onRefresh: _onRefresh,
          backgroundColor: Colors.white,
          color: AppTheme.primaryColor,
          child: Column(
            children: [
              // App Bar with Logo and Search
              _buildAppBar(),

              // Tab Bar - Better visual appearance
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: AppTheme.primaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: _tabs.map((tab) =>
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(tab),
                        ),
                      )
                  ).toList(),
                ),
              ),

              // Medium filter with animated selection
              if (_searchQuery.isEmpty) _buildMediumsRow(),

              // Search Results or Tab content
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResultsView()
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    // Explore Tab
                    _buildExploreTab(courseProvider, adProvider),

                    // My Learning Tab
                    _buildMyLearningTab(courseProvider),

                    // Popular Tab
                    _buildPopularTab(courseProvider),

                    // New Tab
                    _buildNewTab(courseProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Only show FAB for admin users
      floatingActionButton: isAdmin ? _buildAdminFAB() : null,
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom animated loader
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your courses...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AddCourseScreen()),
        );
      },
      backgroundColor: AppTheme.primaryColor,
      elevation: 4,
      icon: Icon(Icons.add_circle_outline, color: Colors.white),
      label: Text(
        "Add Course",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with logo and notification
          Row(
            children: [
              // App logo
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    width: 32,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(
                          Icons.school,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'NOVA LEARN',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Notifications with badge - Now using real notification count
              FutureBuilder<int>(
                  future: _getUnreadNotificationsCount(),
                  builder: (context, snapshot) {
                    final notificationCount = snapshot.data ?? 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Stack(
                          children: [
                            Icon(Icons.notifications_outlined,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    notificationCount > 9
                                        ? '9+'
                                        : notificationCount.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () {
                          // Navigate to notifications
                        },
                      ),
                    );
                  }
              ),
            ],
          ),

          SizedBox(height: 12),

          // Search Bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                // Search icon
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search courses, instructors...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                        if (_searchQuery.isNotEmpty) {
                          _performSearch();
                        }
                      });
                    },
                  ),
                ),
                // Clear button if text exists
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _searchResults.clear();
                        _isSearching = false;
                      });
                    },
                  ),
                // Filter button
                Container(
                  margin: EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _searchType != "All"
                        ? AppTheme.primaryColor.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_list,
                      color: _searchType != "All"
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                      size: 20,
                    ),
                    tooltip: 'Search filters',
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      setState(() {
                        _searchType = value;
                        if (_searchQuery.isNotEmpty) {
                          _performSearch();
                        }
                      });
                    },
                    itemBuilder: (context) =>
                        _searchTypes.map((type) {
                          return PopupMenuItem<String>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  _searchType == type
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _searchType == type
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  type,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: _searchType == type
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getUnreadNotificationsCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return notificationsSnapshot.docs.length;
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  Widget _buildSearchResultsView() {
    if (_isSearching) {
      return _buildSearchingState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return AnimatedOpacity(
          opacity: 1.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _buildCourseListItem(_searchResults[index]),
        );
      },
    );
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Searching courses...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: SingleChildScrollView( // Added ScrollView to handle overflow
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF11261f).withOpacity(0.1),
                // Using our green color theme
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: const Color(0xFF11261f), // Using our green color theme
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No courses found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.8, // Responsive width
              constraints: BoxConstraints(maxWidth: 280), // Maximum width
              child: Text(
                'Try adjusting your search or filters for better results',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _searchResults.clear();
                  _isSearching = false;
                  _searchType = "All";
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11261f),
                // Using our green color theme
                foregroundColor: Colors.white,
                elevation: 1,
                // Reduced elevation
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Less rounded corners
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediumsRow() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medium label
          Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Text(
              'Medium:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          // Medium options
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediumOptions.length,
              padding: EdgeInsets.only(right: 16),
              itemBuilder: (context, index) {
                final medium = _mediumOptions[index];
                final isSelected = medium == _selectedMedium;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMedium = medium;
                      if (_searchQuery.isNotEmpty) {
                        _performSearch();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      medium,
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight
                            .w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB VIEWS
  Widget _buildExploreTab(CourseProvider courseProvider,
      AdvertisementProvider adProvider) {
    return ListView(
      padding: EdgeInsets.only(top: 16, bottom: 24),
      children: [
        // Dashboard stats card - NEW ADDITION for realistic data
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatsCard(),
        ),
        SizedBox(height: 24),

        // Category filters - horizontal scrollable row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Categories',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(height: 8),
        _buildCategoriesRow(),
        SizedBox(height: 24),

        // Hero banner with gradient and animation
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildHeroBanner(),
        ),
        SizedBox(height: 24),

        // Advertisement Carousel with better presentation
        if (adProvider.advertisements.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Featured',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 180,
                margin: EdgeInsets.only(bottom: 24),
                child: ClipRRect(
                  child: AdvertisementCarousel(
                      advertisementProvider: adProvider),
                ),
              ),
            ],
          ),

        // Continue Learning Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('Continue Learning'),
        ),
        SizedBox(height: 12),
        _buildContinueLearningSection(courseProvider),
        SizedBox(height: 24),

        // Popular Courses
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('Popular Courses'),
        ),
        SizedBox(height: 12),
        _buildPopularCoursesSection(courseProvider),
        SizedBox(height: 24),

        // New Courses
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildSectionHeader('New Courses'),
        ),
        SizedBox(height: 12),
        _buildNewCoursesSection(courseProvider),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.secondaryColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Your Learning Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              // Enrolled courses
              Expanded(
                child: _buildStatItem(
                  _enrolledCoursesCount.toString(),
                  'Enrolled',
                  Icons.school,
                ),
              ),
              // Available courses
              Expanded(
                child: _buildStatItem(
                  _totalCoursesAvailable.toString(),
                  'Available',
                  Icons.auto_stories,
                ),
              ),
              // Average rating
              Expanded(
                child: _buildStatItem(
                  _averageRating.toStringAsFixed(1),
                  'Avg. Rating',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesRow() {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
                if (_searchQuery.isNotEmpty) {
                  _performSearch();
                }
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyLearningTab(CourseProvider courseProvider) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildSignInPrompt();
    }

    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: courseProvider.getEnrolledCourses(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading your courses');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'You haven\'t enrolled in any courses yet',
            'Explore our course catalog and start learning today!',
            Icons.school_outlined,
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_lesson,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Your Learning',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Learning stats card
            _buildLearningStatsCard(snapshot.data!.length),
            SizedBox(height: 24),
            // Courses grid
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return _buildEnrolledCourseCard(snapshot.data![index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLearningStatsCard(int courseCount) {
    // Calculate learning time and progress
    return FutureBuilder<Map<String, dynamic>>(
        future: _calculateLearningStats(courseCount),
        builder: (context, snapshot) {
          final totalHours = snapshot.data?['totalHours'] ?? 0;
          final completionPercentage = snapshot.data?['completionPercentage'] ??
              0;

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.tertiaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon part
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                // Text part
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You\'re enrolled in $courseCount courses',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total learning time: ${totalHours.toStringAsFixed(
                            1)} hours',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Overall completion: ${completionPercentage
                                .toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: completionPercentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Future<Map<String, dynamic>> _calculateLearningStats(int courseCount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'totalHours': 0.0,
          'completionPercentage': 0.0,
        };
      }

      // Get all enrolled courses from Firestore
      QuerySnapshot enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalHours = 0;
      double totalProgress = 0;

      if (enrollmentsSnapshot.docs.isNotEmpty) {
        for (var doc in enrollmentsSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          double progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
          double hoursSpent = (data['hoursSpent'] as num?)?.toDouble() ?? 0.0;

          totalHours += hoursSpent;
          totalProgress += progress;
        }
      }

      double averageCompletion = courseCount > 0
          ? totalProgress / courseCount
          : 0;

      return {
        'totalHours': totalHours,
        'completionPercentage': averageCompletion,
      };
    } catch (e) {
      print('Error calculating learning stats: $e');
      return {
        'totalHours': 0.0,
        'completionPercentage': 0.0,
      };
    }
  }

  Widget _buildPopularTab(CourseProvider courseProvider) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
      future: courseProvider.getPremiumCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading popular courses');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No popular courses found',
            'Check back later for our most popular courses',
            Icons.star_outline,
          );
        }

        // Filter to only show approved courses
        final approvedCourses = snapshot.data!.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isApproved'] == true;
        }).toList();

        if (approvedCourses.isEmpty) {
          return _buildEmptyState(
            'No popular courses available yet',
            'Check back later for our featured content',
            Icons.star_outline,
          );
        }

        // Use a list of futures to fetch extended data for each course
        List<Future<Map<String, dynamic>>> extendedDataFutures = approvedCourses.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _fetchExtendedCourseData(doc.id, data);
        }).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(extendedDataFutures),
          builder: (context, extendedDataSnapshot) {
            if (extendedDataSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            }

            if (!extendedDataSnapshot.hasData || extendedDataSnapshot.data!.isEmpty) {
              return _buildEmptyState(
                'Failed to load course data',
                'Please try again later',
                Icons.error_outline,
              );
            }

            // Sort by rating and then by enrollment count
            final coursesData = extendedDataSnapshot.data!;
            coursesData.sort((a, b) {
              // First compare by rating
              final aRating = a['averageRating'] as double? ?? 0.0;
              final bRating = b['averageRating'] as double? ?? 0.0;

              int ratingComparison = bRating.compareTo(aRating);
              if (ratingComparison != 0) {
                return ratingComparison; // Higher ratings first
              }

              // If ratings are equal, compare by enrollment count
              final aStudents = a['students'] as int? ?? 0;
              final bStudents = b['students'] as int? ?? 0;
              return bStudents.compareTo(aStudents); // More students first
            });

            // Create a map of course data to course IDs
            Map<String, String> courseIdMap = {};
            for (int i = 0; i < approvedCourses.length; i++) {
              final doc = approvedCourses[i];
              final data = doc.data() as Map<String, dynamic>;
              courseIdMap[data['courseTitle']] = doc.id;
            }

            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[700],
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Popular Courses',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Our highest-rated and most enrolled courses',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),

                // Grid layout with staggered animation
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: coursesData.length,
                  itemBuilder: (context, index) {
                    final courseData = coursesData[index];
                    // Find the matching course ID
                    String courseId = '';
                    for (var doc in approvedCourses) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['courseTitle'] == courseData['courseTitle']) {
                        courseId = doc.id;
                        break;
                      }
                    }

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildCourseGridItem(courseData, courseId),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget _buildNewTab(CourseProvider courseProvider) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: courseProvider.getFreeCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading new courses');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No new courses found',
            'Check back later for newly added courses',
            Icons.new_releases_outlined,
          );
        }

        // Filter to only show approved courses and sort by date
        final approvedCourses = snapshot.data!.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isApproved'] == true;
        }).toList();

        // Sort by date added (newest first)
        approvedCourses.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTimestamp = aData['createdAt'] as Timestamp?;
          final bTimestamp = bData['createdAt'] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp); // Descending order
        });

        if (approvedCourses.isEmpty) {
          return _buildEmptyState(
            'No new courses available yet',
            'Check back soon for our latest content',
            Icons.new_releases_outlined,
          );
        }

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Icon(
                  Icons.new_releases,
                  color: AppTheme.tertiaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'New Courses',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Our latest content for you to explore',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ...approvedCourses
                .map((course) => _buildCourseListItem(course))
                .toList(),
          ],
        );
      },
    );
  }

  // UI COMPONENTS
  Widget _buildHeroBanner() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔥 POPULAR',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Advance Your Career',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Discover courses taught by industry experts and expand your skills',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore All',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Hero illustration - can be replaced with an SVG or image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.school,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Row(
            children: [
              Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueLearningSection(CourseProvider courseProvider) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildSignInPromptCompact();
    }

    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: courseProvider.getEnrolledCourses(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHorizontalLoadingShimmer();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Error loading your courses',
              style: GoogleFonts.poppins(
                color: Colors.red[400],
                fontSize: 14,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateCompact(
            'No courses in progress',
            'Start learning by enrolling in a course',
            Icons.play_circle_outline,
          );
        }

        // Sort courses by last accessed date (if available)
        List<QueryDocumentSnapshot<Object?>> sortedCourses = List.from(
            snapshot.data!);
        sortedCourses.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aLastAccessed = aData['lastAccessed'] as Timestamp?;
          final bLastAccessed = bData['lastAccessed'] as Timestamp?;

          if (aLastAccessed == null && bLastAccessed == null) return 0;
          if (aLastAccessed == null) return 1;
          if (bLastAccessed == null) return -1;

          return bLastAccessed.compareTo(aLastAccessed); // Descending order
        });

        return Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedCourses.length,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildContinueLearningCard(sortedCourses[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularCoursesSection(CourseProvider courseProvider) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
      future: courseProvider.getPremiumCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHorizontalLoadingShimmer();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Error loading popular courses',
              style: GoogleFonts.poppins(
                color: Colors.red[400],
                fontSize: 14,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateCompact(
            'No popular courses',
            'Check back later for trending courses',
            Icons.trending_up,
          );
        }

        // Filter to only show approved courses and sort by rating
        final approvedCourses = snapshot.data!.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isApproved'] == true;
        }).toList();

        approvedCourses.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          // Sort by rating
          final aRating = (aData['rating'] as num?)?.toDouble() ?? 0.0;
          final bRating = (bData['rating'] as num?)?.toDouble() ?? 0.0;

          if (aRating != bRating) {
            return bRating.compareTo(aRating); // Higher ratings first
          }

          // If ratings are equal, sort by enrollment count
          final aStudents = aData['students'] as int? ?? 0;
          final bStudents = bData['students'] as int? ?? 0;
          return bStudents.compareTo(aStudents); // More students first
        });

        if (approvedCourses.isEmpty) {
          return _buildEmptyStateCompact(
            'No popular courses',
            'Check back later for trending courses',
            Icons.trending_up,
          );
        }

        // Use a list of futures to fetch extended data for each course
        List<Future<Map<String, dynamic>>> extendedDataFutures = approvedCourses.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _fetchExtendedCourseData(doc.id, data);
        }).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(extendedDataFutures),
          builder: (context, extendedDataSnapshot) {
            if (extendedDataSnapshot.connectionState == ConnectionState.waiting) {
              return _buildHorizontalLoadingShimmer();
            }

            if (!extendedDataSnapshot.hasData || extendedDataSnapshot.data!.isEmpty) {
              return _buildEmptyStateCompact(
                'Failed to load courses',
                'Please try again later',
                Icons.error_outline,
              );
            }

            // Sort by rating and enrollment count
            final coursesData = extendedDataSnapshot.data!;

            // Create a map of course data to course IDs
            Map<String, String> courseIdMap = {};
            for (int i = 0; i < approvedCourses.length; i++) {
              final doc = approvedCourses[i];
              courseIdMap[doc.id] = doc.id;
            }

            return Container(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coursesData.length,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  // Get the course ID that corresponds to this course data
                  final courseTitle = coursesData[index]['courseTitle'] ?? '';
                  String courseId = '';

                  // Find the corresponding document to get the ID
                  for (var doc in approvedCourses) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['courseTitle'] == courseTitle) {
                      courseId = doc.id;
                      break;
                    }
                  }

                  return _buildPopularCourseCard(coursesData[index], courseId);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewCoursesSection(CourseProvider courseProvider) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: courseProvider.getFreeCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHorizontalLoadingShimmer();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Error loading new courses',
              style: GoogleFonts.poppins(
                color: Colors.red[400],
                fontSize: 14,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateCompact(
            'No new courses',
            'Check back later for new additions',
            Icons.auto_awesome,
          );
        }

        // Filter to only show approved courses
        final approvedCourses = snapshot.data!.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isApproved'] == true;
        }).toList();

        // Sort by creation date (newest first)
        approvedCourses.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aCreatedAt = aData['createdAt'] as Timestamp?;
          final bCreatedAt = bData['createdAt'] as Timestamp?;

          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;

          return bCreatedAt.compareTo(aCreatedAt); // Descending order
        });

        if (approvedCourses.isEmpty) {
          return _buildEmptyStateCompact(
            'No new courses',
            'Check back later for new additions',
            Icons.auto_awesome,
          );
        }

        return Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: approvedCourses.length,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return _buildNewCourseCard(approvedCourses[index]);
            },
          ),
        );
      },
    );
  }

  // CARD COMPONENTS
  Widget _buildContinueLearningCard(QueryDocumentSnapshot<Object?> course) {
    final data = course.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getCourseProgress(course.id, user?.uid),
      builder: (context, snapshot) {
        final progress = snapshot.data?['progress'] as double? ?? 0.0;
        final lastLesson = snapshot.data?['lastLessonTitle'] as String? ??
            'Continue learning';

        return Container(
          width: 230,
          margin: EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/courseScreen',
                  arguments: course.id,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section with title overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: data['imageUrl'] != null && data['imageUrl']
                            .toString()
                            .isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: data['imageUrl'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[400]!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) =>
                              Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.book,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              ),
                        )
                            : Container(
                          height: 100,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.book,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      // Progress indicator overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.tertiaryColor,
                                  ),
                                  strokeWidth: 3,
                                ),
                                Text(
                                  '${progress.toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Last accessed label
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: Text(
                            lastLesson,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Content part
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['courseTitle'] ?? 'Course Title',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['instructor'] ?? 'Instructor',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Continue button
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/courseScreen',
                                arguments: course.id,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.tertiaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  // FIX: Updated the popular course card to use enhanced data
  Widget _buildPopularCourseCard(Map<String, dynamic> courseData, String courseId) {
    // IMPORTANT: Process the course data to ensure we have consistent rating values
    // This is where the fix is applied - properly process the data using RatingUtils
    final processedData = RatingUtils.ensureRatingData(courseData);

    // Extract rating data with correct typing
    final double rating = processedData['averageRating'] ?? 0.0;
    final int ratingCount = processedData['ratingCount'] ?? 0;
    final int studentCount = courseData['actualStudentCount'] ?? courseData['students'] ?? 0;

    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/courseScreen',
              arguments: courseId,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: courseData['imageUrl'] != null && courseData['imageUrl'].toString().isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: courseData['imageUrl'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                        : Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  // Premium badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber[700],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Student count
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '$studentCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Content part
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseData['courseTitle'] ?? 'Course Title',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Fixed StarRating widget with correct parameters
                        Expanded(
                          child: StarRating(
                            rating: rating,
                            totalRatings: ratingCount,
                            size: 16,
                            showRatingCount: true,
                            compact: false,
                            starColor: Colors.amber[700]!,
                            emptyStarColor: Colors.grey[300]!,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            courseData['price'] != null ? 'RS ${courseData['price']}' : 'Free',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          courseData['duration'] ?? '8 weeks',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewCourseCard(QueryDocumentSnapshot<Object?> course) {
    final data = course.data() as Map<String, dynamic>;
    final bool isFree = (data['price'] == 0 || data['price'] == null || data['price'] == '0');
    final DateTime? createdDate = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final bool isRecent = createdDate != null &&
        DateTime.now().difference(createdDate).inDays < 30;

    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/courseScreen',
              arguments: course.id,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                        : Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  // New badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isRecent
                            ? AppTheme.tertiaryColor
                            : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRecent ? Icons.auto_awesome : Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isRecent ? 'NEW' : 'FREE',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Added date
                  if (createdDate != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_formatDate(createdDate)}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content part
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['courseTitle'] ?? 'Course Title',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['instructor'] ?? 'Instructor',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Enrollment count and price badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${data['students'] ?? 0} students',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFree ? Colors.green : AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isFree ? 'FREE' : 'RS ${data['price']}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format date as "MMM d" (e.g., "Mar 15")
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference < 7) {
      return difference == 0
          ? 'Today'
          : difference == 1
          ? 'Yesterday'
          : '$difference days ago';
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildEnrolledCourseCard(QueryDocumentSnapshot<Object?> course) {
    final data = course.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<Map<String, dynamic>>(
        future: _getCourseProgress(course.id, user?.uid),
    builder: (context, snapshot) {
    final progress = snapshot.data?['progress'] as double? ?? 0.0;
    final lastAccessedTimestamp = snapshot.data?['lastAccessed'] as Timestamp?;
    final lastAccessedDate = lastAccessedTimestamp?.toDate();
    final lastAccessedString = lastAccessedDate != null ? _formatDate(lastAccessedDate) : '';

    return Container(
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 8,
    offset: Offset(0, 4),
    ),
    ],
    ),
    child: Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
    Navigator.pushNamed(
    context,
    '/courseScreen',
    arguments: course.id,
    );
    },
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Course image with progress
    Stack(
    children: [
    ClipRRect(
    borderRadius: BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    ),
    child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
    ? CachedNetworkImage(
    imageUrl: data['imageUrl'],
    height: 100,
    width: double.infinity,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
    color: Colors.grey[300],
    child: Center(
    child: SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(
    Colors.grey[400]!,
    ),
    ),
    ),
    ),
    ),
    errorWidget: (context, url, error) => Container(
    color: Colors.grey[300],
    child: Icon(
    Icons.book,
    size: 40,
    color: Colors.grey[400],
    ),
    ),
    )
        : Container(
    height: 120,
    color: Colors.grey[300],
    child: Center(
    child: Icon(
    Icons.book,
    size: 40,
    color: Colors.grey[400],
    ),
    ),
    ),
    ),
    // Progress circular indicator
    Positioned(
    right: 8,
    bottom: -16,
    child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 4,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Center(
    child:Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.tertiaryColor,
          ),
          strokeWidth: 3,
        ),
        Text(
          '${progress.toInt()}%',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.tertiaryColor,
          ),
        ),
      ],
    ),
    ),
    ),
    ),

      // Last accessed indicator
      if (lastAccessedString.isNotEmpty)
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  lastAccessedString,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
    ),
      // Course info
      Padding(
        padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['courseTitle'] ?? 'Course Title',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 14,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['instructor'] ?? 'Instructor',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Continue button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/courseScreen',
                    arguments: course.id,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
    );
    },
    );
  }

  Widget _buildCourseGridItem(Map<String, dynamic> courseData, String courseId) {
    // Process data to ensure consistent rating values
    final processedData = RatingUtils.ensureRatingData(courseData);

    // Extract data with proper typing
    final bool isPremium = courseData['isPremium'] == true || courseData['status'] == 'Premium';
    final double rating = processedData['averageRating'] ?? 0.0;
    final int ratingCount = processedData['ratingCount'] ?? 0;
    final int students = courseData['actualStudentCount'] ?? courseData['students'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/courseScreen',
              arguments: courseId,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image with badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: courseData['imageUrl'] != null && courseData['imageUrl'].toString().isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: courseData['imageUrl'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!,
                              ),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                        : Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  if (isPremium)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PREMIUM',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Course info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['courseTitle'] ?? 'Course Title',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              courseData['instructor'] ?? 'Instructor',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      // Rating and student count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: StarRating(
                              rating: rating,
                              totalRatings: ratingCount,
                              size: 14,
                              showRatingCount: false,
                              compact: true,
                              starColor: Colors.amber[700]!,
                              emptyStarColor: Colors.grey[300]!,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$students',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8),
                      // Price and enroll button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              courseData['price'] == 0 || courseData['price'] == null || courseData['price'] == '0'
                                  ? 'FREE'
                                  : 'RS ${courseData['price']}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/courseScreen',
                                  arguments: courseId,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Enroll',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseListItem(QueryDocumentSnapshot<Object?> course) {
    // Get the raw course data
    final Map<String, dynamic> rawData = course.data() as Map<String, dynamic>;

    // Use data providers rather than raw data when possible
    return FutureBuilder<Map<String, dynamic>>(
      // Fetch real-time course details from multiple sources
      future: _fetchExtendedCourseData(course.id, rawData),
      builder: (context, snapshot) {
        // While loading, show a shimmer effect
        if (!snapshot.hasData) {
          return _buildCourseItemShimmer();
        }

        // Extract enhanced data with real-time information
        final data = snapshot.data!;

        final bool isFree = (data['price'] == null || data['price'] == 0 || data['price'] == '0');
        final bool isPremium = data['isPremium'] == true || data['status'] == 'Premium';
        final int studentCount = data['actualStudentCount'] ?? data['students'] ?? 0;
        final double rating = data['rating'] ?? 0.0;
        final int ratingCount = data['ratingCount'] ?? 0;
        final bool isRecentlyAdded = data['isRecentlyAdded'] ?? false;
        final int sectionsCount = data['sectionsCount'] ?? 0;
        final int videosCount = data['videosCount'] ?? 0;
        final String medium = data['medium'] ?? 'English';

        // Determine badge type based on real data
        final String badgeText = isPremium
            ? 'PREMIUM'
            : isRecentlyAdded
            ? 'NEW'
            : rating >= 4.5 && ratingCount >= 5
            ? 'TOP RATED'
            : 'FEATURED';

        final Color badgeStartColor = isPremium
            ? Colors.amber[700]!
            : isRecentlyAdded
            ? AppTheme.tertiaryColor
            : AppTheme.secondaryColor;

        final Color badgeEndColor = isPremium
            ? Colors.amber[800]!
            : isRecentlyAdded
            ? Color(0xFF0A7268)
            : Color(0xFF7C3AED);

        final IconData badgeIcon = isPremium
            ? Icons.star
            : isRecentlyAdded
            ? Icons.auto_awesome
            : Icons.trending_up;

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/courseScreen',
                  arguments: course.id,
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course image with Hero animation for smooth transitions
                  Stack(
                    children: [
                      Hero(
                        tag: 'course-image-${course.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: data['imageUrl'],
                            height: 130,
                            width: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Image not available',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                              : Container(
                            height: 130,
                            width: 120,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 40,
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No Image',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Badge (dynamic based on course properties)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [badgeStartColor, badgeEndColor],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                badgeIcon,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                badgeText,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Medium indicator
                      Positioned(
                        top: 12,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            medium,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // Rating indicator
                      if (rating > 0)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: StarRating(
                              rating: rating,
                              size: 14,
                              totalRatings: ratingCount,
                              showRatingCount: false,
                              compact: true,
                              starColor: Colors.amber[400]!,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Course information
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium indicator if applicable
                          if (isPremium)
                            Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber[200]!, width: 1),
                              ),
                              child: Text(
                                '✨ PREMIUM CONTENT',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[800],
                                ),
                              ),
                            ),

                          // Title and price badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  data['courseTitle'] ?? 'Course Title',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                  maxLines: isPremium ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isFree
                                        ? [Color(0xFF34D399), Color(0xFF10B981)]
                                        : [AppTheme.secondaryColor, Color(0xFF7C3AED)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isFree
                                          ? Color(0xFF34D399).withOpacity(0.3)
                                          : AppTheme.secondaryColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  isFree ? 'FREE' : 'RS ${data['price']}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Instructor with icon
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['instructor'] ?? 'Instructor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),

                          // Subject with icon if available
                          if (data['subject'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.subject,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data['subject'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 8),

                          // Ratings and reviews count
                          Row(
                            children: [
                              StarRating(
                                rating: rating,
                                totalRatings: ratingCount,
                                size: 14,
                                showRatingCount: true,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Course content stats (sections and videos)
                          Row(
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$sectionsCount sections • $videosCount videos',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),

                          // Course details row (duration and student count)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Duration
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    data['duration'] ?? 'Self-paced',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              // Students
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    studentCount > 999
                                        ? '${(studentCount / 1000).toStringAsFixed(1)}k'
                                        : '$studentCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Call to action button
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 110,
                                height: 32,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/courseScreen',
                                      arguments: course.id,
                                    );
                                  },
                                  icon: Icon(
                                      isFree ? Icons.play_circle_outline : Icons.shopping_cart_outlined,
                                      size: 16
                                  ),
                                  label: Text(
                                    isFree ? 'Start' : 'Enroll',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFree ? AppTheme.tertiaryColor : AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Helper method to fetch extended course data from multiple sources
  Future<Map<String, dynamic>> _fetchExtendedCourseData(String courseId, Map<String, dynamic> baseData) async {
    Map<String, dynamic> enhancedData = Map.from(baseData);

    try {
      // Get the course from Firestore to ensure latest data
      DocumentSnapshot courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      QuerySnapshot feedbacksSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .collection('feedbacks')
          .get();

      // If we have direct feedbacks subcollection, use it
      if (feedbacksSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> feedbacks = [];
        double totalRating = 0.0;
        int validRatingCount = 0;

        for (var doc in feedbacksSnapshot.docs) {
          Map<String, dynamic> feedbackData = doc.data() as Map<String, dynamic>;
          feedbacks.add(feedbackData);

          if (feedbackData.containsKey('rating') && feedbackData['rating'] != null) {
            double rating = (feedbackData['rating'] as num).toDouble();
            if (rating > 0) {
              totalRating += rating;
              validRatingCount++;
            }
          }
        }

        // Update data with feedbacks and calculated average
        enhancedData['feedbacks'] = feedbacks;
        if (validRatingCount > 0) {
          enhancedData['averageRating'] = totalRating / validRatingCount;
          enhancedData['rating'] = totalRating / validRatingCount;
          enhancedData['ratingCount'] = validRatingCount;
        } else {
          enhancedData['averageRating'] = 0.0;
          enhancedData['rating'] = 0.0;
          enhancedData['ratingCount'] = 0;
        }
      }

      // Apply RatingUtils to ensure consistent rating data format
      enhancedData = RatingUtils.ensureRatingData(enhancedData);

      // Rest of the method remains the same
      // Fetch actual enrollment count
      final actualCount = await _getEnrollmentCount(courseId);
      enhancedData['actualStudentCount'] = actualCount;
      if (courseDoc.exists) {
        // Merge fresh data from Firestore
        Map<String, dynamic> freshData = courseDoc.data() as Map<String, dynamic>;
        enhancedData.addAll(freshData);

        // Apply RatingUtils to ensure consistent rating data
        enhancedData = RatingUtils.ensureRatingData(enhancedData);

        // Fetch actual enrollment count
        final actualCount = await _getEnrollmentCount(courseId);
        enhancedData['actualStudentCount'] = actualCount;

        // Check if course is recently added (within last 30 days)
        if (freshData.containsKey('createdAt')) {
          final createdAt = freshData['createdAt'] as Timestamp;
          final daysAgo = DateTime.now().difference(createdAt.toDate()).inDays;
          enhancedData['isRecentlyAdded'] = daysAgo <= 30;
        }

        // Count sections and videos
        if (freshData.containsKey('sections')) {
          final sections = freshData['sections'] as List<dynamic>? ?? [];
          enhancedData['sectionsCount'] = sections.length;

          int totalVideos = 0;
          for (var section in sections) {
            if (section is Map<String, dynamic> && section.containsKey('videos')) {
              totalVideos += (section['videos'] as List<dynamic>? ?? []).length;
            }
          }
          enhancedData['videosCount'] = totalVideos;
        }
      }
    } catch (e) {
      print('Error fetching extended course data: $e');
    }

    return enhancedData;
  }

// Get actual enrollment count for a course
  Future<int> _getEnrollmentCount(String courseId) async {
    try {
      // First check if the count is directly stored
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (courseDoc.exists) {
        final data = courseDoc.data() as Map<String, dynamic>;
        if (data.containsKey('enrolledUserIds')) {
          final enrolledUsers = data['enrolledUserIds'] as List<dynamic>? ?? [];
          return enrolledUsers.length;
        }
      }

      // If not, count users who have this course in their enrolledCourses array
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      int count = 0;
      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        if (userData.containsKey('enrolledCourses')) {
          final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

          // Check if the user is enrolled in this course
          bool isEnrolled = enrolledCourses.any((course) {
            if (course is Map<String, dynamic>) {
              return course['courseId'] == courseId;
            } else if (course is String) {
              return course == courseId;
            }
            return false;
          });

          if (isEnrolled) count++;
        }
      }

      return count;
    } catch (e) {
      print('Error getting enrollment count: $e');
      return 0;
    }
  }

// Loading state for course item
  Widget _buildCourseItemShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Content placeholders
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Subtitle placeholder
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Stats placeholder
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Spacer(),
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),

                    // Button placeholder
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 100,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // EMPTY STATES AND LOADING INDICATORS
  Widget _buildSignInPrompt() {
    return Center(
      child: Container(
        width: 320,
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Sign in to Access Your Courses',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Track your progress, earn certificates, and get personalized recommendations',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            // Sign in button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Create account text button
            TextButton(
              onPressed: () {
                // Navigate to register screen
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondaryColor,
              ),
              child: Text(
                'Create an account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPromptCompact() {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with illustration
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.lock_outline,
                size: 30,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(width: 20),
          // Text and button column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign in to track your progress',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Access your enrolled courses and continue learning',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    // Sign in button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to login screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 1,
                        ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Register button
                    TextButton(
                      onPressed: () {
                        // Navigate to register screen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.secondaryColor,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      ),
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: SingleChildScrollView(  // Add scroll capability to handle overflow
        child: Container(
          width: 320,
          margin: EdgeInsets.symmetric(vertical: 24), // Reduced vertical margin
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon in a circle - slightly smaller
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 35,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              SizedBox(height: 20), // Reduced spacing
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18, // Slightly smaller font
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8), // Reduced spacing
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24), // Reduced spacing
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(0); // Go to explore tab
                },
                icon: Icon(Icons.explore, size: 18),
                label: Text('Explore Courses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Slightly smaller padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyStateCompact(String title, String message, IconData icon) {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in a circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        width: 320,
        margin: EdgeInsets.symmetric(vertical: 40),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon in a circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red[400],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _onRefresh();
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLoadingShimmer() {
    return Container(
      height: 180,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 200,
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  // Content placeholders
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title placeholder
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        // Subtitle placeholder
                        Container(
                          width: 120,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // HELPER METHODS
  Future<Map<String, dynamic>> _getCourseProgress(String courseId, String? userId) async {
    final result = <String, dynamic>{};

    if (userId == null) {
      result['progress'] = 0.0;
      result['lastLessonTitle'] = '';
      return result;
    }

    try {
      // First try to get from enrollments collection (more detailed)
      final enrollmentQuery = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (enrollmentQuery.docs.isNotEmpty) {
        final enrollment = enrollmentQuery.docs.first.data();
        result['progress'] = enrollment['progress'] as double? ?? 0.0;
        result['lastLessonTitle'] = enrollment['lastLessonTitle'] as String? ?? '';
        result['lastAccessed'] = enrollment['lastAccessed'] as Timestamp?;
        result['enrollmentDate'] = enrollment['enrollmentDate'] as Timestamp?;
        return result;
      }

      // Fallback to user's enrolledCourses array
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('enrolledCourses')) {
          final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

          for (var courseData in enrolledCourses) {
            if (courseData is Map<String, dynamic> && courseData['courseId'] == courseId) {
              result['progress'] = courseData['progress'] as double? ?? 0.0;
              result['lastLessonTitle'] = courseData['lastLessonTitle'] as String? ?? '';
              result['lastAccessed'] = courseData['lastAccessed'] as Timestamp?;
              result['enrollmentDate'] = courseData['enrollmentDate'] as Timestamp?;
              return result;
            }
          }
        }
      }

      // Default values if no data found
      result['progress'] = 0.0;
      result['lastLessonTitle'] = '';

    } catch (e) {
      print('Error getting course progress: $e');
      result['progress'] = 0.0;
      result['lastLessonTitle'] = '';
    }

    return result;
  }
}