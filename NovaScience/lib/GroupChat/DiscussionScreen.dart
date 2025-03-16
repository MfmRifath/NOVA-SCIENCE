import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Screens/StartScreen/AppTheme.dart';
import 'GroupListScreen.dart';
import 'GroupChatScreen.dart'; // Import the GroupChatScreen

class DiscussionScreen extends StatefulWidget {
  @override
  _DiscussionScreenState createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAdmin = false;
  bool _isLoading = true;
  late Stream<QuerySnapshot> _groupsStream;
  int _selectedCategoryIndex = 0;
  bool _showFab = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  // Main categories
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Science Stream',
      'icon': Icons.science,
      'color': Color(0xFF4CAF50),
      'description': 'Physics, Chemistry, Biology and more',
      'background': 'assets/images/science_bg.jpg',
      'gradient': [Color(0xFF2E7D32), Color(0xFF81C784)],
    },
    {
      'name': 'Arts Stream',
      'icon': Icons.color_lens,
      'color': Color(0xFFE91E63),
      'description': 'Literature, History, Geography and more',
      'background': 'assets/images/arts_bg.jpg',
      'gradient': [Color(0xFFC2185B), Color(0xFFF48FB1)],
    },
    {
      'name': 'Commerce Stream',
      'icon': Icons.attach_money,
      'color': Color(0xFF2196F3),
      'description': 'Business, Economics, Accounting and more',
      'background': 'assets/images/commerce_bg.jpg',
      'gradient': [Color(0xFF1565C0), Color(0xFF64B5F6)],
    },
    {
      'name': 'Technology Stream',
      'icon': Icons.computer,
      'color': Color(0xFF673AB7),
      'description': 'Programming, Engineering, Design and more',
      'background': 'assets/images/tech_bg.jpg',
      'gradient': [Color(0xFF4527A0), Color(0xFFB39DDB)],
    },
    {
      'name': 'O/L',
      'icon': Icons.menu_book,
      'color': Color(0xFFFF9800),
      'description': 'General education and foundation subjects',
      'background': 'assets/images/general_bg.jpg',
      'gradient': [Color(0xFFEF6C00), Color(0xFFFFCC80)],
    },
  ];

  // Recent activity data
  List<Map<String, dynamic>> _recentGroups = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkUserRole();
    _setupGroupsStream();
    _fetchRecentGroups();
    _setupScrollListener();

    // Status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Show/hide FAB based on scroll direction
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFab) {
          setState(() {
            _showFab = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFab) {
          setState(() {
            _showFab = true;
          });
        }
      }

      // Handle pull to refresh
      if (_scrollController.position.pixels <= -100 && !_isRefreshing) {
        _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        _fetchRecentGroups(),
        Future.delayed(Duration(milliseconds: 1500)), // Min loading time for better UX
      ]);

      // Setup streams again
      _setupGroupsStream();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content refreshed'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error refreshing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _setupGroupsStream() {
    _groupsStream = FirebaseFirestore.instance
        .collection('discussion_groups')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<void> _fetchRecentGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('discussion_groups')
          .where('members', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _recentGroups = snapshot.docs
              .map((doc) => {
            'id': doc.id,
            'name': doc['name'],
            'category': doc['category'],
            'lastMessage': doc['lastMessage'] ?? 'No messages yet',
            'lastMessageTime': doc['lastMessageTime'],
            'groupImageUrl': doc['groupImageUrl'],
          })
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching recent groups: $e');
    }
  }

  Future<void> _checkUserRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _isAdmin = userDoc.data()?['role'] == 'Admin';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Start animation after loading
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildContent(),
          if (_isRefreshing)
            Positioned(
              top: 120, // Below app bar
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Refreshing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showFab && _isAdmin ? _buildFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: _buildSearchBar(),
        ),
        SliverToBoxAdapter(
          child: _buildCategorySlider(),
        ),
        SliverToBoxAdapter(
          child: _buildSelectedCategoryHeader(),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: _buildGroupsList(),
        ),
        SliverToBoxAdapter(
          child: _buildRecentlyJoinedHeader(),
        ),
        SliverToBoxAdapter(
          child: _buildRecentlyJoinedGroups(),
        ),
        SliverToBoxAdapter(
          child: _buildRecentActivityHeader(),
        ),
        _buildRecentActivity(),
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          'Discussion Groups',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(100, 0, 0, 0),
              ),
            ],
          ),
        ),
        stretchModes: [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                ),
              ),
            ),
            // Pattern overlay
            Opacity(
              opacity: 0.2,
              child: Image.network(
                'https://transparenttextures.com/patterns/cubes.png',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: [0.7, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect, Share, Learn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 40), // Space for the title
                ],
              ),
            ),
            // Pull to refresh indicator hint when pulled down
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  opacity: _scrollController.hasClients && _scrollController.position.pixels < -50 ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Text(
                    'Pull to refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // Show notifications
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notifications coming soon'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
        ),
        if (_isAdmin)
          IconButton(
            icon: Icon(Icons.dashboard_customize_outlined, color: Colors.white),
            onPressed: () {
              // Show admin dashboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Admin dashboard coming soon'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.1, 0.4, curve: Curves.easeOut),
              ),
            ),
            child: child,
          );
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search discussions...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
            onTap: () {
              // Show search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Search functionality coming soon'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySlider() {
    return Container(
      height: 150,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.2, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.3, 0.5, curve: Curves.easeOut),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.3, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(index);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(int index) {
    final category = _categories[index];
    final isSelected = index == _selectedCategoryIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        width: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: category['color'].withOpacity(0.4),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isSelected
                    ? category['color']
                    : category['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: category['gradient'],
                )
                    : null,
              ),
              child: Icon(
                category['icon'],
                color: isSelected ? Colors.white : category['color'],
                size: 32,
              ),
            ),
            SizedBox(height: 8),
            Text(
              category['name'].split(' ')[0],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCategoryHeader() {
    final selectedCategory = _categories[_selectedCategoryIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selectedCategory['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  selectedCategory['icon'],
                  color: selectedCategory['color'],
                  size: 12,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '${selectedCategory['name']} Groups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              _navigateToGroupList(selectedCategory['name']);
            },
            child: Text(
              'View All',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('discussion_groups')
          .where('category', isEqualTo: _categories[_selectedCategoryIndex]['name'])
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildErrorState('Failed to load groups'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: _buildGroupsLoadingState(),
          );
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              'No groups in this category',
              'Be the first to create a group in this category!',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double startValue = 0.4 + (index * 0.05);

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          startValue,
                          startValue + 0.1,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            startValue,
                            startValue + 0.1,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: _buildGroupCard(doc.id, data),
              );
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(String groupId, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final isUserMember = (data['members'] as List?)?.contains(user?.uid) ?? false;
    final groupImage = data['groupImageUrl'];
    final String memberCount = data['memberCount']?.toString() ?? '0';
    final String description = data['description'] ?? 'No description available';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isUserMember) {
            _navigateToGroupChat(groupId, data['name'], groupImage);
          } else {
            _showJoinGroupDialog(groupId, data['name']);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header with image
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: _getColorForString(data['name']).withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    if (groupImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: groupImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: _getColorForString(data['name']).withOpacity(0.2),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: _getColorForString(data['name']).withOpacity(0.2),
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getColorForString(data['name']).withOpacity(0.4),
                              _getColorForString(data['name']).withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.groups,
                            color: _getColorForString(data['name']),
                            size: 40,
                          ),
                        ),
                      ),

                    // Gradient overlay for better visibility
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),

                    // Group name and details
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unnamed Group',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2.0,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '$memberCount members',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Status chip
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isUserMember
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              isUserMember ? 'Joined' : 'Join',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Group description
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _getColorForString(data['creatorName'] ?? '').withOpacity(0.2),
                          child: Text(
                            (data['creatorName'] ?? 'A')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getColorForString(data['creatorName'] ?? ''),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Created by ${data['creatorName'] ?? 'Anonymous'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiaryColor,
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

  Color _getColorForString(String input) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  Widget _buildRecentlyJoinedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Groups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune, color: AppTheme.primaryColor),
            onPressed: () {
              // Filter functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filter functionality coming soon'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyJoinedGroups() {
    if (_recentGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildEmptyState(
          "You haven't joined any groups yet",
          "Join a group to start discussing with others",
        ),
      );
    }

    return Container(
      height: 140,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _recentGroups.length,
        itemBuilder: (context, index) {
          final group = _recentGroups[index];
          return _buildRecentGroupCard(group);
        },
      ),
    );
  }

  Widget _buildRecentGroupCard(Map<String, dynamic> group) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(0.6, 0.8, curve: Curves.easeOut),
            ),
          ),
          child: child,
        );
      },
      child: Container(
        width: 120,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToGroupChat(
              group['id'],
              group['name'],
              group['groupImageUrl'],
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Group image or placeholder
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: _getColorForString(group['name']).withOpacity(0.2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (group['groupImageUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: group['groupImageUrl'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: _getColorForString(group['name']).withOpacity(0.2),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: _getColorForString(group['name']).withOpacity(0.2),
                            child: Icon(
                              Icons.groups,
                              color: _getColorForString(group['name']),
                              size: 30,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.groups,
                        color: _getColorForString(group['name']),
                        size: 30,
                      ),

                    // Category tag
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getCategoryShortName(group['category']),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Group name
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      group['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryShortName(String categoryName) {
    final parts = categoryName.split(' ');
    if (parts.length > 1) {
      return parts[0].substring(0, 1) + parts[1].substring(0, 1);
    }
    return categoryName.substring(0, min(2, categoryName.length));
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildRecentActivityHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        'Recent Activity',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildErrorState('Could not load recent activity'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildGroupsLoadingState(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildEmptyState(
                'No recent activity',
                'Groups will appear here once they become active',
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['createdAt'] as Timestamp?;

              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double startValue = 0.7 + (index * 0.05);

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          startValue,
                          startValue + 0.1,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            startValue,
                            startValue + 0.1,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _navigateToGroupChat(
                          doc.id,
                          data['name'],
                          data['groupImageUrl'],
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Group avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _getColorForString(data['name']).withOpacity(0.1),
                              ),
                              child: data['groupImageUrl'] != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: data['groupImageUrl'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: Text(
                                      data['name'][0].toUpperCase(),
                                      style: TextStyle(
                                        color: _getColorForString(data['name']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Center(
                                    child: Text(
                                      data['name'][0].toUpperCase(),
                                      style: TextStyle(
                                        color: _getColorForString(data['name']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  : Center(
                                child: Text(
                                  data['name'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: _getColorForString(data['name']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),

                            // Group info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        data['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(data['category']).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          data['category'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getCategoryColor(data['category']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        timestamp == null ? Icons.add : Icons.update,
                                        size: 12,
                                        color: AppTheme.textTertiaryColor,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        timestamp == null
                                            ? 'New group created'
                                            : 'Created ${_timeAgo(timestamp.toDate())}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textTertiaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Join/chat button with fixed animation
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _navigateToGroupChat(
                                    doc.id,
                                    data['name'],
                                    data['groupImageUrl'],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: snapshot.data!.docs.length,
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getCategoryColor(String category) {
    for (var cat in _categories) {
      if (cat['name'] == category) {
        return cat['color'];
      }
    }
    return Colors.grey;
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _setupGroupsStream();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsLoadingState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading groups...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showCreateGroupDialog();
      },
      backgroundColor: AppTheme.tertiaryColor,
      icon: Icon(Icons.add),
      label: Text('Create Group'),
      elevation: 4,
    );
  }

  void _navigateToGroupList(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupListScreen(category: category),
      ),
    );
  }

  // FIXED: Properly navigate to GroupChatScreen
  void _navigateToGroupChat(String groupId, String groupName, dynamic groupAvatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          groupId: groupId,
          groupName: groupName,
          groupAvatar: groupAvatar,
        ),
      ),
    );
  }

  void _showJoinGroupDialog(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.group_add, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(child: Text('Join Group')),
            ],
          ),
          content: Text('Would you like to join the "$groupName" group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinGroup(groupId, groupName);
              },
              child: Text('Join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinGroup(String groupId, String groupName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get a reference to the group document
      DocumentReference groupRef = FirebaseFirestore.instance.collection('discussion_groups').doc(groupId);

      // Update the group document atomically
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);
        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> members = List.from(groupData['members'] ?? []);

        // Check if user is already a member
        if (!members.contains(user.uid)) {
          members.add(user.uid);

          transaction.update(groupRef, {
            'members': members,
            'memberCount': members.length,
          });
        }
      });

      // Refresh recent groups
      _fetchRecentGroups();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have joined the "$groupName" group!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate to the group chat
      _navigateToGroupChat(groupId, groupName, null);
    } catch (e) {
      print('Error joining group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join group. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedCategory = _categories[_selectedCategoryIndex]['name'];
        String groupName = '';
        String groupDescription = '';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.group_add, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Create New Group'),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Category:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['name'],
                            child: Row(
                              children: [
                                Icon(category['icon'], color: category['color'], size: 16),
                                SizedBox(width: 8),
                                Text(category['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Group Name:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter group name',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        groupName = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Group Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter group description',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        groupDescription = value;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
                  _createNewGroup(selectedCategory, groupName, groupDescription);
                  Navigator.of(context).pop();
                } else {
                  // Show validation error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewGroup(String category, String name, String description) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Generate search keywords for the group name
      List<String> searchKeywords = [];
      String nameLower = name.toLowerCase();
      for (int i = 1; i <= nameLower.length; i++) {
        searchKeywords.add(nameLower.substring(0, i));
      }

      final docRef = await FirebaseFirestore.instance.collection('discussion_groups').add({
        'name': name,
        'description': description,
        'category': category,
        'createdBy': user.uid,
        'creatorName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'members': [user.uid],
        'admins': [user.uid],
        'nameSearch': searchKeywords,
      });

      // Refresh recent groups
      _fetchRecentGroups();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate to the newly created group
      _navigateToGroupChat(docRef.id, name, null);
    } catch (e) {
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or brand icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Discussion Hub',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Connect, share and learn together',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tertiaryColor),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading discussions...',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}