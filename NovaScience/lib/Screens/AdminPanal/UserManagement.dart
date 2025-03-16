import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../Modals/User.dart';
import '../../Service/AuthService.dart';
import 'UserDetailsScreen.dart';


class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<CustomUser> users = [];
  List<CustomUser> filteredUsers = [];
  List<CustomUser> recentlyRegisteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TabController? _tabController;

  // For user registration chart
  Map<String, int> _userRegistrationData = {};

  // Filters
  String _selectedRoleFilter = 'All';
  bool _onlyShowActiveUsers = false;

  // Sort options
  String _currentSortOption = 'Name'; // Default sort
  bool _isAscending = true;

  // Stats counters
  int _totalUsers = 0;
  int _teacherCount = 0;
  int _adminCount = 0;
  int _activeUsers = 0;

  // Custom color palette - using provided colors
  final Color primaryColor = const Color(0xFF11261f); // Green
  final Color secondaryColor = const Color(0xFF123755); // Yellow (actually blue)
  final Color accentColor = const Color(0xFF722626); // Maroon
  final Color successColor = const Color(0xFF2E7D32); // Green variant
  final Color dangerColor = const Color(0xFF8B0000); // Dark red
  final Color warningColor = const Color(0xFF856404); // Amber variant
  final Color surfaceColor = const Color(0xFFF5F5F5); // Light gray background
  final Color textDarkColor = const Color(0xFF212121); // Dark text
  final Color textLightColor = const Color(0xFFFAFAFA); // Light text
  final Color borderColor = const Color(0xFFDCDCDC); // Border color

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    _animationController!.forward();

    // Initialize tab controller
    _tabController = TabController(
      length: 4,
      vsync: this,
    );

    _tabController!.addListener(() {
      setState(() {});
    });

    _fetchUsers();
  }

  @override
  void dispose() {
    // Clean up all animations to prevent memory leaks
    _animationController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // Fetch users method with recently registered tracking
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      users = await _authService.fetchAllUsers();

      // Sort by registration date to find recently registered users
      users.sort((a, b) {
        final aDate = a.registrationDate ?? DateTime(2000);
        final bDate = b.registrationDate ?? DateTime(2000);
        return bDate.compareTo(aDate); // Most recent first
      });

      // Get recently registered users (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      recentlyRegisteredUsers = users.where((user) {
        return user.registrationDate != null &&
            user.registrationDate!.isAfter(thirtyDaysAgo);
      }).toList();

      // Prepare registration data for chart
      _prepareRegistrationChartData();

      // Apply default sorting
      _sortUsers();

      // Calculate statistics
      _calculateStatistics();

      // Apply initial filter
      _applyFilters();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching users: $e',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Prepare data for registration chart
  void _prepareRegistrationChartData() {
    _userRegistrationData = {};

    // Get the last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final formattedDate = DateFormat('MM/dd').format(date);
      _userRegistrationData[formattedDate] = 0;
    }

    // Count registrations per day
    for (var user in users) {
      if (user.registrationDate != null) {
        final regDate = user.registrationDate!;
        if (regDate.isAfter(DateTime.now().subtract(Duration(days: 7)))) {
          final formattedDate = DateFormat('MM/dd').format(regDate);
          _userRegistrationData[formattedDate] = (_userRegistrationData[formattedDate] ?? 0) + 1;
        }
      }
    }
  }

  // Calculate user statistics
  void _calculateStatistics() {
    _totalUsers = users.length;
    _teacherCount = users.where((user) => user.role?.toLowerCase() == 'teacher').length;
    _adminCount = users.where((user) => user.role?.toLowerCase() == 'admin').length;
    _activeUsers = users.where((user) => user.isLoggedIn ?? false).length;
  }

  // Apply filters to the user list
  void _applyFilters() {
    filteredUsers = users.where((user) {
      // Apply search filter
      final nameMatches = user.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final emailMatches = user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final roleMatches = user.role?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;

      // Apply role filter
      bool roleFilterMatches = true;
      if (_selectedRoleFilter != 'All') {
        roleFilterMatches = user.role?.toLowerCase() == _selectedRoleFilter.toLowerCase();
      }

      // Apply active users filter
      bool activeFilterMatches = true;
      if (_onlyShowActiveUsers) {
        activeFilterMatches = user.isLoggedIn ?? false;
      }

      return (nameMatches || emailMatches || roleMatches) &&
          roleFilterMatches &&
          activeFilterMatches;
    }).toList();

    // Apply current sort
    _sortUsers();
  }

  // Sort users based on current option
  void _sortUsers() {
    switch (_currentSortOption) {
      case 'Name':
        filteredUsers.sort((a, b) {
          final aName = a.name?.toLowerCase() ?? '';
          final bName = b.name?.toLowerCase() ?? '';
          return _isAscending ? aName.compareTo(bName) : bName.compareTo(aName);
        });
        break;
      case 'Email':
        filteredUsers.sort((a, b) {
          final aEmail = a.email?.toLowerCase() ?? '';
          final bEmail = b.email?.toLowerCase() ?? '';
          return _isAscending ? aEmail.compareTo(bEmail) : bEmail.compareTo(aEmail);
        });
        break;
      case 'Role':
        filteredUsers.sort((a, b) {
          final aRole = a.role?.toLowerCase() ?? '';
          final bRole = b.role?.toLowerCase() ?? '';
          return _isAscending ? aRole.compareTo(bRole) : bRole.compareTo(aRole);
        });
        break;
      case 'Registration Date':
        filteredUsers.sort((a, b) {
          final aDate = a.registrationDate ?? DateTime(2000);
          final bDate = b.registrationDate ?? DateTime(2000);
          return _isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
        break;
      case 'Last Active':
        filteredUsers.sort((a, b) {
          final aDate = a.lastActiveTime ?? DateTime(2000);
          final bDate = b.lastActiveTime ?? DateTime(2000);
          return _isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
        break;
    }
  }

  // Delete user method
  void _deleteUser(String email) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: surfaceColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                ),
                const SizedBox(height: 20),
                Text(
                  'Deleting user...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );

      // Find the user to delete from the local list
      CustomUser? userToDelete = users.firstWhere((user) => user.email == email);
      String? imageUrl = userToDelete.profileImageUrl;

      // Log the image URL for debugging
      print("Attempting to delete user with email: $email and image URL: $imageUrl");

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Re-authenticate the user if necessary
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: 'user_password', // Replace with the actual user's password
        );

        await user.reauthenticateWithCredential(credential);
        await user.delete();

        print("User deleted successfully from Firebase Authentication!");

        // Delete the user document from Firestore
        await FirebaseFirestore.instance.collection('users').doc(userToDelete.id).delete();
        print("User document deleted successfully from Firestore!");

        // Check if the image URL is valid before deleting
        if (imageUrl != null && !imageUrl.startsWith('https://via.placeholder.com')) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          print("Image deleted successfully from storage.");
        }

        // Close the loading dialog
        Navigator.of(context).pop();

        // Remove the user from the local lists
        setState(() {
          users.removeWhere((user) => user.email == email);
          filteredUsers.removeWhere((user) => user.email == email);
          recentlyRegisteredUsers.removeWhere((user) => user.email == email);
        });

        // Recalculate statistics
        _calculateStatistics();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'User deleted successfully!',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: textLightColor,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ));
      } else {
        // Close the loading dialog
        Navigator.of(context).pop();

        print("No user is currently signed in.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'No user is currently signed in.',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();

      // Handle errors
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Failed to delete user: $e',
          style: GoogleFonts.poppins(color: textLightColor),
        ),
        backgroundColor: dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ));
    }
  }

  // Edit user method
  void _editUser(BuildContext context, CustomUser user) async {
    CustomUser? updatedUser = await _showUserDialog(user: user);

    if (updatedUser != null) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: surfaceColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Updating user...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );

        // Call AuthService to update the user in Firestore
        await _authService.updateUserByEmail(
          email: user.email!,
          updatedData: {
            'name': updatedUser.name ?? '',
            'role': updatedUser.role ?? '',
            'phoneNumber': updatedUser.phoneNumber ?? '',
            'profileImageUrl': updatedUser.profileImageUrl ?? "https://via.placeholder.com/150",
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        );

        // Close loading dialog
        Navigator.of(context).pop();

        // Update UI to reflect changes
        int index = users.indexOf(user);
        if (index >= 0) {
          users[index] = updatedUser;
        }

        // Apply filters to update filtered users list
        _applyFilters();

        // Recalculate statistics after update
        _calculateStatistics();

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'User updated successfully!',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Failed to update user: $e',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textLightColor),
            onPressed: _fetchUsers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.dark_mode_rounded, color: textLightColor),
            onPressed: () {
              // Implement dark mode toggle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Dark mode will be available soon!',
                    style: GoogleFonts.poppins(color: textLightColor),
                  ),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            tooltip: 'Toggle Dark Mode',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: TabBar(
            controller: _tabController,
            indicatorColor: accentColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: textLightColor,
            unselectedLabelColor: textLightColor.withOpacity(0.7),
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'All Users'),
              Tab(text: 'Recently Added'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading users...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation!,
        child: TabBarView(
          controller: _tabController,
          children: [
            // ===== Dashboard Tab =====
            _buildDashboardTab(),

            // ===== All Users Tab =====
            _buildAllUsersTab(),

            // ===== Recently Registered Tab =====
            _buildRecentlyRegisteredTab(),

            // ===== Analytics Tab =====
            _buildAnalyticsTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController?.index == 1 || _tabController?.index == 2
          ? FloatingActionButton.extended(
        onPressed: () async {
          // Show the user dialog and wait for a result
          final newUser = await _showUserDialog();

          // If the dialog returns a non-null user, add it to your users list
          if (newUser != null) {
            setState(() {
              users.add(newUser);
              _applyFilters();
              _calculateStatistics();
            });
          }
        },
        tooltip: 'Add User',
        backgroundColor: accentColor,
        elevation: 4,
        icon: Icon(Icons.person_add_rounded, color: textLightColor),
        label: Text(
          'Add User',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textLightColor,
          ),
        ),
      )
          : null,
    );
  }

  // =============== Dashboard Tab ===============
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statistics Cards
          _buildStatisticsDashboard(),
          const SizedBox(height: 24),

          // Recently registered users section
          _buildSectionTitle('Recently Registered Users'),
          const SizedBox(height: 16),
          _buildRecentUsersList(limit: 5),

          const SizedBox(height: 24),

          // Currently Active Users
          _buildSectionTitle('Currently Active Users'),
          const SizedBox(height: 16),
          _buildActiveUsersList(),

          const SizedBox(height: 24),

          // Registration Trend Chart
          _buildSectionTitle('Registration Trend (Last 7 Days)'),
          const SizedBox(height: 16),
          _buildRegistrationChart(),

          const SizedBox(height: 24),

          // User Role Distribution
          _buildSectionTitle('User Role Distribution'),
          const SizedBox(height: 16),
          _buildRoleDistributionCards(),
        ],
      ),
    );
  }

  // =============== All Users Tab ===============
  Widget _buildAllUsersTab() {
    return Column(
      children: [
        // Search and filter bar
        _buildSearchAndFilterBar(),

        // User list
        Expanded(
          child: filteredUsers.isEmpty
              ? _buildEmptyState(
            icon: Icons.people_alt_rounded,
            title: 'No users found',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try changing your search or filters'
                : 'Add users using the button below',
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserTile(user);
            },
          ),
        ),
      ],
    );
  }

  // =============== Recently Registered Tab ===============
  Widget _buildRecentlyRegisteredTab() {
    return Column(
      children: [
        // Registration period selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                color: secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Last 30 Days',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  // Implement date range picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Date range picker will be available soon!',
                        style: GoogleFonts.poppins(color: textLightColor),
                      ),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.date_range_rounded, size: 18),
                label: Text('Change Period'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryColor,
                  side: BorderSide(color: secondaryColor),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Recent registrations chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildRegistrationChart(),
        ),

        const SizedBox(height: 16),

        // Recently registered users
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildSectionTitle('New Users'),
              const Spacer(),
              Text(
                '${recentlyRegisteredUsers.length} new registrations',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Recently registered users list
        Expanded(
          child: recentlyRegisteredUsers.isEmpty
              ? _buildEmptyState(
            icon: Icons.person_add_alt_1_rounded,
            title: 'No recent registrations',
            subtitle: 'New users will appear here',
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recentlyRegisteredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = recentlyRegisteredUsers[index];
              return _buildRecentUserTile(user);
            },
          ),
        ),
      ],
    );
  }

  // =============== Analytics Tab ===============
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // User growth chart
    _buildSectionTitle('User Growth'),
    const SizedBox(height: 16),
    Container(
    height: 300,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: primaryColor.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: _buildUserGrowthChart(),
    ),

    const SizedBox(height: 24),

    // Role distribution chart
    _buildSectionTitle('User Role Distribution'),
    const SizedBox(height: 16),
    Container(
    height: 300,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: primaryColor.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: _buildRoleDistributionChart(),
    ),

    const SizedBox(height: 24),

    // User activity metrics
    _buildSectionTitle('User Activity Metrics'),
    const SizedBox(height: 16),
    Row(
    children: [
    Expanded(
    child: _buildMetricCard(
    title: 'Average Sessions',
    value: '3.2',
    subtitle: 'per week',
    icon: Icons.insights_rounded,
    iconColor: secondaryColor,
    ),
    ),
    const SizedBox(width: 16),
    Expanded(
    child: _buildMetricCard(
    title: 'Session Duration',
    value: '18:45',
    subtitle: 'average time',
    icon: Icons.timer_rounded,
    iconColor: successColor,
    ),
    ),
    ],
    ),
    const SizedBox(height: 16),
    Row(
    children: [
    Expanded(
    child: _buildMetricCard(
    title: 'Active Users',
    value: '${_activeUsers}',
    subtitle: 'currently online',
    icon: Icons.person_rounded,
    iconColor: secondaryColor,
    ),
    ),
    const SizedBox(width: 16),
    Expanded(
    child: _buildMetricCard(
    title: 'Retention Rate',
    value: '85%',
    subtitle: 'last 30 days',
    icon: Icons.repeat_rounded,
    iconColor: accentColor,
    ),
    ),
    ],
    ),

    const SizedBox(height: 24),

    // Export data button
      // Continuing from where the previous file ended

      // Export data button
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export User Data',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download user data in CSV or Excel format for further analysis',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textDarkColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'CSV export will be available soon!',
                          style: GoogleFonts.poppins(color: textLightColor),
                        ),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.download_rounded, size: 18),
                  label: Text('CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryColor,
                    side: BorderSide(color: secondaryColor),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Excel export will be available soon!',
                          style: GoogleFonts.poppins(color: textLightColor),
                        ),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.description_rounded, size: 18),
                  label: Text('Excel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: successColor,
                    side: BorderSide(color: successColor),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF export will be available soon!',
                          style: GoogleFonts.poppins(color: textLightColor),
                        ),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text('PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  // =============== Component Builders ===============

  // Build statistics dashboard with modern UI
  Widget _buildStatisticsDashboard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, Color(0xFF0A1814)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'User Statistics',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textLightColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: textLightColor,
                  ),
                  onPressed: () {
                    // Show options menu
                  },
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  title: 'Total Users',
                  count: _totalUsers,
                  icon: Icons.people_alt_rounded,
                  color: secondaryColor,
                ),
                _buildStatCard(
                  title: 'Teachers',
                  count: _teacherCount,
                  icon: Icons.school_rounded,
                  color: accentColor,
                ),
                _buildStatCard(
                  title: 'Admins',
                  count: _adminCount,
                  icon: Icons.admin_panel_settings_rounded,
                  color: Color(0xFFAA6C39), // Bronze variation
                ),
                _buildStatCard(
                  title: 'Active',
                  count: _activeUsers,
                  icon: Icons.check_circle_rounded,
                  color: successColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a single stat card for the dashboard
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textLightColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textLightColor.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  // Build recently registered users list (with limit option)
  Widget _buildRecentUsersList({int? limit}) {
    final displayUsers = limit != null && recentlyRegisteredUsers.length > limit
        ? recentlyRegisteredUsers.sublist(0, limit)
        : recentlyRegisteredUsers;

    if (displayUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_alt_1_rounded,
        title: 'No recent registrations',
        subtitle: 'New users will appear here',
        compact: true,
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayUsers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = displayUsers[index];
            return _buildRecentUserTile(user);
          },
        ),

        // View all button if there are more users
        if (limit != null && recentlyRegisteredUsers.length > limit)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () {
                _tabController?.animateTo(2); // Navigate to Recently Added tab
              },
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: secondaryColor,
              ),
              label: Text(
                'View All Recent Users',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Build currently active users list
  Widget _buildActiveUsersList() {
    final activeUsers = users.where((user) => user.isLoggedIn ?? false).toList();

    if (activeUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_rounded,
        title: 'No active users',
        subtitle: 'Users will appear here when they log in',
        compact: true,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = activeUsers[index];
        return _buildUserTile(user, showActiveIndicator: true);
      },
    );
  }

  // Build registration trend chart
  Widget _buildRegistrationChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _userRegistrationData.values.isEmpty
              ? 10
              : (_userRegistrationData.values.reduce((a, b) => a > b ? a : b) * 1.2),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(

              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = _userRegistrationData.keys.elementAt(groupIndex);
                final value = _userRegistrationData.values.elementAt(groupIndex);
                return BarTooltipItem(
                  '$date: $value users',
                  GoogleFonts.poppins(
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  try {
                    String title = _userRegistrationData.keys.elementAt(value.toInt());
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: textDarkColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    );
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text(
                      '0',
                      style: GoogleFonts.poppins(
                        color: textDarkColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.left,
                    );
                  }
                  if (value % 1 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          color: textDarkColor.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(
            _userRegistrationData.length,
                (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _userRegistrationData.values.elementAt(index).toDouble(),
                  color: secondaryColor,
                  width: 20,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build role distribution cards
  Widget _buildRoleDistributionCards() {
    // Count users by role
    final Map<String, int> roleCounts = {};
    for (var user in users) {
      final role = user.role?.toLowerCase() ?? 'unknown';
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    // Define colors for each role
    final Map<String, Color> roleColors = {
      'admin': accentColor,
      'teacher': secondaryColor,
      'user': Color(0xFF327959), // Darker forest green
      'unknown': Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var entry in roleCounts.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: roleColors[entry.key] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.key.capitalize(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textDarkColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(entry.value / _totalUsers * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: roleColors[entry.key] ?? Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Build search and filter bar for All Users tab
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textDarkColor,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name, email, or role...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: textDarkColor.withOpacity(0.5),
              ),
              prefixIcon: Icon(Icons.search_rounded, color: secondaryColor),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 12),

          // Filter options
          Row(
            children: [
              // Role filter dropdown
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: secondaryColor),
                      iconSize: 24,
                      elevation: 16,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textDarkColor,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRoleFilter = newValue!;
                          _applyFilters();
                        });
                      },
                      items: <String>['All', 'Admin', 'Teacher', 'User']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'All' ? Icons.filter_list_rounded :
                                value == 'Admin' ? Icons.admin_panel_settings_rounded :
                                value == 'Teacher' ? Icons.school_rounded :
                                Icons.person_rounded,
                                color: secondaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sort options dropdown
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentSortOption,
                      isExpanded: true,
                      icon: Icon(
                          _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: secondaryColor
                      ),
                      iconSize: 20,
                      elevation: 16,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textDarkColor,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (String? newValue) {
                        setState(() {
                          if (_currentSortOption == newValue) {
                            // Toggle sort direction
                            _isAscending = !_isAscending;
                          } else {
                            _currentSortOption = newValue!;
                          }
                          _sortUsers();
                        });
                      },
                      items: <String>['Name', 'Email', 'Role', 'Registration Date', 'Last Active']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Name' ? Icons.sort_by_alpha_rounded :
                                value == 'Email' ? Icons.email_rounded :
                                value == 'Role' ? Icons.badge_rounded :
                                value == 'Registration Date' ? Icons.date_range_rounded :
                                Icons.schedule_rounded,
                                color: secondaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Active users toggle
              FilterChip(
                label: Text(
                  'Active Only',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _onlyShowActiveUsers ? textLightColor : textDarkColor,
                  ),
                ),
                selected: _onlyShowActiveUsers,
                checkmarkColor: textLightColor,
                selectedColor: successColor,
                backgroundColor: surfaceColor,
                onSelected: (bool selected) {
                  setState(() {
                    _onlyShowActiveUsers = selected;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Text(
                  'Showing ${filteredUsers.length} of $_totalUsers users',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textDarkColor.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || _selectedRoleFilter != 'All' || _onlyShowActiveUsers)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedRoleFilter = 'All';
                        _onlyShowActiveUsers = false;
                        _applyFilters();
                      });
                    },
                    icon: Icon(Icons.clear_rounded, size: 16),
                    label: Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: accentColor,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: compact ? 8.0 : 24.0,
          horizontal: 16.0
      ),
      padding: EdgeInsets.all(compact ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 32 : 48,
              color: secondaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: compact ? 12 : 14,
              color: textDarkColor.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (!compact) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _showUserDialog();
              },
              icon: Icon(Icons.add, size: 18),
              label: Text('Add User'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build user tile with animations and modern design
  Widget _buildUserTile(CustomUser user, {bool showActiveIndicator = false}) {
    final bool isLoggedIn = user.isLoggedIn ?? false;
    final bool isTeacher = user.role?.toLowerCase() == 'teacher';
    final bool isAdmin = user.role?.toLowerCase() == 'admin';

    // Create indicator color based on role
    Color roleColor = Color(0xFF327959); // For regular users
    if (isTeacher) {
      roleColor = secondaryColor;
    } else if (isAdmin) {
      roleColor = accentColor;
    }

    // Continuing from the previous part

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to user details screen
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return UserDetailsScreen(user: user);
                  },
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            splashColor: secondaryColor.withOpacity(0.1),
            highlightColor: secondaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status indicator dot for logged-in users
                  if (showActiveIndicator && isLoggedIn)
                    Container(
                      width: 8,
                      height: 56,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: successColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                  // Profile image with online indicator
                  Stack(
                    children: [
                      Hero(
                        tag: 'user-avatar-${user.email}',
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: surfaceColor,
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? Icon(Icons.person_rounded, size: 28, color: primaryColor)
                              : null,
                        ),
                      ),
                      if (isLoggedIn && !showActiveIndicator)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: successColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'No Name',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No Email',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textDarkColor.withOpacity(0.7),
                          ),
                        ),
                        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              user.phoneNumber!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textDarkColor.withOpacity(0.5),
                              ),
                            ),
                          ),
                        if (user.role != null && user.role!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: roleColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              user.role!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: roleColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Last active indicator
                  if (user.lastActiveTime != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Last seen',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: textDarkColor.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            timeago.format(user.lastActiveTime!),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_rounded, size: 20, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'View Details',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 20, color: accentColor),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 20, color: dangerColor),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailsScreen(user: user),
                            ),
                          );
                          break;
                        case 'edit':
                          _editUser(context, user);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, user);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build recent user tile with timestamp
  Widget _buildRecentUserTile(CustomUser user) {
    final bool isTeacher = user.role?.toLowerCase() == 'teacher';
    final bool isAdmin = user.role?.toLowerCase() == 'admin';

    // Create indicator color based on role
    Color roleColor = Color(0xFF327959); // For regular users
    if (isTeacher) {
      roleColor = secondaryColor;
    } else if (isAdmin) {
      roleColor = accentColor;
    }

    // Format registration date
    String registrationDate = 'Unknown';
    if (user.registrationDate != null) {
      registrationDate = timeago.format(user.registrationDate!);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailsScreen(user: user),
                ),
              );
            },
            splashColor: secondaryColor.withOpacity(0.1),
            highlightColor: secondaryColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: secondaryColor,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: surfaceColor,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Icon(Icons.person_rounded, size: 26, color: primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'No Name',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No Email',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textDarkColor.withOpacity(0.7),
                          ),
                        ),
                        Row(
                          children: [
                            if (user.role != null && user.role!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: roleColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  user.role!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: roleColor,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: successColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'New',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Registration date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Registered',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: textDarkColor.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        registrationDate,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: secondaryColor,
                              size: 20,
                            ),
                            onPressed: () => _editUser(context, user),
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                            onPressed: () => _showDeleteConfirmation(context, user),
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build analytics charts
  Widget _buildUserGrowthChart() {
    // Mock data - would be replaced with actual user growth data
    final List<Map<String, dynamic>> growthData = [
      {'month': 'Jan', 'users': 120},
      {'month': 'Feb', 'users': 150},
      {'month': 'Mar', 'users': 180},
      {'month': 'Apr', 'users': 220},
      {'month': 'May', 'users': 280},
      {'month': 'Jun', 'users': 310},
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < growthData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      growthData[index]['month'],
                      style: GoogleFonts.poppins(
                        color: textDarkColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value % 50 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      value.toInt().toString(),
                      style: GoogleFonts.poppins(
                        color: textDarkColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: growthData.length - 1.0,
        minY: 0,
        maxY: 400,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              growthData.length,
                  (index) => FlSpot(
                index.toDouble(),
                growthData[index]['users'].toDouble(),
              ),
            ),
            isCurved: true,
            color: secondaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: secondaryColor.withOpacity(0.3),
              gradient: LinearGradient(
                colors: [
                  secondaryColor.withOpacity(0.3),
                  secondaryColor.withOpacity(0.0),
                ],
                stops: [0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(

              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  final month = growthData[index]['month'];
                  final users = growthData[index]['users'];

                  return LineTooltipItem(
                    '$month: $users users',
                    GoogleFonts.poppins(
                      color: textLightColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              }
          ),
        ),
      ),
    );
  }


  Widget _buildRoleDistributionChart() {
    // Count users by role
    final Map<String, int> roleCounts = {};
    for (var user in users) {
      final role = user.role?.toLowerCase() ?? 'unknown';
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    // Define colors for each role
    final Map<String, Color> roleColors = {
      'admin': accentColor,
      'teacher': secondaryColor,
      'user': Color(0xFF327959), // Darker forest green
      'unknown': Colors.grey,
    };

    // Prepare pie chart sections
    List<PieChartSectionData> sections = [];
    roleCounts.forEach((role, count) {
      final percentage = count / _totalUsers * 100;
      sections.add(
        PieChartSectionData(
          color: roleColors[role] ?? Colors.grey,
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textLightColor,
          ),
        ),
      );
    });

    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),

        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: roleCounts.entries.map((entry) {
              final role = entry.key;
              final count = entry.value;
              final percentage = count / _totalUsers * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: roleColors[role] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role.capitalize(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textDarkColor,
                            ),
                          ),
                          Text(
                            '$count users (${percentage.toStringAsFixed(1)}%)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textDarkColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Build metric card for analytics
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textDarkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textDarkColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context, CustomUser user) async {
    final bool result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: surfaceColor,
        title: Column(
          children: [
            Icon(
              Icons.warning_rounded,
              color: accentColor,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${user.name ?? 'this user'}? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: textLightColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.delete_rounded, size: 18),
            label: Text(
              'DELETE',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (result && user.email != null) {
      _deleteUser(user.email!);
    }
  }

  // Show user dialog for adding/editing
  Future<CustomUser?> _showUserDialog({CustomUser? user}) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Controllers
    final TextEditingController nameController =
    TextEditingController(text: user?.name ?? '');
    final TextEditingController emailController =
    TextEditingController(text: user?.email ?? '');
    final TextEditingController roleController =
    TextEditingController(text: user?.role ?? '');
    final TextEditingController phoneNumberController =
    TextEditingController(text: user?.phoneNumber ?? '');
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    // Local variables
    File? newProfileImage;
    bool isUploadingImage = false;

    // We can still show a placeholder image or the user's current image
    String? previewImageUrl = user?.profileImageUrl ?? 'https://via.placeholder.com/150';

    // Key for form validation
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    // Predefined role options
    final List<String> roleOptions = ['User', 'Teacher', 'Admin', 'Other'];
    String selectedRole = user?.role ?? 'User';

    return showDialog<CustomUser>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) { // Use separate context for dialog
      return StatefulBuilder(
          builder: (context, setState) {
        // --- Helper: Pick an image locally (no Firebase upload here) ---
        Future<void> pickImage() async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked == null) return;
          setState(() => isUploadingImage = true);

          try {
            newProfileImage = File(picked.path);
            // Update the preview to show the newly picked local image
            previewImageUrl = null;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error picking image: $e',
                  style: GoogleFonts.poppins(color: textLightColor),
                ),
                backgroundColor: dangerColor,
              ),
            );
          } finally {
            setState(() => isUploadingImage = false);
          }
        }

        return AlertDialog(
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
    ),
    backgroundColor: surfaceColor,
    title: Column(
    children: [
    Icon(
    user == null ? Icons.person_add_rounded : Icons.person_rounded,
    color: secondaryColor,
    size: 40,
    ),
    SizedBox(height: 16),
    Text(
    user == null ? 'Add New User' : 'Edit User',
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    ),
    ),
    ],
    ),
    content: SingleChildScrollView(
    child: Form(
    key: _formKey,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    // Avatar & Change Image Button
    Stack(
    alignment: Alignment.center,
    children: [
      // Continuing from the previous part

      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: secondaryColor,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: surfaceColor,
          backgroundImage: previewImageUrl != null
              ? NetworkImage(previewImageUrl!)
              : (newProfileImage != null
              ? FileImage(newProfileImage!) as ImageProvider
              : null),
          child: (previewImageUrl == null && newProfileImage == null)
              ? Icon(Icons.person_rounded, size: 48, color: secondaryColor)
              : null,
        ),
      ),
      if (isUploadingImage)
        Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(textLightColor),
          ),
        ),
    ],
    ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: isUploadingImage ? null : pickImage,
        icon: Icon(
          Icons.camera_alt_rounded,
          size: 18,
        ),
        label: Text(
          'Change Profile Image',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      const Divider(height: 32),

      // Form Fields
      _buildFormField(
        controller: nameController,
        label: 'Full Name',
        icon: Icons.person_rounded,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      _buildFormField(
        controller: emailController,
        label: 'Email Address',
        icon: Icons.email_rounded,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an email';
          }
          // Basic email validation
          if (!value.contains('@') || !value.contains('.')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Role dropdown
      DropdownButtonFormField<String>(
        value: selectedRole,
        decoration: InputDecoration(
          labelText: 'Role',
          labelStyle: GoogleFonts.poppins(
            color: secondaryColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.badge_rounded, color: secondaryColor, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: secondaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: surfaceColor,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        items: roleOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textDarkColor,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedRole = newValue;
              roleController.text = newValue;
            });
          }
        },
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: textDarkColor,
        ),
      ),
      const SizedBox(height: 16),

      _buildFormField(
        controller: phoneNumberController,
        label: 'Phone Number',
        icon: Icons.phone_rounded,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),

      _buildFormField(
        controller: passwordController,
        label: 'Password',
        icon: Icons.lock_rounded,
        obscureText: true,
        validator: (value) {
          if (user == null && (value == null || value.isEmpty)) {
            return 'Please enter a password';
          }
          if (value != null && value.isNotEmpty && value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      _buildFormField(
        controller: confirmPasswordController,
        label: 'Confirm Password',
        icon: Icons.lock_rounded,
        obscureText: true,
        validator: (value) {
          if (passwordController.text.isNotEmpty &&
              value != passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    ],
    ),
    ),
    ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), // Use dialogContext
              child: Text(
                'CANCEL',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ),

            // Save Button
            ElevatedButton(
              onPressed: () async {
                // Validate form
                if (_formKey.currentState!.validate()) {
                  // Basic password check
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Passwords do not match',
                          style: GoogleFonts.poppins(color: textLightColor),
                        ),
                        backgroundColor: dangerColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return; // Exit without doing anything
                  }

                  try {
                    // Close dialog first to avoid UI issues
                    Navigator.of(dialogContext).pop(); // Use dialogContext

                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: surfaceColor,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                user == null ? 'Creating user...' : 'Updating user...',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
                    );

                    DateTime now = DateTime.now();
                    CustomUser resultUser;

                    if (user == null) {
                      // Create a NEW user via AuthService
                      await authService.addUser(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        role: selectedRole,
                        phoneNumber: phoneNumberController.text.trim().isEmpty
                            ? null
                            : phoneNumberController.text.trim(),
                        profileImage: newProfileImage,
                      );

                      // Create a result user object
                      resultUser = CustomUser(
                        id: 'new-user-id', // This will be replaced by Firestore
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        role: selectedRole,
                        phoneNumber: phoneNumberController.text.trim().isEmpty
                            ? null
                            : phoneNumberController.text.trim(),
                        profileImageUrl: newProfileImage != null
                            ? 'pending-upload' // Placeholder until image is uploaded
                            : 'https://via.placeholder.com/150',
                        isLoggedIn: false,
                        registrationDate: now, // Use the correct field name
                        lastActiveTime: now,
                      );
                    } else {
                      // UPDATE existing user's Firestore data by Email
                      await authService.updateUserByEmail(
                        email: user.email ?? '', // old email
                        updatedData: {
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'role': selectedRole,
                          'phoneNumber': phoneNumberController.text.trim(),
                          'lastActiveTime': FieldValue.serverTimestamp(),
                        },
                      );

                      // If we picked a new image, call updateUser to upload & override
                      if (newProfileImage != null) {
                        await authService.updateUser(
                          updatedData: {},
                          newProfileImage: newProfileImage,
                        );
                      }

                      // Create updated user object
                      resultUser = CustomUser(
                        id: user.id,
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        role: selectedRole,
                        phoneNumber: phoneNumberController.text.trim(),
                        profileImageUrl: newProfileImage != null
                            ? 'pending-upload' // Placeholder
                            : user.profileImageUrl,
                        isLoggedIn: user.isLoggedIn,
                        registrationDate: user.registrationDate, // Use the correct field name
                        lastActiveTime: now,
                      );
                    }

                    // Close loading dialog
                    Navigator.of(context).pop();

                    // Return the result user through the Future from showDialog
                    // No need to explicitly return here - the Navigator.pop() above
                    // already returned the resultUser to the caller

                    // Create a new dialog to show success and return the user
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: surfaceColor,
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: successColor,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user == null ? 'User Created Successfully!' : 'User Updated Successfully!',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(resultUser); // Return the user to original caller
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: successColor,
                                foregroundColor: textLightColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'OK',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                  } catch (e) {
                    // Close loading dialog if it's open
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: $e',
                          style: GoogleFonts.poppins(color: textLightColor),
                        ),
                        backgroundColor: dangerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );

                    // Return null to the _showUserDialog caller
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: textLightColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
          },
      );
        },
    );
  }

  // Helper method to build form fields with consistent styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: textDarkColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: secondaryColor,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: secondaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      validator: validator,
    );
  }
}

// Extension method to capitalize a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
