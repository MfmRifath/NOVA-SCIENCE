import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

import 'NovaDesignSystem.dart';
import 'PDFViewerScreen.dart';
import 'ResourceUtils.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  ResourceDetailScreen({required this.resourceId});

  @override
  _ResourceDetailScreenState createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> with TickerProviderStateMixin {
  // Design colors
  final Color primaryColor = NovaDesignSystem.primaryColor;
  final Color secondaryColor = NovaDesignSystem.secondaryColor;
  final Color accentColor = NovaDesignSystem.accentColor;
  final Color tertiaryColor = NovaDesignSystem.tertiaryColor;
  final Color backgroundColor = Color(0xFFF8F9FC); // Lighter background for better contrast

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // State variables
  bool isLoading = true;
  bool isError = false;
  Map<String, dynamic>? resourceData;
  bool isAdmin = false;
  int downloadCount = 0;
  bool isDownloading = false;
  bool isFavorite = false;

  // Tab controller for content sections
  late TabController _tabController;
  final List<String> _tabs = ['Overview', 'Content', 'Related'];

  // Scroll controller for handling scroll behaviors
  late ScrollController _scrollController;
  bool isScrolled = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    // Initialize tab controller
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Initialize scroll controller and add listener
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Load data
    _loadResource();
    _checkUserRole();
    _checkIfFavorite();

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
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
    _fadeController.dispose();
    _scaleController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadResource() async {
    try {
      final resourceDoc = await FirebaseFirestore.instance
          .collection('resources')
          .doc(widget.resourceId)
          .get();

      if (resourceDoc.exists) {
        setState(() {
          resourceData = resourceDoc.data() as Map<String, dynamic>;
          isLoading = false;
          downloadCount = resourceData?['viewCount'] ?? 0;
        });

        // Increment view count
        await FirebaseFirestore.instance
            .collection('resources')
            .doc(widget.resourceId)
            .update({
          'viewCount': FieldValue.increment(1),
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      print('Error loading resource: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
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
          isAdmin = userDoc.data()?['role'] == 'Admin';
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoriteDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.resourceId)
            .get();

        setState(() {
          isFavorite = favoriteDoc.exists;
        });
      }
    } catch (e) {
      print('Error checking favorites: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final favoritesRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.resourceId);

        setState(() {
          isFavorite = !isFavorite;
        });

        if (isFavorite) {
          // Add to favorites
          await favoritesRef.set({
            'addedAt': FieldValue.serverTimestamp(),
            'resourceId': widget.resourceId,
            'title': resourceData!['title'],
            'category': resourceData!['category'],
            'stream': resourceData!['stream'],
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 2),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to favorites screen
                },
              ),
            ),
          );
        } else {
          // Remove from favorites
          await favoritesRef.delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: Colors.grey.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      // Revert state if error
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (isError || resourceData == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: _buildTabBar(),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview tab
                _buildOverviewTab(),

                // Content details tab
                _buildContentTab(),

                // Related resources tab
                _buildRelatedResourcesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: isScrolled ? primaryColor : Colors.transparent,
      elevation: isScrolled ? 4 : 0,
      title: AnimatedOpacity(
        opacity: isScrolled ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: Text(
          resourceData!['title'] ?? 'Resource Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isScrolled ? Colors.transparent : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: isScrolled ? Colors.white : Colors.white,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isScrolled ? Colors.transparent : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.red : (isScrolled ? Colors.white : Colors.white),
              size: 20,
            ),
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isScrolled ? Colors.transparent : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share_rounded,
              color: isScrolled ? Colors.white : Colors.white,
              size: 20,
            ),
          ),
          onPressed: _shareResource,
        ),
        if (isAdmin || _isResourceOwner())
          PopupMenuButton<String>(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isScrolled ? Colors.transparent : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: isScrolled ? Colors.white : Colors.white,
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            onSelected: (value) {
              if (value == 'edit') {
                _navigateToEditScreen();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder: (context) => [

              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Delete Resource',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    bool isPdf = resourceData != null &&
        resourceData!['fileName'] != null &&
        resourceData!['fileName'].toString().toLowerCase().endsWith('.pdf');

    return AnimatedOpacity(
      opacity: isScrolled ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            if (isPdf) {
              _previewPdf(resourceData!['fileUrl']);
            } else {
              _launchUrl(resourceData!['fileUrl']);
            }
          },
          backgroundColor: tertiaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          label: Text(
            isPdf ? 'View PDF' : 'Download',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(isPdf ? Icons.visibility_rounded : Icons.download_rounded),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderContent(),
      ),
    );
  }

  Widget _buildHeaderContent() {
    // Get category/subcategory information
    IconData headerIcon = _getResourceIcon();
    Color headerColor = _getResourceColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Resource icon
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Hero(
                  tag: 'resource-icon-${widget.resourceId}',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      headerIcon,
                      size: 45,
                      color: headerColor,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Resource title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  resourceData!['title'] ?? 'Untitled Resource',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            SizedBox(height: 12),

            // Category and stream badges
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      resourceData!['category'] ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(width: 5),

                  // Stream badge
                  if (resourceData!['stream'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStreamColor().withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        resourceData!['stream'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Subcategory badge (for Exam Papers)
                  if (resourceData!['category'] == 'Exam Papers' &&
                      resourceData!['subcategory'] != null) ...[
                    SizedBox(width: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ResourceUtils.getSubcategoryColor(resourceData!['subcategory']).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        resourceData!['subcategory'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
            blurRadius: 10,
            offset: Offset(0, 4),
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
        indicatorColor: tertiaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick action buttons
          _buildQuickActionButtons(),

          SizedBox(height: 24),

          // Statistics card
          _buildStatisticsCard(),

          SizedBox(height: 20),

          // Resource information card
          _buildResourceInfoCard(),

          SizedBox(height: 20),

          // Description card (if available)
          if (resourceData!['description'] != null &&
              resourceData!['description'].toString().isNotEmpty)
            _buildDescriptionCard(),

          SizedBox(height: 80), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    bool isPdf = resourceData != null &&
        resourceData!['fileName'] != null &&
        resourceData!['fileName'].toString().toLowerCase().endsWith('.pdf');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Download button
          _buildQuickActionButton(
            icon: Icons.download_rounded,
            label: 'Download',
            color: tertiaryColor,
            onTap: () => _launchUrl(resourceData!['fileUrl']),
          ),

          // Preview button (for PDFs)
          if (isPdf)
            _buildQuickActionButton(
              icon: Icons.visibility_rounded,
              label: 'Preview',
              color: secondaryColor,
              onTap: () => _previewPdf(resourceData!['fileUrl']),
            ),

          // Share button
          _buildQuickActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: accentColor,
            onTap: _shareResource,
          ),

          // Favorite button
          _buildQuickActionButton(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: isFavorite ? 'Saved' : 'Save',
            color: isFavorite ? Colors.red : Colors.grey.shade700,
            onTap: _toggleFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Views stat
          _buildStatItem(
            icon: Icons.visibility_rounded,
            value: downloadCount.toString(),
            label: 'Views',
            color: tertiaryColor,
          ),

          // Upload date stat
          _buildStatItem(
            icon: Icons.calendar_today_rounded,
            value: _formatDate(resourceData!['uploadDate']),
            label: 'Uploaded',
            color: secondaryColor,
          ),

          // File size stat
          _buildStatItem(
            icon: Icons.data_usage_rounded,
            value: resourceData!['fileSize'] != null ?
            ResourceUtils.formatFileSize(resourceData!['fileSize']) :
            'Unknown',
            label: 'Size',
            color: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Resource Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Information items
          _buildInfoItem(
            icon: Icons.person_rounded,
            label: 'Uploaded by',
            value: resourceData!['uploadedBy'] ?? 'Unknown',
          ),

          SizedBox(height: 16),

          _buildInfoItem(
            icon: Icons.insert_drive_file_rounded,
            label: 'File Name',
            value: resourceData!['fileName'] ?? 'Unknown file',
          ),

          // Show subcategory for Exam Papers
          if (resourceData!['category'] == 'Exam Papers' &&
              resourceData!['subcategory'] != null) ...[
            SizedBox(height: 16),
            _buildInfoItem(
              icon: ResourceUtils.subcategoryIcons[resourceData!['subcategory']] ?? Icons.label_rounded,
              label: 'Exam Paper Type',
              value: resourceData!['subcategory'],
            ),
          ],

          SizedBox(height: 16),

          _buildInfoItem(
            icon: Icons.school_rounded,
            label: 'Academic Stream',
            value: resourceData!['stream'] ?? 'Not specified',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: secondaryColor,
              size: 18,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.description_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Description content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              resourceData!['description'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    bool isPdf = resourceData != null &&
        resourceData!['fileName'] != null &&
        resourceData!['fileName'].toString().toLowerCase().endsWith('.pdf');

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File preview area
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: isPdf
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red.shade400,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'PDF Document',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to preview',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getFileTypeIcon(),
                          color: _getFileTypeColor(),
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _getFileTypeLabel(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to download',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resourceData!['fileName'] ?? 'Unknown file',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4),

                      Text(
                        resourceData!['fileSize'] != null
                            ? 'Size: ${ResourceUtils.formatFileSize(resourceData!['fileSize'])}'
                            : 'Size unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          if (isPdf) ...[
                            // Preview button
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.visibility_rounded,
                                label: 'Preview',
                                color: secondaryColor,
                                onTap: () => _previewPdf(resourceData!['fileUrl']),
                              ),
                            ),

                            SizedBox(width: 12),
                          ],

                          // Download button
                          Expanded(
                            child: _buildActionButton(
                              icon: isDownloading ? null : Icons.download_rounded,
                              label: isDownloading ? 'Downloading...' : 'Download',
                              color: tertiaryColor,
                              isLoading: isDownloading,
                              onTap: isDownloading ? null : () => _launchUrl(resourceData!['fileUrl']),
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

          SizedBox(height: 20),

          // Additional information card (only for PDF)
          if (isPdf)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'About PDF Preview',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Text(
                    'The preview allows you to view the PDF directly within the app before downloading. You can zoom, scroll, and search through the document. Download the file to save it for offline access.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 80), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),

              SizedBox(width: 8),

              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedResourcesTab() {
    if (resourceData == null) return Container();

    // Query parameters for finding related resources
    String? category = resourceData!['category'];
    String? stream = resourceData!['stream'];
    String? subcategory = resourceData!['subcategory'];

    return StreamBuilder<QuerySnapshot>(
      stream: _getRelatedResourcesQuery(category, stream, subcategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(tertiaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyRelatedResources();
        }

        return ListView.builder(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header
              return _buildRelatedResourcesHeader();
            }

            final doc = snapshot.data!.docs[index - 1];
            final data = doc.data() as Map<String, dynamic>;

            return _buildRelatedResourceItem(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRelatedResourcesHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Resources',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Explore more resources similar to this one',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRelatedResources() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Related Resources',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'We couldn\'t find any resources similar to this one',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            TextButton.icon(
              icon: Icon(Icons.refresh_rounded),
              label: Text('Browse All Resources'),
              style: TextButton.styleFrom(
                foregroundColor: tertiaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                // Navigate to resources list
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedResourceItem(String resourceId, Map<String, dynamic> data) {
    IconData resourceIcon;
    Color resourceColor;

    // Determine icon and color
    if (data['category'] == 'Exam Papers' && data['subcategory'] != null) {
      resourceIcon = ResourceUtils.subcategoryIcons[data['subcategory']] ?? Icons.description_rounded;
      resourceColor = ResourceUtils.getSubcategoryColor(data['subcategory']);
    } else {
      resourceIcon = ResourceUtils.categoryIcons[data['category']] ?? Icons.insert_drive_file_rounded;
      resourceColor = ResourceUtils.streamColors[data['stream']] ?? Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResourceDetailScreen(resourceId: resourceId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Resource icon
              Hero(
                tag: 'resource-icon-$resourceId',
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: resourceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      resourceIcon,
                      size: 35,
                      color: resourceColor,
                    ),
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

                    SizedBox(height: 6),

                    // Badges row
                    Row(
                      children: [
                        // Stream badge
                        if (data['stream'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: ResourceUtils.streamColors[data['stream']]?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ResourceUtils.streamColors[data['stream']]?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              data['stream'],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: ResourceUtils.streamColors[data['stream']] ?? Colors.blue,
                              ),
                            ),
                          ),

                        // Subcategory badge for Exam Papers
                        if (data['category'] == 'Exam Papers' && data['subcategory'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ResourceUtils.getSubcategoryColor(data['subcategory']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ResourceUtils.getSubcategoryColor(data['subcategory']).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              data['subcategory'],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: ResourceUtils.getSubcategoryColor(data['subcategory']),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 6),

                    // Meta information
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          data['uploadedBy'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        Spacer(),

                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(data['uploadDate']),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Resource Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(tertiaryColor),
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Loading Resource',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please wait while we load the resource details',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Resource Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Resource Not Found',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'The resource you are looking for may have been removed or is unavailable.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back_rounded),
              label: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(dynamic date) {
    return ResourceUtils.formatDate(date);
  }

  IconData _getResourceIcon() {
    if (resourceData!['category'] == 'Exam Papers' && resourceData!['subcategory'] != null) {
      return ResourceUtils.subcategoryIcons[resourceData!['subcategory']] ?? Icons.description_rounded;
    } else {
      switch (resourceData!['category']) {
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
  }

  Color _getResourceColor() {
    if (resourceData!['category'] == 'Exam Papers' && resourceData!['subcategory'] != null) {
      return ResourceUtils.getSubcategoryColor(resourceData!['subcategory']);
    } else {
      switch (resourceData!['category']) {
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
  }

  Color _getStreamColor() {
    for (var entry in ResourceUtils.streamColors.entries) {
      if (entry.key == resourceData!['stream']) {
        return entry.value;
      }
    }
    return Colors.blue.shade700;
  }

  IconData _getFileTypeIcon() {
    if (resourceData == null || resourceData!['fileName'] == null) return Icons.insert_drive_file_rounded;

    String fileName = resourceData!['fileName'].toLowerCase();

    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description_rounded;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart_rounded;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
      return Icons.image_rounded;
    } else if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Icons.folder_zip_rounded;
    } else {
      return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileTypeColor() {
    if (resourceData == null || resourceData!['fileName'] == null) return Colors.grey.shade700;

    String fileName = resourceData!['fileName'].toLowerCase();

    if (fileName.endsWith('.pdf')) {
      return Colors.red.shade400;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Colors.blue.shade700;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Colors.green.shade600;
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Colors.orange.shade600;
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
      return Colors.purple.shade600;
    } else if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Colors.amber.shade700;
    } else {
      return Colors.grey.shade700;
    }
  }

  String _getFileTypeLabel() {
    if (resourceData == null || resourceData!['fileName'] == null) return 'Document';

    String fileName = resourceData!['fileName'].toLowerCase();

    if (fileName.endsWith('.pdf')) {
      return 'PDF Document';
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return 'Word Document';
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return 'Excel Spreadsheet';
    } else if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return 'PowerPoint';
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) {
      return 'Image';
    } else if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return 'Archive';
    } else {
      return 'Document';
    }
  }

  Future<void> _launchUrl(String urlString) async {
    setState(() {
      isDownloading = true;
    });

    try {
      final Uri url = Uri.parse(urlString);

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }

      // Increment download count in UI
      setState(() {
        downloadCount++;
      });

      // Update the view count in Firestore
      await ResourceUtils.incrementResourceViewCount(widget.resourceId);

      // Delayed download completion for UX feedback
      Timer(Duration(seconds: 1), () {
        setState(() {
          isDownloading = false;
        });

        // Show completion snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Download started successfully',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: Duration(seconds: 3),
          ),
        );
      });
    } catch (e) {
      setState(() {
        isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting download: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _previewPdf(String pdfUrl) {
    if (resourceData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          resourceId: widget.resourceId,
          pdfUrl: pdfUrl,
          title: resourceData!['title'] ?? 'PDF Preview',
          resourceData: resourceData!,
        ),
      ),
    );
  }

  void _shareResource() {
    if (resourceData != null && resourceData!['fileUrl'] != null) {
      final title = resourceData!['title'] ?? 'Resource';
      final url = resourceData!['fileUrl'];

      // Include subcategory in share message for Exam Papers
      String shareMessage = 'Check out this resource: $title\n';
      if (resourceData!['category'] == 'Exam Papers' && resourceData!['subcategory'] != null) {
        shareMessage += '[${resourceData!['stream']} - ${resourceData!['subcategory']}]\n';
      } else {
        shareMessage += '[${resourceData!['stream']}]\n';
      }
      shareMessage += url;

      Share.share(shareMessage);
    }
  }

  bool _isResourceOwner() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || resourceData == null) return false;
    return resourceData!['uploaderId'] == user.uid;
  }

  void _navigateToEditScreen() {
    if (!isAdmin && !_isResourceOwner()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only administrators or resource owners can edit resources'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Navigate to edit screen
    Navigator.pushNamed(
      context,
      '/resource_management',
      arguments: {'editing': true, 'resourceId': widget.resourceId},
    );
  }

  void _showDeleteConfirmation() {
    if (!isAdmin && !_isResourceOwner()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only administrators or resource owners can delete resources'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

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
                  Text(
                    'Delete Resource',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
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
                'Are you sure you want to delete this resource?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '"${resourceData!['title']}"',
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
                        'This action cannot be undone. The resource and its file will be permanently deleted.',
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
                        borderRadius: BorderRadius.circular(12),
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
                  await ResourceUtils.deleteResource(widget.resourceId);

                  // Dismiss loading dialog
                  Navigator.pop(context);

                  // Go back to previous screen
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Resource deleted successfully',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
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
                } catch (e) {
                  // Dismiss loading dialog
                  Navigator.pop(context);

                  print('Error deleting resource: $e');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting resource: $e'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        );
      },
    );
  }

  // Helper method to build the proper query for related resources
  Stream<QuerySnapshot> _getRelatedResourcesQuery(String? category, String? stream, String? subcategory) {
    Query query = FirebaseFirestore.instance.collection('resources');

    // Base query with same category and stream
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (stream != null) {
      query = query.where('stream', isEqualTo: stream);
    }

    // For Exam Papers, add subcategory filter if available
    if (category == 'Exam Papers' && subcategory != null) {
      query = query.where('subcategory', isEqualTo: subcategory);
    }

    // Exclude current resource
    query = query.where(FieldPath.documentId, isNotEqualTo: widget.resourceId);

    // Limit results and order by date
    return query.limit(10).orderBy('uploadDate', descending: true).snapshots();
  }
}