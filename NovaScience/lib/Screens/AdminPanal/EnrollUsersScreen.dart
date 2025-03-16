import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// Updated color palette for better contrast and accessibility
class AppColors {
  // Primary colors with better contrast
  static const Color primary = Color(0xFF0A4D36);     // Darker Green
  static const Color secondary = Color(0xFF0E4B80);   // Deeper Blue
  static const Color accent = Color(0xFF9E2A2A);      // Richer Maroon

  // Background and text colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightText = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF212529);

  // Feedback colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0288D1);

  // Neutral colors
  static const Color neutral100 = Color(0xFFF8F9FA);
  static const Color neutral200 = Color(0xFFE9ECEF);
  static const Color neutral300 = Color(0xFFDEE2E6);
  static const Color neutral400 = Color(0xFFCED4DA);
  static const Color neutral500 = Color(0xFFADB5BD);
  static const Color neutral600 = Color(0xFF6C757D);
  static const Color neutral700 = Color(0xFF495057);
  static const Color neutral800 = Color(0xFF343A40);
  static const Color neutral900 = Color(0xFF212529);
}

class EnrollUsersScreen extends StatefulWidget {
  @override
  _EnrollUsersScreenState createState() => _EnrollUsersScreenState();
}

class _EnrollUsersScreenState extends State<EnrollUsersScreen> with SingleTickerProviderStateMixin {
  String? selectedUserId;
  String? selectedCourseId;
  String? selectedUserName;
  String? selectedCourseName;
  DateTime? enrollmentEndDate;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Animation controller for enhanced feedback
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to make the UI responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrLarger = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Course Enrollment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.lightText,
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.lightText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.lightBackground,
            ],
          ),
        ),
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Processing Enrollment...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),

                  // If tablet or larger, display form fields in a row
                  if (isTabletOrLarger)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildUserSelection()),
                        SizedBox(width: 16),
                        Expanded(child: _buildCourseSelection()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildUserSelection(),
                        SizedBox(height: 20),
                        _buildCourseSelection(),
                      ],
                    ),

                  SizedBox(height: 20),
                  _buildDateSelection(),
                  SizedBox(height: 30),
                  _buildEnrollButton(),
                  SizedBox(height: 20),

                  // Show enrollment summary with animation when fields are selected
                  if (selectedUserId != null && selectedCourseId != null)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                      )),
                      child: _buildEnrollmentSummary(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Enrollment',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete the form below to enroll a user in a course',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.neutral700,
            ),
          ),
          SizedBox(height: 10),
          Divider(color: AppColors.primary.withOpacity(0.2), thickness: 1),
        ],
      ),
    );
  }

  Widget _buildUserSelection() {
    return Card(
      elevation: 2,
      shadowColor: AppColors.neutral500.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            DropdownSearch<Map<String, dynamic>>(
              asyncItems: (String filter) => _fetchUsers(filter),
              compareFn: (item1, item2) => item1['id'] == item2['id'], // Add compareFn to fix assertion error
              popupProps: PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
                // Enhanced popup with better user feedback
                loadingBuilder: (context, searchEntry) => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                emptyBuilder: (context, searchEntry) => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 40, color: AppColors.neutral500),
                        SizedBox(height: 8),
                        Text(
                          'No users found matching "$searchEntry"',
                          style: TextStyle(color: AppColors.neutral700),
                        ),
                      ],
                    ),
                  ),
                ),
                containerBuilder: (context, popupWidget) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: popupWidget,
                    ),
                  );
                },
                menuProps: MenuProps(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Search Users',
                    labelStyle: TextStyle(color: AppColors.secondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.secondary, width: 2),
                    ),
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.secondary,
                          child: Text(
                            (item['email'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(color: AppColors.lightText),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? item['email'] ?? 'Unnamed User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (item['email'] != null)
                                Text(
                                  item['email'],
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.primary)
                      ],
                    ),
                  );
                },
              ),
              itemAsString: (item) => item['email'] ?? 'Unnamed User',
              onChanged: (value) {
                setState(() {
                  selectedUserId = value?['id'];
                  selectedUserName = value?['name'] ?? value?['email'] ?? 'Unnamed User';
                });
                // Trigger animation when selection changes
                if (value != null) {
                  _animationController.reset();
                  _animationController.forward();
                }
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Select User',
                  labelStyle: TextStyle(color: AppColors.darkText),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                  // Add helper text for better UX
                  helperText: 'Search by email or name',
                ),
              ),
              autoValidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null) {
                  return 'Please select a user';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSelection() {
    return Card(
      elevation: 2,
      shadowColor: AppColors.neutral500.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.secondary.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Course Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            DropdownSearch<Map<String, dynamic>>(
              asyncItems: (String filter) => _fetchCourses(filter),
              compareFn: (item1, item2) => item1['id'] == item2['id'], // Add compareFn to fix assertion error
              popupProps: PopupProps.menu(
                showSelectedItems: true,
                showSearchBox: true,
                // Enhanced popup with better user feedback
                loadingBuilder: (context, searchEntry) => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                ),
                emptyBuilder: (context, searchEntry) => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 40, color: AppColors.neutral500),
                        SizedBox(height: 8),
                        Text(
                          'No courses found matching "$searchEntry"',
                          style: TextStyle(color: AppColors.neutral700),
                        ),
                      ],
                    ),
                  ),
                ),
                containerBuilder: (context, popupWidget) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: popupWidget,
                    ),
                  );
                },
                menuProps: MenuProps(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Search Courses',
                    labelStyle: TextStyle(color: AppColors.secondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.secondary, width: 2),
                    ),
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['courseTitle'] ?? 'Untitled Course',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: AppColors.secondary),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.cast_for_education, size: 14, color: AppColors.secondary),
                            SizedBox(width: 4),
                            Text(
                              'Medium: ${item['medium'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text(
                              'Instructor: ${item['instructor'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              itemAsString: (item) => item['courseTitle'] ?? 'Untitled Course',
              onChanged: (value) {
                setState(() {
                  selectedCourseId = value?['id'];
                  selectedCourseName = value?['courseTitle'] ?? 'Untitled Course';
                });
                // Trigger animation when selection changes
                if (value != null) {
                  _animationController.reset();
                  _animationController.forward();
                }
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Select Course',
                  labelStyle: TextStyle(color: AppColors.darkText),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondary.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.secondary.withOpacity(0.2)),
                  ),
                  prefixIcon: Icon(Icons.book, color: AppColors.secondary),
                  // Add helper text for better UX
                  helperText: 'Search by course title',
                ),
              ),
              autoValidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null) {
                  return 'Please select a course';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final String formattedDate = enrollmentEndDate != null
        ? formatter.format(enrollmentEndDate!)
        : 'Not Selected';

    return Card(
      elevation: 2,
      shadowColor: AppColors.neutral500.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.accent.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.accent),
                SizedBox(width: 8),
                Text(
                  'Enrollment Period',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Helper text for better UX
            Text(
              'Set the date when the user\'s access to the course will expire',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.neutral600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: enrollmentEndDate == null
                      ? AppColors.accent.withOpacity(0.2)
                      : AppColors.accent.withOpacity(0.5),
                  width: enrollmentEndDate == null ? 1 : 2,
                ),
              ),
              child: InkWell(
                onTap: () async {
                  // Add haptic feedback for better user experience
                  HapticFeedback.lightImpact();

                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: enrollmentEndDate ?? DateTime.now().add(Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 5),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.accent,
                            onPrimary: Colors.white,
                            onSurface: AppColors.darkText,
                          ),
                          dialogBackgroundColor: AppColors.lightBackground,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (selectedDate != null) {
                    setState(() {
                      enrollmentEndDate = selectedDate;
                    });
                    // Trigger animation when date changes
                    _animationController.reset();
                    _animationController.forward();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enrollment End Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.darkText.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: enrollmentEndDate == null
                                  ? AppColors.darkText.withOpacity(0.5)
                                  : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (enrollmentEndDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Please select an end date',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollButton() {
    final bool isFormValid = selectedUserId != null &&
        selectedCourseId != null &&
        enrollmentEndDate != null;

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid
            ? () {
          // Add haptic feedback
          HapticFeedback.mediumImpact();
          _showConfirmationDialog(context);
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.neutral400,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.neutral600,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 20),
            SizedBox(width: 8),
            Text(
              'Complete Enrollment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentSummary() {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final String formattedDate = enrollmentEndDate != null
        ? formatter.format(enrollmentEndDate!)
        : 'Not Selected';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.neutral100,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enrollment Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: 12),
              _buildSummaryItem(
                icon: Icons.person,
                label: 'User',
                value: selectedUserName ?? 'Not selected',
                color: AppColors.primary,
              ),
              SizedBox(height: 8),
              _buildSummaryItem(
                icon: Icons.school,
                label: 'Course',
                value: selectedCourseName ?? 'Not selected',
                color: AppColors.secondary,
              ),
              SizedBox(height: 8),
              _buildSummaryItem(
                icon: Icons.calendar_today,
                label: 'End Date',
                value: formattedDate,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.darkText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Fetch users from Firestore with improved error handling
  Future<List<Map<String, dynamic>>> _fetchUsers(String filter) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .where((user) => user['email'] != null &&
          user['email'].toLowerCase().contains(filter.toLowerCase()))
          .toList();
    } catch (e) {
      // Add better error handling with user feedback
      print('Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users. Please check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
      return [];
    }
  }

  // Fetch courses from Firestore with improved error handling
  Future<List<Map<String, dynamic>>> _fetchCourses(String filter) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('courses').get();
      return querySnapshot.docs
          .map((doc) => {
        'id': doc.id,
        'courseTitle': doc.data()['courseTitle'] ?? 'Untitled Course',
        'medium': doc.data()['medium'] ?? 'N/A',
        'instructor': doc.data()['instructor'] ?? 'N/A',
      })
          .where((course) => course['courseTitle']
          .toLowerCase()
          .contains(filter.toLowerCase()))
          .toList();
    } catch (e) {
      // Add better error handling with user feedback
      print('Error fetching courses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load courses. Please check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
      return [];
    }
  }

  // Show a confirmation dialog before enrolling the user
  void _showConfirmationDialog(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    final String formattedDate = enrollmentEndDate != null
        ? formatter.format(enrollmentEndDate!)
        : '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                'Confirm Enrollment',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to enroll this user in the selected course?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              _buildConfirmationItem(
                icon: Icons.person,
                label: 'User',
                value: selectedUserName ?? 'Not selected',
                color: AppColors.primary,
              ),
              _buildConfirmationItem(
                icon: Icons.school,
                label: 'Course',
                value: selectedCourseName ?? 'Not selected',
                color: AppColors.secondary,
              ),
              _buildConfirmationItem(
                icon: Icons.calendar_today,
                label: 'Access Until',
                value: formattedDate,
                color: AppColors.accent,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neutral700,
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (selectedUserId != null && selectedCourseId != null && enrollmentEndDate != null) {
                  setState(() {
                    _isLoading = true;
                  });
                  await enrollUserInCourse(selectedUserId!, selectedCourseId!, enrollmentEndDate!);
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: Text('Yes, Enroll'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: AppColors.darkText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fixed enrollUserInCourse method with renamed parameter to avoid naming conflict
  Future<void> enrollUserInCourse(String userId, String courseId, DateTime endDate) async {
    try {
      // Get the current date as the enrollment date
      DateTime enrollmentDate = DateTime.now();

      // Use a batch write for consistency across multiple documents
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Reference to the user document
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Reference to the course document
      DocumentReference courseRef = FirebaseFirestore.instance.collection('courses').doc(courseId);

      // Update the user's document with the enrollment details
      batch.update(userRef, {
        'enrolledCourses': FieldValue.arrayUnion([
          {
            'courseId': courseId,
            'enrollmentDate': enrollmentDate,
            'enrollmentEndDate': endDate,
            'progress': 0.0, // Initialize progress tracking
          }
        ]),
      });

      // Create a dedicated enrollment record for detailed tracking
      DocumentReference enrollmentRef = FirebaseFirestore.instance.collection('enrollments').doc();
      batch.set(enrollmentRef, {
        'userId': userId,
        'courseId': courseId,
        'enrollmentDate': enrollmentDate,
        'enrollmentEndDate': endDate,
        'progress': 0.0,
        'lastAccessed': enrollmentDate,
        'hoursSpent': 0.0,
        'active': true,
      });

      // Update the course document to increment the student count
      batch.update(courseRef, {
        'students': FieldValue.increment(1),
        'enrolledUserIds': FieldValue.arrayUnion([userId]),
      });

      // Commit all the batch operations
      await batch.commit();

      // Reset selections - fixed the DateTime? null assignment by using 'this.' to reference class field
      setState(() {
        selectedUserId = null;
        selectedCourseId = null;
        selectedUserName = null;
        selectedCourseName = null;
        this.enrollmentEndDate = null; // Use 'this.' to explicitly refer to the class field
        _formKey.currentState?.reset();
      });

      // Show success message with an improved snackbar design
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enrollment Successful!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('The user has been enrolled in the course.'),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      // Show error message with an improved snackbar design
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enrollment Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('Error: ${e.toString().substring(0, math.min(e.toString().length, 50))}...'),
                    Text('Please try again or contact support.'),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 6),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () {
              _showConfirmationDialog(context);
            },
          ),
        ),
      );
    }
  }
}