// ResourceStatsWidget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ResourceUtils.dart';


class ResourceStatsWidget extends StatefulWidget {
  @override
  _ResourceStatsWidgetState createState() => _ResourceStatsWidgetState();
}

class _ResourceStatsWidgetState extends State<ResourceStatsWidget> {
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);

  bool isLoading = true;
  int totalResources = 0;
  Map<String, int> streamCounts = {};
  Map<String, int> categoryCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ResourceUtils.getResourceStats();

      setState(() {
        totalResources = stats['totalCount'];
        streamCounts = Map<String, int>.from(stats['streamCounts']);
        categoryCounts = Map<String, int>.from(stats['categoryCounts']);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading resource stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        elevation: 2,
        child: Container(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Resources',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: greenColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.folder, color: maroonColor),
                  onPressed: () {
                    // Navigate to Resources screen
                  },
                  tooltip: 'View Resources',
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    totalResources.toString(),
                    'Total Resources',
                    Icons.folder,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    categoryCounts['Exam Papers'].toString(),
                    'Exam Papers',
                    Icons.description,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    categoryCounts['Notes'].toString(),
                    'Notes',
                    Icons.note,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: 1.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(maroonColor),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Academic Streams:',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Resources',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildStreamProgressBar('Science Stream', streamCounts['Science Stream'] ?? 0, Colors.blue),
            SizedBox(height: 4),
            _buildStreamProgressBar('Arts Stream', streamCounts['Arts Stream'] ?? 0, Colors.purple),
            SizedBox(height: 4),
            _buildStreamProgressBar('Commerce Stream', streamCounts['Commerce Stream'] ?? 0, Colors.green),
            SizedBox(height: 4),
            _buildStreamProgressBar('Technology Stream', streamCounts['Technology Stream'] ?? 0, Colors.orange),
            SizedBox(height: 4),
            _buildStreamProgressBar('O/L', streamCounts['O/L'] ?? 0, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: yellowColor),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: greenColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStreamProgressBar(String stream, int count, Color color) {
    // Calculate percentage
    double percentage = totalResources > 0 ? count / totalResources : 0;

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            stream,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          flex: 5,
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
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Container(
          width: 30,
          alignment: Alignment.centerRight,
          child: Text(
            count.toString(),
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}