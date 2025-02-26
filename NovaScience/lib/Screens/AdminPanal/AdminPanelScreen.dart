import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Custom color palette
  final Color greenColor = const Color(0xFF11261f); // Dark green - primary
  final Color yellowColor = const Color(0xFF123755); // Navy blue - secondary
  final Color maroonColor = const Color(0xFF722626); // Maroon - error
  final Color accentColor = const Color(0xFFe9c46a); // Gold accent
  final Color surfaceColor = const Color(0xFFF7F7F2); // Light cream background
  final Color textDarkColor = const Color(0xFF1F2937); // Dark text
  final Color textLightColor = const Color(0xFFF9FAFB); // Light text

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController and Fade Animation
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward(); // Start the animation
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 100)),
      from: 30,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: greenColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: accentColor.withOpacity(0.1),
            highlightColor: accentColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container with gold background
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: yellowColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: greenColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textDarkColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: yellowColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Administration',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: greenColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ADMIN CONTROLS',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: greenColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scrollable list of admin cards
                Expanded(
                  child: ListView(
                    children: [
                      _buildAdminCard(
                        icon: Icons.dashboard_outlined,
                        title: 'Dashboard Overview',
                        subtitle: 'View key metrics and activity logs',
                        onTap: () {
                          Navigator.pushNamed(context, '/dashboardOverview');
                        },
                        index: 0,
                      ),
                      _buildAdminCard(
                        icon: Icons.people_outline,
                        title: 'User Management',
                        subtitle: 'Manage users, roles, and permissions',
                        onTap: () {
                          Navigator.pushNamed(context, '/userManagement');
                        },
                        index: 1,
                      ),
                      _buildAdminCard(
                        icon: Icons.book_outlined,
                        title: 'Course Management',
                        subtitle: 'Add, update, or remove courses',
                        onTap: () {
                          Navigator.pushNamed(context, '/courseManagement');
                        },
                        index: 2,
                      ),
                      _buildAdminCard(
                        icon: Icons.school_outlined,
                        title: 'Enrollment Management',
                        subtitle: 'Assign courses to users',
                        onTap: () {
                          Navigator.pushNamed(context, '/enrollUsers');
                        },
                        index: 3,
                      ),
                      _buildAdminCard(
                        icon: Icons.analytics_outlined,
                        title: 'Reports & Analytics',
                        subtitle: 'View reports and analytics',
                        onTap: () {
                          Navigator.pushNamed(context, '/reports');
                        },
                        index: 4,
                      ),
                      _buildAdminCard(
                        icon: Icons.settings_outlined,
                        title: 'System Settings',
                        subtitle: 'Configure system settings',
                        onTap: () {
                          Navigator.pushNamed(context, '/systemSettings');
                        },
                        index: 5,
                      ),
                      _buildAdminCard(
                        icon: Icons.campaign_outlined,
                        title: 'Advertisement Management',
                        subtitle: 'Add, edit, or delete advertisements',
                        onTap: () {
                          Navigator.pushNamed(context, '/manageAdvertisements');
                        },
                        index: 6,
                      ),
                      _buildAdminCard(
                        icon: Icons.payments_outlined,
                        title: 'Payment Details',
                        subtitle: 'View all teacher payment details',
                        onTap: () {
                          Navigator.pushNamed(context, '/teachersPayment');
                        },
                        index: 7,
                      ),
                    ],
                  ),
                ),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Handle logout action here
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Column(
                            children: [
                              Icon(
                                Icons.logout,
                                color: maroonColor,
                                size: 36,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Confirm Logout',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: greenColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          content: Text(
                            'Are you sure you want to log out of the admin panel?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textDarkColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'CANCEL',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: yellowColor,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Implement actual logout logic
                                Navigator.of(context).pop();
                                // Then navigate to login screen or perform other logout operations
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maroonColor,
                                foregroundColor: textLightColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'LOGOUT',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.logout_outlined, size: 18),
                    label: Text(
                      'LOGOUT',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonColor,
                      foregroundColor: textLightColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}