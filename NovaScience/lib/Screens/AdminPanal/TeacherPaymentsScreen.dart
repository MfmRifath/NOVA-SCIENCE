import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../Modals/User.dart';
import '../../Service/AuthService.dart';

/// Shows the total app revenue across all teachers (by month),
/// plus each individual teacher's monthly totals & course breakdown.
class TeacherPaymentsScreen extends StatefulWidget {
  const TeacherPaymentsScreen({Key? key}) : super(key: key);

  @override
  _TeacherPaymentsScreenState createState() => _TeacherPaymentsScreenState();
}

class _TeacherPaymentsScreenState extends State<TeacherPaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Teachers - Payment Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            // 1) Show the total (app-wide) monthly revenue
            FutureBuilder<Map<String, double>>(
              future: _fetchAppWideMonthlyRevenue(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _RevenueLoadingCard();
                } else if (snapshot.hasError) {
                  return _RevenueErrorCard(errorMessage: snapshot.error.toString());
                } else {
                  final monthlyData = snapshot.data ?? {};
                  return _AppRevenueCard(monthlyData: monthlyData);
                }
              },
            ),

            const SizedBox(height: 16),

            // 2) The list of teachers with their monthly breakdown
            Expanded(
              child: FutureBuilder<List<CustomUser>>(
                future: _fetchAllTeachers(authService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No teachers found.'));
                  } else {
                    final teachers = snapshot.data!;
                    return ListView.separated(
                      itemCount: teachers.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final teacher = teachers[index];
                        return _buildTeacherTile(teacher);
                      },
                    ).animate().fade().slideY(begin: 0.02);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // (A) Fetch ALL teachers (role == 'Teacher')
  // ---------------------------------------------------------------------------
  Future<List<CustomUser>> _fetchAllTeachers(AuthService authService) async {
    final allUsers = await authService.fetchAllUsers();
    return allUsers.where((user) => user.role == 'Teacher').toList();
  }

  // ---------------------------------------------------------------------------
  // (B) Build each teacher's tile (includes monthly combined totals + courses)
  // ---------------------------------------------------------------------------
  Widget _buildTeacherTile(CustomUser teacher) {
    final teacherName = teacher.name ?? teacher.email ?? 'Unknown';
    final teacherEmail = teacher.email ?? 'No Email';

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white, size: 26),
        ),
        title: Text(
          teacherName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          teacherEmail,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        children: [
          // B1) Monthly combined totals for this teacher
          FutureBuilder<Map<String, double>>(
            future: _fetchMonthlyEarningsAllCourses(teacherEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Error loading combined monthly earnings: ${snapshot.error}'),
                );
              } else {
                final monthlyTotals = snapshot.data ?? {};
                if (monthlyTotals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No monthly totals data'),
                  );
                }
                return _buildCombinedMonthlyTotalsTile(monthlyTotals);
              }
            },
          ),

          // B2) Each course -> monthly breakdown
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTeacherCourses(teacherEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error loading teacher courses: ${snapshot.error}'),
                );
              } else {
                final courses = snapshot.data ?? [];
                if (courses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No courses found for this teacher'),
                  );
                }
                return Column(
                  children: courses.map((course) => _buildCourseTile(course)).toList(),
                );
              }
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildCombinedMonthlyTotalsTile(Map<String, double> monthlyTotals) {
    // Sort months
    final sortedKeys = monthlyTotals.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: const Icon(Icons.summarize, color: Colors.blue),
        title: const Text(
          'Monthly Combined Totals',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          for (final month in sortedKeys)
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(month),
              trailing: Text(
                '\$${(monthlyTotals[month] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeIn);
  }

  // ---------------------------------------------------------------------------
  // (C) Courses & Earnings
  // ---------------------------------------------------------------------------
  Widget _buildCourseTile(Map<String, dynamic> course) {
    final courseTitle = course['courseTitle'] ?? 'Untitled Course';
    final coursePrice = course['price']?.toDouble() ?? 0.0;
    final courseId = course['id'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: const Icon(Icons.book),
        title: Text(
          courseTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text('Price: \$${coursePrice.toStringAsFixed(2)}'),
        children: [
          FutureBuilder<Map<String, double>>(
            future: _fetchMonthlyEarningsForCourse(courseId, coursePrice),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error loading monthly earnings: ${snapshot.error}'),
                );
              } else {
                final monthlyData = snapshot.data ?? {};
                if (monthlyData.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No enrollments for this course'),
                  );
                }

                // Sort months
                final sortedKeys = monthlyData.keys.toList()..sort();
                return Column(
                  children: sortedKeys.map((month) {
                    final earnings = monthlyData[month]!;
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(month),
                      trailing: Text(
                        '\$${earnings.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ).animate().fade(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeIn);
              }
            },
          ),
        ],
      ),
    );
  }

  /// (C1) Fetch teacher's courses
  Future<List<Map<String, dynamic>>> _fetchTeacherCourses(String teacherEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// (C2) Calculate monthly earnings for a single course
  Future<Map<String, double>> _fetchMonthlyEarningsForCourse(
      String courseId,
      double coursePrice,
      ) async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

    final Map<String, int> monthCount = {};
    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId == courseId) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            monthCount.update(
              monthKey,
                  (existing) => existing + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
    }

    final Map<String, double> monthlyEarnings = {};
    monthCount.forEach((month, count) {
      monthlyEarnings[month] = count * coursePrice;
    });

    return monthlyEarnings;
  }

  /// (C3) Calculate combined monthly earnings for ALL courses by a single teacher
  Future<Map<String, double>> _fetchMonthlyEarningsAllCourses(String teacherEmail) async {
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      teacherCourses[doc.id] = coursePrice;
    }

    final Map<String, double> monthlyEarnings = {};
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && teacherCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            final price = teacherCourses[cId] ?? 0.0;
            monthlyEarnings.update(
              monthKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    return monthlyEarnings;
  }

  /// (D) Calculate APP-WIDE revenue for all teachers/courses
  Future<Map<String, double>> _fetchAppWideMonthlyRevenue() async {
    final courseSnapshot =
    await FirebaseFirestore.instance.collection('courses').get();

    final Map<String, double> allCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      allCourses[doc.id] = coursePrice;
    }

    final Map<String, double> monthlyRevenue = {};
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && allCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final double price = allCourses[cId] ?? 0.0;

            monthlyRevenue.update(
              monthKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    return monthlyRevenue;
  }
}

/// Simple loading card for the revenue section
class _RevenueLoadingCard extends StatelessWidget {
  const _RevenueLoadingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading App Revenue...'),
          ],
        ),
      ),
    );
  }
}

/// A card that shows an error for the revenue section
class _RevenueErrorCard extends StatelessWidget {
  final String errorMessage;

  const _RevenueErrorCard({
    Key? key,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: Text(
          'Error: $errorMessage',
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }
}

/// A card that shows the app-wide monthly revenue data
class _AppRevenueCard extends StatelessWidget {
  final Map<String, double> monthlyData;

  const _AppRevenueCard({
    Key? key,
    required this.monthlyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Card(
        child: ListTile(
          title: Text('No App Revenue Data'),
        ),
      );
    }

    final sortedKeys = monthlyData.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.shade50,
      child: ExpansionTile(
        leading: const Icon(Icons.attach_money, color: Colors.teal),
        title: const Text(
          'Total App Revenue (All Teachers)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          for (final month in sortedKeys)
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.grey),
              title: Text(month),
              trailing: Text(
                '\$${(monthlyData[month] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeIn);
  }
}