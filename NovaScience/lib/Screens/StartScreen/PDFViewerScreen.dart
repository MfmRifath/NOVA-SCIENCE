import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

import 'ResourceUtils.dart';

class PDFViewerScreen extends StatefulWidget {
  final String resourceId;
  final String pdfUrl;
  final String title;
  final Map<String, dynamic> resourceData;

  PDFViewerScreen({
    required this.resourceId,
    required this.pdfUrl,
    required this.title,
    required this.resourceData,
  });

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> with SingleTickerProviderStateMixin {
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  bool _isLoading = true;
  bool _showControls = true;
  bool _hasError = false;
  String? _pdfFilePath;
  String _errorMessage = 'Failed to load PDF';

  int _totalPages = 0;
  int _currentPage = 0;
  double _currentZoom = 1.0;
  bool _isFullScreen = false;
  PDFViewController? _pdfViewController;

  // For tracking download progress
  double _downloadProgress = 0;
  late AnimationController _fadeControllerForControls;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _fadeControllerForControls = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeControllerForControls.value = 1.0; // Start visible
    _loadPDF();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _fadeControllerForControls.dispose();
    super.dispose();
  }

  Future<void> _loadPDF() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get the application's temporary directory
      final dir = await getTemporaryDirectory();

      // Create a simpler file name to avoid path issues
      final fileName = 'pdf_${widget.resourceId}.pdf';
      final filePath = path.join(dir.path, fileName);

      final file = File(filePath);

      // Check if the file already exists
      if (await file.exists()) {
        setState(() {
          _pdfFilePath = filePath;
          _isLoading = false;
        });
        return;
      }

      // Download file with progress
      await _downloadFileWithProgress(widget.pdfUrl, filePath);

      setState(() {
        _pdfFilePath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  Future<void> _downloadFileWithProgress(String url, String savePath) async {
    try {
      // Create a new client
      final client = http.Client();

      // Make a GET request to the URL
      final response = await client.get(Uri.parse(url));

      // Check if the request was successful
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Get the total size of the file
      final totalBytes = response.contentLength ?? response.bodyBytes.length;

      // Ensure the directory exists
      final directory = File(savePath).parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write the file with progress tracking
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);

      // Update progress to complete
      setState(() {
        _downloadProgress = 1.0;
      });

      client.close();
    } catch (e) {
      print('Error downloading file: $e');
      throw e;
    }
  }

  void _resetControlsTimer() {
    // Cancel existing timer if any
    _hideControlsTimer?.cancel();

    // Show controls
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      _fadeControllerForControls.forward();
    }

    // Set new timer to hide controls after 3 seconds
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
        _fadeControllerForControls.reverse();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    // Reset controls timer when toggling fullscreen
    _resetControlsTimer();
  }

  Future<void> _sharePDF() async {
    try {
      if (_pdfFilePath != null) {
        final title = widget.title;
        final category = widget.resourceData['category'] ?? 'Resource';
        final stream = widget.resourceData['stream'] ?? '';

        // Use the share() method instead of shareFiles()
        await Share.share(
          'Check out this $category: $title [$stream]\n${widget.pdfUrl}',
          subject: title,
        );
      }
    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPDF() async {
    try {
      final Uri url = Uri.parse(widget.pdfUrl);

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }

      // Update the view count
      await ResourceUtils.incrementResourceViewCount(widget.resourceId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download started'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error downloading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: _isFullScreen
          ? null
          : AppBar(
        backgroundColor: greenColor,
        title: Text(
          widget.title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _sharePDF,
            tooltip: 'Share',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadPDF,
            tooltip: 'Download',
          ),
          IconButton(
            icon: Icon(Icons.fullscreen),
            onPressed: _toggleFullScreen,
            tooltip: 'Fullscreen',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _resetControlsTimer,
        child: Stack(
          children: [
            // PDF View
            PDFView(
              filePath: _pdfFilePath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages!;
                });
              },
              onError: (error) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                print('Error loading page $page: $error');
              },
              onViewCreated: (PDFViewController viewController) {
                setState(() {
                  _pdfViewController = viewController;
                });
              },
              onPageChanged: (int? page, int? total) {
                if (page != null) {
                  setState(() {
                    _currentPage = page;
                  });
                  // Reset controls timer when page changes
                  _resetControlsTimer();
                }
              },
            ),

            // Floating controls
            FadeTransition(
              opacity: _fadeControllerForControls,
              child: _buildControls(),
            ),

            // Fullscreen exit button
            if (_isFullScreen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: FadeTransition(
                  opacity: _fadeControllerForControls,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),

            // Fullscreen toggle button
            if (_isFullScreen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: FadeTransition(
                  opacity: _fadeControllerForControls,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: _toggleFullScreen,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page counter and zoom level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pages, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '${_currentPage + 1}/$_totalPages',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.zoom_in, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '${(_currentZoom * 100).toInt()}%',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Navigation controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous page button
                IconButton(
                  icon: Icon(Icons.navigate_before, color: Colors.white),
                  iconSize: 36,
                  onPressed: _currentPage > 0
                      ? () {
                    _pdfViewController?.setPage(_currentPage - 1);
                    _resetControlsTimer();
                  }
                      : null,
                ),

                SizedBox(width: 24),

                // Zoom out button
                IconButton(
                  icon: Icon(Icons.zoom_out, color: Colors.white),
                  onPressed: () {
                    // Implement zoom out functionality if needed
                    _resetControlsTimer();
                  },
                ),

                SizedBox(width: 24),

                // Zoom in button
                IconButton(
                  icon: Icon(Icons.zoom_in, color: Colors.white),
                  onPressed: () {
                    // Implement zoom in functionality if needed
                    _resetControlsTimer();
                  },
                ),

                SizedBox(width: 24),

                // Next page button
                IconButton(
                  icon: Icon(Icons.navigate_next, color: Colors.white),
                  iconSize: 36,
                  onPressed: (_totalPages > 0 && _currentPage < _totalPages - 1)
                      ? () {
                    _pdfViewController?.setPage(_currentPage + 1);
                    _resetControlsTimer();
                  }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: greenColor,
        title: Text(
          'Loading PDF',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PDF icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.picture_as_pdf,
                size: 50,
                color: Colors.red.shade700,
              ),
            ),

            SizedBox(height: 24),

            // Loading text
            Text(
              'Loading PDF Document',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),

            SizedBox(height: 8),

            // Loading subtitle
            Text(
              widget.title,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 32),

            // Progress indicator
            Container(
              width: 200,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 200 * _downloadProgress,
                    decoration: BoxDecoration(
                      color: maroonColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Progress text
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: greenColor,
        title: Text(
          'PDF Error',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red.shade700,
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Failed to Load PDF',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),

            SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 32),

            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _loadPDF,
            ),

            SizedBox(height: 16),

            TextButton.icon(
              icon: Icon(Icons.download),
              label: Text('Download Instead'),
              style: TextButton.styleFrom(
                foregroundColor: maroonColor,
              ),
              onPressed: _downloadPDF,
            ),
          ],
        ),
      ),
    );
  }
}