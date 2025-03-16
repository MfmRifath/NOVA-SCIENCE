// DashboardScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../StartScreen/ResourceUtils.dart';

class ResourceDashboardScreen extends StatefulWidget {
  @override
  _ResourceDashboardScreenState createState() => _ResourceDashboardScreenState();
}

class _ResourceDashboardScreenState extends State<ResourceDashboardScreen> with SingleTickerProviderStateMixin {
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  TabController? _tabController;
  int _currentTabIndex = 0;

  bool isLoading = true;
  Map<String, dynamic> resourceStats = {
    'totalCount': 0,
    'streamCounts': {},
    'categoryCounts': {},
    'subcategoryCounts': {},
  };

  List<Map<String, dynamic>> recentResources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get resource statistics
      final stats = await ResourceUtils.getResourceStats();

      // Get recent resources
      final recentSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .orderBy('uploadDate', descending: true)
          .limit(5)
          .get();

      final recent = recentSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        resourceStats = stats;
        recentResources = List<Map<String, dynamic>>.from(recent);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: greenColor,
          title: Text('Resource Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(maroonColor),
              ),
              SizedBox(height: 16),
              Text(
                'Loading dashboard data...',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: greenColor,
        title: Text(
          'Resource Dashboard',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Exam Papers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview tab
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(),
                SizedBox(height: 24),
                _buildStreamPieChart(),
                SizedBox(height: 24),
                _buildCategoryBarChart(),
                SizedBox(height: 24),
                _buildRecentResourcesList(),
              ],
            ),
          ),
          // Exam Papers tab with subcategories
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamPapersOverview(),
                SizedBox(height: 24),
                _buildExamPaperSubcategoriesChart(),
                SizedBox(height: 24),
                _buildExamPapersByStream(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: maroonColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Navigate to add resource screen
          Navigator.pushNamed(context, '/resource_management');
        },
        tooltip: 'Add Resource',
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Resources',
          resourceStats['totalCount'].toString(),
          Icons.folder,
          Colors.blue.shade700,
        ),
        _buildStatCard(
          'Science Resources',
          resourceStats['streamCounts']['Science Stream'].toString(),
          Icons.science,
          Colors.green.shade700,
        ),
        _buildStatCard(
          'Exam Papers',
          resourceStats['categoryCounts']['Exam Papers'].toString(),
          Icons.description,
          Colors.orange.shade700,
        ),
        _buildStatCard(
          'Books',
          resourceStats['categoryCounts']['Books'].toString(),
          Icons.book,
          Colors.purple.shade700,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.1),
            ],
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            Spacer(),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamPapersOverview() {
    final examPapersCount = resourceStats['categoryCounts']['Exam Papers'] ?? 0;
    final subcategoryCounts = resourceStats['subcategoryCounts'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exam Papers Overview',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: greenColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: $examPapersCount',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _buildExamPaperTypeCard(
                  'Term Papers',
                  subcategoryCounts['Term Papers'] ?? 0,
                  ResourceUtils.subcategoryIcons['Term Papers'] ?? Icons.assignment,
                  ResourceUtils.getSubcategoryColor('Term Papers'),
                ),
                _buildExamPaperTypeCard(
                  'Model Papers',
                  subcategoryCounts['Model Papers'] ?? 0,
                  ResourceUtils.subcategoryIcons['Model Papers'] ?? Icons.model_training,
                  ResourceUtils.getSubcategoryColor('Model Papers'),
                ),
                _buildExamPaperTypeCard(
                  'Past Papers',
                  subcategoryCounts['Past Papers'] ?? 0,
                  ResourceUtils.subcategoryIcons['Past Papers'] ?? Icons.history_edu,
                  ResourceUtils.getSubcategoryColor('Past Papers'),
                ),
                _buildExamPaperTypeCard(
                  'Term Paper Keys',
                  subcategoryCounts['Term Paper Keys'] ?? 0,
                  ResourceUtils.subcategoryIcons['Term Paper Keys'] ?? Icons.key,
                  ResourceUtils.getSubcategoryColor('Term Paper Keys'),
                ),
                _buildExamPaperTypeCard(
                  'Past Paper Keys',
                  subcategoryCounts['Past Paper Keys'] ?? 0,
                  ResourceUtils.subcategoryIcons['Past Paper Keys'] ?? Icons.vpn_key,
                  ResourceUtils.getSubcategoryColor('Past Paper Keys'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamPaperTypeCard(String title, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        color: color.withOpacity(0.05),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '$count',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamPaperSubcategoriesChart() {
    final subcategoryCounts = resourceStats['subcategoryCounts'] as Map<String, dynamic>;
    final subcategoryEntries = subcategoryCounts.entries.toList();

    // Prepare data for bar chart
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < subcategoryEntries.length; i++) {
      final entry = subcategoryEntries[i];
      final subcategory = entry.key;
      final count = entry.value;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: ResourceUtils.getSubcategoryColor(subcategory),
              width: 16,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Papers by Type',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 250,
              child: barGroups.isEmpty
                  ? Center(child: Text('No data available'))
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: subcategoryEntries.map((e) => e.value as int).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < subcategoryEntries.length) {
                            final label = subcategoryEntries[index].key.split(' ')[0];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                label,
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamPapersByStream() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exam Papers by Stream',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('resources')
                    .where('category', isEqualTo: 'Exam Papers')
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No exam papers data available'));
                  }

                  // Count papers by stream and subcategory
                  Map<String, Map<String, int>> streamSubcategoryCounts = {};

                  // Initialize the map for each stream
                  ResourceUtils.streamColors.keys.forEach((streamName) {
                    streamSubcategoryCounts[streamName] = {};
                    ResourceUtils.categorySubcategories['Exam Papers']!.forEach((subcategory) {
                      streamSubcategoryCounts[streamName]![subcategory] = 0;
                    });
                  });

                  // Count the documents
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String stream = data['stream'] ?? 'Unknown';
                    String subcategory = data['subcategory'] ?? 'Unknown';

                    if (streamSubcategoryCounts.containsKey(stream) &&
                        streamSubcategoryCounts[stream]!.containsKey(subcategory)) {
                      streamSubcategoryCounts[stream]![subcategory] =
                          (streamSubcategoryCounts[stream]![subcategory] ?? 0) + 1;
                    }
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: streamSubcategoryCounts.length,
                    itemBuilder: (context, index) {
                      final stream = streamSubcategoryCounts.keys.elementAt(index);
                      final subcategoryCounts = streamSubcategoryCounts[stream]!;
                      final totalForStream = subcategoryCounts.values.fold(0, (sum, count) => sum + count);

                      if (totalForStream == 0) return Container(); // Skip if no papers

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: ResourceUtils.streamColors[stream] ?? Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                stream,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Spacer(),
                              Text(
                                'Total: $totalForStream',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ResourceUtils.streamColors[stream] ?? Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ...subcategoryCounts.entries.map((entry) {
                            final subcategory = entry.key;
                            final count = entry.value;
                            final percentage = totalForStream > 0 ? count / totalForStream : 0;

                            return Padding(
                              padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    ResourceUtils.subcategoryIcons[subcategory] ?? Icons.label,
                                    size: 14,
                                    color: ResourceUtils.getSubcategoryColor(subcategory),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    subcategory,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: percentage.toDouble(),
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: ResourceUtils.getSubcategoryColor(subcategory),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '$count',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: ResourceUtils.getSubcategoryColor(subcategory),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          Divider(height: 24),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBarChart() {
    final categoryCounts = resourceStats['categoryCounts'] as Map<String, dynamic>;
    final categoryEntries = categoryCounts.entries.toList();

    // Prepare data for bar chart
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < categoryEntries.length; i++) {
      final entry = categoryEntries[i];
      final category = entry.key;
      final count = entry.value;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: ResourceUtils.categoryIcons.containsKey(category)
                  ? ResourceUtils.streamColors.values.elementAt(i % ResourceUtils.streamColors.length)
                  : Colors.grey,
              width: 20,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resources by Category',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: barGroups.isEmpty
                  ? Center(child: Text('No data available'))
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: categoryEntries.map((e) => e.value as int).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                  titlesData: FlTitlesData(
                    // Updated to use the new API
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < categoryEntries.length) {
                            return Text(
                              categoryEntries[index].key.split(' ')[0],
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamPieChart() {
    final streamCounts = resourceStats['streamCounts'] as Map<String, dynamic>;
    final streamEntries = streamCounts.entries.toList();

    // Prepare data for pie chart
    List<PieChartSectionData> sections = [];
    for (int i = 0; i < streamEntries.length; i++) {
      final entry = streamEntries[i];
      final stream = entry.key;
      final count = entry.value;

      if (count > 0) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '$count',
            titleStyle: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            color: ResourceUtils.streamColors[stream] ?? Colors.grey,
            radius: 100,
            titlePositionPercentageOffset: 0.55,
          ),
        );
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resources by Stream',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: sections.isEmpty
                  ? Center(child: Text('No data available'))
                  : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildStreamLegend(streamEntries),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamLegend(List<MapEntry<String, dynamic>> streamEntries) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: streamEntries.map((entry) {
        final stream = entry.key;
        final count = entry.value;

        if (count > 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: ResourceUtils.streamColors[stream] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stream,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        return Container();
      }).toList(),
    );
  }

  Widget _buildRecentResourcesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Added Resources',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: greenColor,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View All'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/resource_management');
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            if (recentResources.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No recent resources found'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: recentResources.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final resource = recentResources[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (ResourceUtils.streamColors[resource['stream']] ?? Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ResourceUtils.categoryIcons[resource['category']] ?? Icons.insert_drive_file,
                        color: ResourceUtils.streamColors[resource['stream']] ?? Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      resource['title'] ?? 'Untitled',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        // Show subcategory badge for Exam Papers
                        if (resource['category'] == 'Exam Papers' && resource['subcategory'] != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: ResourceUtils.getSubcategoryColor(resource['subcategory']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              resource['subcategory'],
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: ResourceUtils.getSubcategoryColor(resource['subcategory']),
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            '${resource['stream'] ?? 'Unknown'} • ${ResourceUtils.formatDate(resource['uploadDate'])}',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      // Navigate to resource details
                      Navigator.pushNamed(
                        context,
                        '/resource_detail',
                        arguments: {'resourceId': resource['id']},
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}