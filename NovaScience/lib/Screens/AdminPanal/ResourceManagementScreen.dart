import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../StartScreen/NovaDesignSystem.dart';
import '../StartScreen/ResourceDetailScreen.dart';
import '../StartScreen/ResourceUtils.dart';

class ResourceManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  ResourceManagementScreen({this.arguments});

  @override
  _ResourceManagementScreenState createState() => _ResourceManagementScreenState();
}

// Using TickerProviderStateMixin to support multiple animation controllers
class _ResourceManagementScreenState extends State<ResourceManagementScreen> with TickerProviderStateMixin {
  // Design colors
  final Color primaryColor = NovaDesignSystem.primaryColor;
  final Color secondaryColor = NovaDesignSystem.secondaryColor;
  final Color accentColor = NovaDesignSystem.accentColor;
  final Color tertiaryColor = NovaDesignSystem.tertiaryColor;
  final Color backgroundColor = Color(0xFFF8F9FC);

  // State variables
  bool isLoading = true;
  bool isAdmin = false;
  List<DocumentSnapshot> resources = [];
  String? selectedCategory;
  String? selectedStream;
  List<String> categories = ['All Categories'];
  List<String> streams = ['All Streams'];

  // Animation controller for list animations
  late AnimationController _animationController;

  // For search functionality
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  bool isSearchVisible = true;
  FocusNode searchFocusNode = FocusNode();

  // For tab navigation
  late TabController _tabController;
  final List<String> _tabs = ['All Resources', 'My Uploads', 'Analytics'];

  // For editing mode
  bool isEditing = false;
  String? editingResourceId;
  Map<String, dynamic>? editingResourceData;

  // For sorting
  String sortField = 'uploadDate';
  bool sortAscending = false;

  // For resource statistics
  Map<String, dynamic> resourceStats = {
    'totalCount': 0,
    'streamCounts': {},
    'categoryCounts': {},
  };

  // Store top resources separately to avoid type casting issues
  List<Map<String, dynamic>> topResources = [];

  // Scroll controller for handling scroll behaviors
  late ScrollController _scrollController;
  bool isScrolled = false;

  // Resource dashboard metrics
  int totalResources = 0;
  int totalViews = 0;
  int recentUploads = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Initialize tab controller
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Initialize scroll controller and add listener
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Check if we're in editing mode from arguments
    if (widget.arguments != null) {
      isEditing = widget.arguments!['editing'] ?? false;
      editingResourceId = widget.arguments!['resourceId'];

      if (isEditing && editingResourceId != null) {
        _loadResourceForEditing(editingResourceId!);
      }
    }

    _checkUserRole();
    _loadCategories();
    _loadStreams();
    _loadResources();
    _loadDashboardMetrics();
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && !isScrolled) {
      setState(() {
        isScrolled = true;
      });
    } else if (_scrollController.offset <= 100 && isScrolled) {
      setState(() {
        isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          // Only admin can access this screen
          isAdmin = userDoc.data()?['role'] == 'Admin';
        });

        // If not admin, show error and navigate back
        if (!isAdmin) {
          // Need to delay to avoid build errors
          Future.delayed(Duration.zero, () {
            _showAccessDeniedDialog();
          });
        }
      } else {
        // If no user is logged in, show error and navigate back
        Future.delayed(Duration.zero, () {
          _showAccessDeniedDialog();
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Access Denied',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Text(
                'You do not have permission to access the Resource Management Dashboard.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please contact an administrator if you need access to this area.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            child: Text(
              'Go Back',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Navigate back
            },
          ),
        ],
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _loadResourceForEditing(String resourceId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('resources')
          .doc(resourceId)
          .get();

      if (doc.exists) {
        setState(() {
          editingResourceData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error loading resource for editing: $e');
      _showErrorSnackBar('Error loading resource for editing: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('resources')
          .get();

      Set<String> uniqueCategories = {'All Categories'};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['category'] != null && data['category'].toString().isNotEmpty) {
          uniqueCategories.add(data['category']);
        }
      }

      setState(() {
        categories = uniqueCategories.toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadStreams() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('resources')
          .get();

      Set<String> uniqueStreams = {'All Streams'};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['stream'] != null && data['stream'].toString().isNotEmpty) {
          uniqueStreams.add(data['stream']);
        }
      }

      setState(() {
        streams = uniqueStreams.toList();
      });
    } catch (e) {
      print('Error loading streams: $e');
    }
  }

  Future<void> _loadResources() async {
    if (!isAdmin) return;

    setState(() {
      isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('resources');

      // Apply filters
      if (selectedCategory != null && selectedCategory != 'All Categories') {
        query = query.where('category', isEqualTo: selectedCategory);
      }

      if (selectedStream != null && selectedStream != 'All Streams') {
        query = query.where('stream', isEqualTo: selectedStream);
      }

      // Apply search
      if (searchQuery.isNotEmpty) {
        // Using a simplified approach - in a real app, you might want a more sophisticated search
        query = query.where('title', isGreaterThanOrEqualTo: searchQuery)
            .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff');
      }

      // Apply sorting
      query = query.orderBy(sortField, descending: !sortAscending);

      // If on "My Uploads" tab, only show current user's uploads
      if (_tabController.index == 1) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          query = query.where('uploaderId', isEqualTo: user.uid);
        }
      }

      final snapshot = await query.get();

      setState(() {
        resources = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading resources: $e');
      setState(() {
        isLoading = false;
      });

      // Show error message
      _showErrorSnackBar('Error loading resources: $e');
    }
  }

  Future<void> _loadDashboardMetrics() async {
    try {
      // Get total resources count
      final resourcesSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .get();

      // Calculate total views
      int views = 0;
      List<Map<String, dynamic>> tempTopResources = [];

      // Process each document
      for (var doc in resourcesSnapshot.docs) {
        final data = doc.data();
        final id = doc.id;

        // Add to view count
        if (data['viewCount'] != null) {
          views += (data['viewCount'] as int);
        }

        // Create a new map for the top resource
        Map<String, dynamic> resourceMap = {
          'id': id,
          'title': data['title'] ?? 'Untitled',
          'category': data['category'] ?? 'Unknown',
          'stream': data['stream'],
          'subcategory': data['subcategory'],
          'viewCount': data['viewCount'] ?? 0,
        };

        tempTopResources.add(resourceMap);
      }

      // Sort by view count
      tempTopResources.sort((a, b) {
        final aCount = a['viewCount'] as int;
        final bCount = b['viewCount'] as int;
        return bCount.compareTo(aCount);
      });

      // Take top 5
      tempTopResources = tempTopResources.take(5).toList();

      // Get recent uploads (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentUploadsSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .where('uploadDate', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Get resource stats for charts
      final stats = await ResourceUtils.getResourceStats();

      setState(() {
        totalResources = resourcesSnapshot.docs.length;
        totalViews = views;
        recentUploads = recentUploadsSnapshot.docs.length;
        resourceStats = stats;

        // Store top resources separately to avoid casting issues
        topResources = tempTopResources;
      });
    } catch (e) {
      print('Error loading dashboard metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If editing a resource, show edit form instead
    if (isEditing && editingResourceData != null) {
      return _buildEditResourceScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildTopDashboard(),
            ),
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),
            SliverToBoxAdapter(
              child: _buildSearchAndFilters(),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // All resources tab
            _buildResourcesTab(),

            // My uploads tab
            _buildResourcesTab(),

            // Analytics tab
            _buildAnalyticsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      title: Text(
        'Resource Management',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded),
          color: Colors.white,
          tooltip: isSearchVisible ? 'Hide Search' : 'Show Search',
          onPressed: () {
            setState(() {
              isSearchVisible = !isSearchVisible;
              if (isSearchVisible) {
                // Focus the search field when showing
                Future.delayed(Duration(milliseconds: 100), () {
                  searchFocusNode.requestFocus();
                });
              }
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.refresh_rounded),
          color: Colors.white,
          tooltip: 'Refresh',
          onPressed: () {
            _loadResources();
            _loadDashboardMetrics();
            _showSuccessSnackBar('Resources refreshed');
          },
        ),
        _buildSortMenuButton(),
      ],
    );
  }

  Widget _buildSortMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort_rounded, color: Colors.white),
      tooltip: 'Sort Resources',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: Offset(0, 50),
      onSelected: (value) {
        if (value.startsWith('sort_')) {
          final field = value.split('_')[1];
          setState(() {
            if (sortField == field) {
              sortAscending = !sortAscending;
            } else {
              sortField = field;
              sortAscending = false;
            }
          });
          _loadResources();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'sort_uploadDate',
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: sortField == 'uploadDate' ? tertiaryColor : Colors.grey,
              ),
              SizedBox(width: 12),
              Text(
                'Date ${sortField == 'uploadDate' ? (sortAscending ? '(Oldest)' : '(Newest)') : ''}',
                style: GoogleFonts.poppins(
                  fontWeight: sortField == 'uploadDate' ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort_title',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha_rounded,
                size: 18,
                color: sortField == 'title' ? tertiaryColor : Colors.grey,
              ),
              SizedBox(width: 12),
              Text(
                'Title ${sortField == 'title' ? (sortAscending ? '(A-Z)' : '(Z-A)') : ''}',
                style: GoogleFonts.poppins(
                  fontWeight: sortField == 'title' ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort_viewCount',
          child: Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 18,
                color: sortField == 'viewCount' ? tertiaryColor : Colors.grey,
              ),
              SizedBox(width: 12),
              Text(
                'Views ${sortField == 'viewCount' ? (sortAscending ? '(Lowest)' : '(Highest)') : ''}',
                style: GoogleFonts.poppins(
                  fontWeight: sortField == 'viewCount' ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopDashboard() {
    return Container(
      color: primaryColor,
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildDashboardMetricCard(
                title: 'Total Resources',
                value: totalResources.toString(),
                icon: Icons.folder_rounded,
                iconColor: Colors.blue,
                change: '+5% from last month',
                positiveChange: true,
              ),
              SizedBox(width: 12),
              _buildDashboardMetricCard(
                title: 'Total Views',
                value: totalViews.toString(),
                icon: Icons.visibility_rounded,
                iconColor: Colors.green,
                change: '+12% from last month',
                positiveChange: true,
              ),
              SizedBox(width: 12),
              _buildDashboardMetricCard(
                title: 'Recent Uploads',
                value: recentUploads.toString(),
                icon: Icons.cloud_upload_rounded,
                iconColor: Colors.orange,
                change: 'Last 30 days',
                showChangeIcon: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String change,
    bool positiveChange = true,
    bool showChangeIcon = true,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                if (showChangeIcon)
                  Icon(
                    positiveChange ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: positiveChange ? Colors.green.shade600 : Colors.red.shade600,
                    size: 14,
                  ),
                if (showChangeIcon) SizedBox(width: 4),
                Expanded(
                  child: Text(
                    change,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: showChangeIcon
                          ? (positiveChange ? Colors.green.shade600 : Colors.red.shade600)
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: tertiaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: tertiaryColor,
            width: 3,
          ),
          insets: EdgeInsets.symmetric(horizontal: 24),
        ),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        onTap: (index) {
          // Reload resources when tab changes
          _loadResources();
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: isSearchVisible ? null : 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: isSearchVisible ? 16 : 0,
          bottom: isSearchVisible ? 16 : 0,
        ),
        child: Column(
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                focusNode: searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by title, category or uploader...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade600,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                      _loadResources();
                    },
                  )
                      : null,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });

                  // Debounce search queries
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (searchQuery == value) {
                      _loadResources();
                    }
                  });
                },
              ),
            ),

            SizedBox(height: 16),

            // Filters row
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: selectedCategory ?? 'All Categories',
                    icon: Icons.category_rounded,
                    items: categories,
                    onSelected: (newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                      _loadResources();
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildFilterChip(
                    label: selectedStream ?? 'All Streams',
                    icon: Icons.school_rounded,
                    items: streams,
                    onSelected: (newValue) {
                      setState(() {
                        selectedStream = newValue;
                      });
                      _loadResources();
                    },
                  ),
                ),
              ],
            ),

            // Clear filters button (only shown when filters are active)
            if (selectedCategory != 'All Categories' || selectedStream != 'All Streams')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategory = 'All Categories';
                      selectedStream = 'All Streams';
                    });
                    _loadResources();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Clear All Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    final isCustom = label != 'All Categories' && label != 'All Streams';

    return Container(
      decoration: BoxDecoration(
        color: isCustom ? tertiaryColor.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCustom ? tertiaryColor.withOpacity(0.5) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        offset: Offset(0, 40),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: isCustom ? tertiaryColor : Colors.grey.shade700,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isCustom ? tertiaryColor : Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: isCustom ? tertiaryColor : Colors.grey.shade700,
                size: 20,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => items.map((item) {
          return PopupMenuItem<String>(
            value: item,
            child: Row(
              children: [
                Icon(
                  item == label ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: item == label ? tertiaryColor : Colors.grey.shade400,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: item == label ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(context, '/resource_screen')
            .then((_) {
          _loadResources();
          _loadDashboardMetrics();
        });
      },
      backgroundColor: tertiaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: Icon(Icons.add_rounded),
      label: Text(
        'Add Resource',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    if (isLoading) {
      return _buildLoadingShimmer();
    }

    if (resources.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: resources.length,
        itemBuilder: (context, index) {
          final doc = resources[index];
          final data = doc.data() as Map<String, dynamic>;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 300),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildResourceCard(doc.id, data),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_off_rounded,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No Resources Found',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                searchQuery.isNotEmpty || selectedCategory != 'All Categories' || selectedStream != 'All Streams'
                    ? 'Try changing your search or filters to find what you\'re looking for.'
                    : 'Get started by adding resources for students to access.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              if (searchQuery.isNotEmpty || selectedCategory != 'All Categories' || selectedStream != 'All Streams')
                ElevatedButton.icon(
                  icon: Icon(Icons.filter_alt_off_rounded),
                  label: Text(
                    'Clear All Filters',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      searchQuery = '';
                      selectedCategory = 'All Categories';
                      selectedStream = 'All Streams';
                    });
                    _loadResources();
                  },
                )
              else
                ElevatedButton.icon(
                  icon: Icon(Icons.add_rounded),
                  label: Text(
                    'Add New Resource',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tertiaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/resource_screen')
                        .then((_) {
                      _loadResources();
                      _loadDashboardMetrics();
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard(String id, Map<String, dynamic> data) {
    // Determine category icon and color
    IconData categoryIcon;
    Color categoryColor;

    switch (data['category']) {
      case 'Exam Papers':
        if (data['subcategory'] != null) {
          categoryIcon = ResourceUtils.subcategoryIcons[data['subcategory']] ?? Icons.description_rounded;
          categoryColor = ResourceUtils.getSubcategoryColor(data['subcategory']);
        } else {
          categoryIcon = Icons.description_rounded;
          categoryColor = Colors.blue.shade700;
        }
        break;
      case 'Notes':
        categoryIcon = Icons.note_rounded;
        categoryColor = Colors.green.shade700;
        break;
      case 'Tutorials':
        categoryIcon = Icons.school_rounded;
        categoryColor = Colors.orange.shade700;
        break;
      case 'Books':
        categoryIcon = Icons.book_rounded;
        categoryColor = Colors.purple.shade700;
        break;
      default:
        categoryIcon = Icons.insert_drive_file_rounded;
        categoryColor = Colors.grey.shade700;
    }

    // Format date
    String formattedDate = 'Unknown';
    if (data['uploadDate'] != null) {
      final timestamp = data['uploadDate'] as Timestamp;
      formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceDetailScreen(resourceId: id),
            ),
          ).then((_) {
            _loadResources();
            _loadDashboardMetrics();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resource icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 30,
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Resource details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Untitled',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),

                        // Tags row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Category tag
                            _buildTag(
                              label: data['category'] ?? 'Unknown',
                              color: categoryColor,
                              icon: categoryIcon,
                            ),

                            // Stream tag
                            if (data['stream'] != null)
                              _buildTag(
                                label: data['stream'],
                                color: ResourceUtils.streamColors[data['stream']] ?? Colors.blue,
                                icon: Icons.school_rounded,
                              ),

                            // Subcategory tag (for Exam Papers)
                            if (data['category'] == 'Exam Papers' && data['subcategory'] != null)
                              _buildTag(
                                label: data['subcategory'],
                                color: ResourceUtils.getSubcategoryColor(data['subcategory']),
                                icon: ResourceUtils.subcategoryIcons[data['subcategory']] ?? Icons.description_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Fixed: Improve Row layout to prevent overflows
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetaItem(
                      icon: Icons.person_rounded,
                      value: data['uploadedBy'] ?? 'Unknown',
                    ),
                    SizedBox(width: 16),
                    _buildMetaItem(
                      icon: Icons.calendar_today_rounded,
                      value: formattedDate,
                    ),
                    SizedBox(width: 16),
                    _buildMetaItem(
                      icon: Icons.visibility_rounded,
                      value: '${data['viewCount'] ?? 0} views',
                    ),

                    SizedBox(width: 16),

                    // Action buttons
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      tooltip: 'Edit',
                      onTap: () {
                        setState(() {
                          isEditing = true;
                          editingResourceId = id;
                          editingResourceData = data;
                        });
                      },
                    ),

                    SizedBox(width: 8),

                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      tooltip: 'Delete',
                      onTap: () {
                        _showDeleteConfirmation(id, data['title'] ?? 'this resource');
                      },
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

  Widget _buildTag({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String resourceId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Delete Resource',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
            ],
          ),
          titlePadding: EdgeInsets.only(left: 24, right: 24, top: 24),
          contentPadding: EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Are you sure you want to delete:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The resource and its associated file will be permanently deleted.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete_outline_rounded, size: 20),
              label: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(context);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(tertiaryColor),
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  await ResourceUtils.deleteResource(resourceId);

                  // Dismiss loading dialog
                  Navigator.pop(context);

                  // Refresh resources and metrics
                  _loadResources();
                  _loadDashboardMetrics();

                  // Show success message
                  _showSuccessSnackBar('Resource deleted successfully');
                } catch (e) {
                  // Dismiss loading dialog
                  Navigator.pop(context);

                  // Show error message
                  _showErrorSnackBar('Error deleting resource: $e');
                }
              },
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Distribution Card
          _buildSectionHeader('Resource Distribution', Icons.pie_chart_rounded),
          SizedBox(height: 12),
          _buildDistributionCard(),

          SizedBox(height: 24),

          // Academic Stream Distribution
          _buildSectionHeader('Academic Stream Distribution', Icons.bar_chart_rounded),
          SizedBox(height: 12),
          _buildStreamDistributionCard(),

          SizedBox(height: 24),

          // Top Resources
          _buildSectionHeader('Most Viewed Resources', Icons.trending_up_rounded),
          SizedBox(height: 12),
          _buildTopResourcesCard(),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionCard() {
    final Map<String, int> categoryCounts = Map<String, int>.from(resourceStats['categoryCounts'] ?? {});

    // Define colors for different categories
    final Map<String, Color> categoryColors = {
      'Exam Papers': Colors.blue.shade700,
      'Notes': Colors.green.shade700,
      'Tutorials': Colors.orange.shade700,
      'Books': Colors.purple.shade700,
    };

    // Prepare data for pie chart
    List<PieChartSectionData> sections = [];

    categoryCounts.forEach((category, count) {
      final color = categoryColors[category] ?? Colors.grey.shade700;
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '$count',
          radius: 80,
          titleStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          badgeWidget: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: color,
              size: 12,
            ),
          ),
          badgePositionPercentageOffset: 1.0,
        ),
      );
    });

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Pie chart
          Container(
            height: 250,
            child: sections.isEmpty
                ? Center(
              child: Text(
                'No data available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            )
                : PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 0,
                startDegreeOffset: -90,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Legend for pie chart
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: categoryColors.entries.map((entry) {
              final category = entry.key;
              final color = entry.value;
              final count = categoryCounts[category] ?? 0;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$category ($count)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamDistributionCard() {
    final Map<String, int> streamCounts = Map<String, int>.from(resourceStats['streamCounts'] ?? {});
    final int totalCount = resourceStats['totalCount'] ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...streamCounts.entries.map((entry) => _buildProgressBar(
            label: entry.key,
            value: entry.value,
            total: totalCount,
            color: _getStreamColor(entry.key),
          )),

          if (streamCounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No data available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final double percentage = total > 0 ? value / total : 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Text(
                '$value / $total',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Stack(
            children: [
              // Background
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Progress
              Container(
                height: 10,
                width: MediaQuery.of(context).size.width * percentage * 0.85, // Adjust for padding
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // Percentage label
              Positioned(
                right: 0,
                top: -2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopResourcesCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Use the separate topResources list that was created in _loadDashboardMetrics
          if (topResources.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No resources available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < topResources.length; i++)
              _buildTopResourceItem(
                index: i + 1,
                id: topResources[i]['id'],
                title: topResources[i]['title'] ?? 'Untitled',
                category: topResources[i]['category'] ?? 'Unknown',
                viewCount: topResources[i]['viewCount'] ?? 0,
                iconData: _getCategoryIcon(topResources[i]['category'] ?? 'Unknown'),
                color: _getCategoryColor(topResources[i]['category'] ?? 'Unknown'),
              ),
        ],
      ),
    );
  }

  Widget _buildTopResourceItem({
    required int index,
    required String id,
    required String title,
    required String category,
    required int viewCount,
    required IconData iconData,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceDetailScreen(resourceId: id),
          ),
        ).then((_) {
          _loadResources();
          _loadDashboardMetrics();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: index <= 3 ? color.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: index <= 3 ? color : Colors.grey.shade600,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Resource icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: color,
                  size: 20,
                ),
              ),
            ),

            SizedBox(width: 12),

            // Resource details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.visibility_rounded,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$viewCount views',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // View details button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Exam Papers':
        return Icons.description_rounded;
      case 'Notes':
        return Icons.note_rounded;
      case 'Tutorials':
        return Icons.school_rounded;
      case 'Books':
        return Icons.book_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Exam Papers':
        return Colors.blue.shade700;
      case 'Notes':
        return Colors.green.shade700;
      case 'Tutorials':
        return Colors.orange.shade700;
      case 'Books':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStreamColor(String stream) {
    switch (stream) {
      case 'Science Stream':
        return Colors.blue.shade700;
      case 'Arts Stream':
        return Colors.purple.shade700;
      case 'Commerce Stream':
        return Colors.green.shade700;
      case 'Technology Stream':
        return Colors.orange.shade700;
      case 'O/L':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Edit resource screen
  Widget _buildEditResourceScreen() {
    if (editingResourceData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Resource'),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Text('Error: Resource data not found'),
        ),
      );
    }

    // Controllers for editing form
    final titleController = TextEditingController(text: editingResourceData!['title']);
    final descriptionController = TextEditingController(text: editingResourceData!['description'] ?? '');

    // Default values
    String selectedStream = editingResourceData!['stream'];
    String selectedCategory = editingResourceData!['category'];
    String? selectedSubcategory = editingResourceData!['subcategory'];
    bool isUploading = false;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Edit Resource',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              isEditing = false;
              editingResourceId = null;
              editingResourceData = null;
            });
          },
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.visibility_rounded, color: Colors.white),
            label: Text(
              'Preview',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () {
              if (editingResourceId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResourceDetailScreen(resourceId: editingResourceId!),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              // Form content
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Edit form header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: Offset(0, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: primaryColor,
                                size: 25,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Resource Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Update information for this resource',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Edit form fields
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: Offset(0, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          _buildFormLabel('Resource Title *'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: titleController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter resource title',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Stream selection
                          _buildFormLabel('Academic Stream *'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStream,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down_rounded),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                ),
                                items: streams
                                    .where((stream) => stream != 'All Streams')
                                    .map((stream) {
                                  return DropdownMenuItem<String>(
                                    value: stream,
                                    child: Text(stream),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedStream = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Category selection
                          _buildFormLabel('Resource Category *'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down_rounded),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                ),
                                items: categories
                                    .where((category) => category != 'All Categories')
                                    .map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedCategory = value;

                                      // Reset subcategory if changing away from Exam Papers
                                      if (value != 'Exam Papers') {
                                        selectedSubcategory = null;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),

                          // Show subcategory selector only for Exam Papers
                          if (selectedCategory == 'Exam Papers') ...[
                            SizedBox(height: 24),
                            _buildFormLabel('Exam Paper Type *'),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSubcategory,
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down_rounded),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.grey.shade800,
                                  ),
                                  items: [
                                    'Term Papers',
                                    'Model Papers',
                                    'Past Papers',
                                    'Term Paper Keys',
                                    'Past Paper Keys',
                                  ].map((subcategory) {
                                    return DropdownMenuItem<String>(
                                      value: subcategory,
                                      child: Text(subcategory),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedSubcategory = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],

                          SizedBox(height: 24),

                          // Description field
                          _buildFormLabel('Resource Description'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: descriptionController,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter a detailed description of this resource (optional)',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Warning about file
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.amber.shade800,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Note: File cannot be changed. To change the file, please delete this resource and upload a new one.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    backgroundColor: Colors.grey.shade100,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isEditing = false;
                                      editingResourceId = null;
                                      editingResourceData = null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  child: Text(
                                    'Save Changes',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tertiaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: isUploading ? null : () async {
                                    // Validate form
                                    if (titleController.text.trim().isEmpty) {
                                      _showErrorSnackBar('Please enter a title');
                                      return;
                                    }

                                    setState(() {
                                      isUploading = true;
                                    });

                                    try {
                                      // Prepare updated data
                                      Map<String, dynamic> updatedData = {
                                        'title': titleController.text.trim(),
                                        'description': descriptionController.text.trim(),
                                        'stream': selectedStream,
                                        'category': selectedCategory,
                                        'lastUpdated': Timestamp.now(),
                                      };

                                      // Add or remove subcategory field
                                      if (selectedCategory == 'Exam Papers' && selectedSubcategory != null) {
                                        updatedData['subcategory'] = selectedSubcategory;
                                      } else if (editingResourceData!.containsKey('subcategory')) {
                                        // Need to use FieldValue.delete() to remove the field
                                        updatedData['subcategory'] = FieldValue.delete();
                                      }

                                      // Update resource in Firestore
                                      await FirebaseFirestore.instance
                                          .collection('resources')
                                          .doc(editingResourceId)
                                          .update(updatedData);

                                      // Reset editing state
                                      setState(() {
                                        isEditing = false;
                                        editingResourceId = null;
                                        editingResourceData = null;
                                        isUploading = false;
                                      });

                                      // Reload resources
                                      _loadResources();
                                      _loadDashboardMetrics();

                                      // Show success message
                                      _showSuccessSnackBar('Resource updated successfully');
                                    } catch (e) {
                                      setState(() {
                                        isUploading = false;
                                      });

                                      // Show error message
                                      _showErrorSnackBar('Error updating resource: $e');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),

              // Loading overlay
              if (isUploading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(tertiaryColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Updating resource...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }
}