import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'NovaDesignSystem.dart';
import 'ResourceUtils.dart';
import 'ResourceDetailScreen.dart';

// Enhanced design constants
class ResourceTheme {
  // Primary palette
  static const Color primaryColor = Color(0xFF11261F);
  static const Color primaryLight = Color(0xFF1A3A2F);
  static const Color primaryDark = Color(0xFF0A1915);

  // Secondary palette
  static const Color secondaryColor = Color(0xFF123755);
  static const Color secondaryLight = Color(0xFF1A4E7A);
  static const Color secondaryDark = Color(0xFF0B2438);

  // Accent colors
  static const Color accentColor = Color(0xFFE9C46A);
  static const Color accentLight = Color(0xFFF1D78A);
  static const Color accentDark = Color(0xFFD4B155);

  // Tertiary color
  static const Color tertiaryColor = Color(0xFF722626);
  static const Color tertiaryLight = Color(0xFF8C3030);
  static const Color tertiaryDark = Color(0xFF5A1E1E);

  // Background colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF5F5F5F);
  static const Color textHint = Color(0xFF9E9E9E);

  // Status colors
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Gradient backgrounds
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryLight,
      primaryColor,
      primaryDark,
    ],
  );

  static LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentLight.withOpacity(0.8),
      accentColor,
      accentDark,
    ],
  );

  // Typography
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Shadows
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.07),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

  static ButtonStyle get tertiaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: tertiaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: primaryColor, width: 1.5),
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Input decoration
  static InputDecoration getInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      helperText: helperText,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: error, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: shadowSmall,
  );

  // Animation durations
  static Duration get animFast => Duration(milliseconds: 200);
  static Duration get animMedium => Duration(milliseconds: 350);
  static Duration get animSlow => Duration(milliseconds: 500);
}

// Fuzzy search implementation
class FuzzySearch {
  // Calculate Levenshtein distance
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List<int>.filled(b.length + 1, 0);
    List<int> curr = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i <= b.length; i++) {
      prev[i] = i;
    }

    for (int i = 0; i < a.length; i++) {
      curr[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        curr[j + 1] = math.min(
            math.min(curr[j] + 1, prev[j + 1] + 1), prev[j] + cost);
      }

      List<int> temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[b.length];
  }

  // Calculate similarity score (0-100)
  static double calculateSimilarity(String source, String target) {
    if (source.isEmpty && target.isEmpty) return 100.0;

    source = source.toLowerCase();
    target = target.toLowerCase();

    // Exact contains check
    if (source.contains(target) || target.contains(source)) {
      return 95.0;
    }

    // Calculate Levenshtein distance
    int distance = _levenshteinDistance(source, target);
    int maxLength = math.max(source.length, target.length);

    if (maxLength == 0) return 100.0;

    // Convert distance to similarity score
    double similarity = ((maxLength - distance) / maxLength) * 100;

    return similarity;
  }

  // Determine if strings match
  static bool isFuzzyMatch(String source, String query, {double threshold = 70.0}) {
    if (source.isEmpty || query.isEmpty) return false;

    // Split query into words
    List<String> queryWords = query.toLowerCase().split(' ');
    source = source.toLowerCase();

    // Exact match check
    if (source.contains(query.toLowerCase())) return true;

    // Check if all query words appear in source
    bool allWordsPresent = queryWords.every((word) => source.contains(word));
    if (allWordsPresent) return true;

    // For short queries, use fuzzy matching
    if (queryWords.length <= 2) {
      double similarity = calculateSimilarity(source, query);
      return similarity >= threshold;
    }

    // For longer phrases, check word matches
    int matchCount = 0;
    for (String word in queryWords) {
      if (word.length < 3) {
        if (source.contains(word)) matchCount++;
      } else {
        bool wordMatched = false;
        for (String sourceWord in source.split(' ')) {
          double wordSimilarity = calculateSimilarity(sourceWord, word);
          if (wordSimilarity >= threshold) {
            wordMatched = true;
            break;
          }
        }
        if (wordMatched) matchCount++;
      }
    }

    double matchRatio = matchCount / queryWords.length;
    return matchRatio >= 0.6;
  }
}

// Resource model class
class Resource {
  final String id;
  final String title;
  final String description;
  final String uploadedBy;
  final String fileName;
  final String stream;
  final String category;
  final String? subcategory;
  final DateTime uploadDate;
  final int viewCount;
  final double searchRelevance;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.uploadedBy,
    required this.fileName,
    required this.stream,
    required this.category,
    this.subcategory,
    required this.uploadDate,
    required this.viewCount,
    this.searchRelevance = 0.0,
  });

  factory Resource.fromFirestore(DocumentSnapshot doc, {String searchQuery = ''}) {
    final data = doc.data() as Map<String, dynamic>;

    // Calculate search relevance
    double relevance = 0.0;
    if (searchQuery.isNotEmpty) {
      final title = (data['title'] as String?) ?? '';
      final description = (data['description'] as String?) ?? '';
      final uploadedBy = (data['uploadedBy'] as String?) ?? '';
      final fileName = (data['fileName'] as String?) ?? '';

      // Score relevance based on matches
      if (title.toLowerCase().contains(searchQuery.toLowerCase())) {
        relevance += 100;
      } else if (FuzzySearch.isFuzzyMatch(title, searchQuery)) {
        relevance += 80;
      }

      if (description.toLowerCase().contains(searchQuery.toLowerCase())) {
        relevance += 50;
      }

      if (uploadedBy.toLowerCase().contains(searchQuery.toLowerCase())) {
        relevance += 30;
      }

      if (fileName.toLowerCase().contains(searchQuery.toLowerCase())) {
        relevance += 40;
      }
    }

    return Resource(
      id: doc.id,
      title: data['title'] ?? 'Untitled Resource',
      description: data['description'] ?? '',
      uploadedBy: data['uploadedBy'] ?? 'Unknown',
      fileName: data['fileName'] ?? 'Unknown File',
      stream: data['stream'] ?? 'Unknown Stream',
      category: data['category'] ?? 'Uncategorized',
      subcategory: data['subcategory'],
      uploadDate: (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['viewCount'] ?? 0,
      searchRelevance: relevance,
    );
  }
}

class ResourceScreen extends StatefulWidget {
  @override
  _ResourceScreenState createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> with TickerProviderStateMixin {
  // App state
  bool isAdmin = false;
  bool isLoading = true;
  bool isFilterVisible = false;
  String searchQuery = '';

  // Enhanced search state
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  bool isSearchFocused = false;
  bool isAdvancedSearch = false;
  List<String> recentSearches = [];
  List<String> searchSuggestions = [];
  bool showRecentSearches = false;

  // Advanced search options
  bool searchInTitles = true;
  bool searchInDescriptions = true;
  bool searchInUploaders = true;
  bool searchInFileNames = true;
  bool useFuzzySearch = true;

  // Scroll controller
  final ScrollController scrollController = ScrollController();
  bool showScrollToTop = false;

  // Resource filters
  String selectedStream = 'All Resources';
  String selectedCategory = 'All Categories';
  String? selectedSubcategory;

  // Sort options
  String sortOption = 'Newest First';
  List<String> sortOptions = [
    'Newest First',
    'Oldest First',
    'Most Viewed',
    'Title A-Z',
    'Title Z-A',
    'Search Relevance',
  ];

  // Resource data
  List<Resource>? resources;
  bool isLoadingResources = false;
  bool hasMoreResources = true;
  int resourceBatchSize = 15;
  DocumentSnapshot? lastDocument;

  // Stream and category data
  final Map<String, IconData> streamIcons = {
    'All Resources': Icons.folder,
    'Science Stream': Icons.science,
    'Arts Stream': Icons.color_lens,
    'Commerce Stream': Icons.assessment,
    'Technology Stream': Icons.computer,
    'O/L': Icons.school,
  };

  final Map<String, Color> streamColors = {
    'All Resources': Colors.grey,
    'Science Stream': Colors.blue.shade700,
    'Arts Stream': Colors.purple.shade700,
    'Commerce Stream': Colors.green.shade700,
    'Technology Stream': Colors.orange.shade700,
    'O/L': Colors.red.shade700,
  };

  final Map<String, IconData> categoryIcons = {
    'All Categories': Icons.folder,
    'Exam Papers': Icons.description,
    'Notes': Icons.note,
    'Tutorials': Icons.school,
    'Books': Icons.book,
    'Other Materials': Icons.insert_drive_file,
  };

  final Map<String, Color> categoryColors = {
    'All Categories': Colors.grey,
    'Exam Papers': Colors.blue.shade700,
    'Notes': Colors.green.shade700,
    'Tutorials': Colors.orange.shade700,
    'Books': Colors.purple.shade700,
    'Other Materials': Colors.grey.shade700,
  };

  // Subcategories for exam papers
  final Map<String, IconData> subcategoryIcons = {
    'All Exam Papers': Icons.description,
    'Term Papers': Icons.assignment,
    'Model Papers': Icons.model_training,
    'Past Papers': Icons.history_edu,
    'Term Paper Keys': Icons.key,
    'Past Paper Keys': Icons.vpn_key,
  };

  // Debounce timer for search
  DateTime? _lastSearchTime;
  static const searchDebounceTime = Duration(milliseconds: 500);

  // Animation controllers
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;

  late AnimationController _filtersAnimationController;
  late Animation<double> _filtersAnimation;

  late AnimationController _highlightAnimationController;
  late Animation<double> _highlightAnimation;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _searchAnimationController = AnimationController(
      duration: ResourceTheme.animMedium,
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    _filtersAnimationController = AnimationController(
      duration: ResourceTheme.animMedium,
      vsync: this,
    );
    _filtersAnimation = CurvedAnimation(
      parent: _filtersAnimationController,
      curve: Curves.easeInOut,
    );

    _highlightAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightAnimationController,
      curve: Curves.easeInOut,
    );
    _highlightAnimationController.repeat(reverse: true);

    _fabAnimationController = AnimationController(
      duration: ResourceTheme.animMedium,
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();

    // Set up focus listener for search field
    searchFocusNode.addListener(() {
      setState(() {
        isSearchFocused = searchFocusNode.hasFocus;
        showRecentSearches = isSearchFocused && searchQuery.isEmpty;
      });
      if (isSearchFocused) {
        _searchAnimationController.forward();
      } else if (searchQuery.isEmpty) {
        _searchAnimationController.reverse();
        showRecentSearches = false;
      }
    });

    // Check user role
    _checkUserRole();

    // Set up scroll listener for lazy loading and scroll-to-top button
    scrollController.addListener(() {
      setState(() {
        showScrollToTop = scrollController.offset > 300;
      });

      // Lazy loading when close to bottom
      if (scrollController.position.pixels >
          scrollController.position.maxScrollExtent - 500 &&
          !isLoadingResources &&
          hasMoreResources) {
        _loadMoreResources();
      }
    });

    // Load saved recent searches
    _loadRecentSearches();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    _searchAnimationController.dispose();
    _filtersAnimationController.dispose();
    _highlightAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Load recent searches from local storage
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    } catch (e) {
      // Fallback if shared preferences fail
      setState(() {
        recentSearches = ['Physics notes', 'Past papers', 'Mathematics', 'Biology'];
      });
    }
  }

  // Save search query to recent searches
  Future<void> _saveSearchQuery(String query) async {
    if (query.isEmpty || recentSearches.contains(query)) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Remove the query if it already exists (to move it to the top)
        recentSearches.remove(query);
        // Add the new query at the beginning
        recentSearches.insert(0, query);
        // Limit to 10 recent searches
        if (recentSearches.length > 10) {
          recentSearches = recentSearches.sublist(0, 10);
        }
      });

      // Save to shared preferences
      await prefs.setStringList('recent_searches', recentSearches);
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  // Clear all recent searches
  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store the current searches for undo
      await prefs.setStringList('prev_recent_searches', recentSearches);
      await prefs.remove('recent_searches');

      setState(() {
        recentSearches = [];
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search history cleared'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: ResourceTheme.primaryColor,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: ResourceTheme.accentColor,
            onPressed: () async {
              // Restore the previous recent searches
              final prevSearches = prefs.getStringList('prev_recent_searches');
              if (prevSearches != null) {
                setState(() {
                  recentSearches = prevSearches;
                });
                await prefs.setStringList('recent_searches', prevSearches);
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  // Get search suggestions based on current query
  List<String> _getSearchSuggestions(String query) {
    if (query.isEmpty) return [];

    // Generate suggestions
    final List<String> allSuggestions = [
      ...recentSearches,
      // Common search terms
      'Past Papers',
      'Exam Papers',
      'Notes',
      'Mathematics',
      'Science',
      'Biology',
      'Physics',
      'Chemistry',
      'History',
      'Term Papers',
      'Model Papers',
      'Tutorials',
      'Reference Books',
    ];

    // Filter suggestions
    return allSuggestions
        .where((suggestion) => suggestion.toLowerCase().contains(query.toLowerCase()))
        .toSet() // Remove duplicates
        .toList();
  }

  // Check user role for admin privileges
  Future<void> _checkUserRole() async {
    setState(() {
      isLoading = true;
    });

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
    } finally {
      setState(() {
        isLoading = false;
      });
      // Load resources after checking role
      _loadResources();
    }
  }

  // Load resources with filtering
  void _loadResources() {
    setState(() {
      isLoadingResources = true;
      resources = null; // Clear existing resources
      lastDocument = null;
      hasMoreResources = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('resources');

      // Apply stream filter
      if (selectedStream != 'All Resources') {
        query = query.where('stream', isEqualTo: selectedStream);
      }

      // Apply category filter
      if (selectedCategory != 'All Categories') {
        query = query.where('category', isEqualTo: selectedCategory);

        // Apply subcategory filter
        if (selectedCategory == 'Exam Papers' &&
            selectedSubcategory != null &&
            selectedSubcategory != 'All Exam Papers') {
          query = query.where('subcategory', isEqualTo: selectedSubcategory);
        }
      }

      // Apply sorting
      query = _applySorting(query);

      // Adjust batch size for search queries
      int queryLimit = searchQuery.isNotEmpty ? resourceBatchSize * 3 : resourceBatchSize;
      query = query.limit(queryLimit);

      // Get the resources
      query.get().then((snapshot) {
        if (searchQuery.isNotEmpty) {
          // Process with search relevance
          List<Resource> allResources = snapshot.docs.map((doc) =>
              Resource.fromFirestore(doc, searchQuery: searchQuery)).toList();

          // Apply advanced search filtering
          List<Resource> filteredResources = _filterResourcesBySearchCriteria(allResources);

          // Sort by relevance if needed
          if (sortOption == 'Search Relevance') {
            filteredResources.sort((a, b) => b.searchRelevance.compareTo(a.searchRelevance));
          }

          setState(() {
            resources = filteredResources;
            isLoadingResources = false;

            // Set lastDocument for pagination
            if (snapshot.docs.isNotEmpty) {
              lastDocument = snapshot.docs.last;
            }

            hasMoreResources = snapshot.docs.length >= queryLimit;
          });

          // If search returned no results, try secondary search
          if (filteredResources.isEmpty) {
            _performSecondarySearch();
          }
        } else {
          // No search query, convert all results
          final List<Resource> loadedResources = snapshot.docs
              .map((doc) => Resource.fromFirestore(doc))
              .toList();

          setState(() {
            resources = loadedResources;
            isLoadingResources = false;

            if (snapshot.docs.isNotEmpty) {
              lastDocument = snapshot.docs.last;
            }

            hasMoreResources = snapshot.docs.length >= resourceBatchSize;
          });
        }
      }).catchError((error) {
        print('Error loading resources: $error');
        setState(() {
          resources = [];
          isLoadingResources = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading resources: $error'),
            backgroundColor: ResourceTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });
    } catch (e) {
      print('Error building query: $e');
      setState(() {
        resources = [];
        isLoadingResources = false;
      });
    }
  }

  // Filter resources based on search criteria
  List<Resource> _filterResourcesBySearchCriteria(List<Resource> resources) {
    if (searchQuery.isEmpty) return resources;

    return resources.where((resource) {
      // Check against different fields based on search settings
      if (searchInTitles) {
        if (useFuzzySearch) {
          if (FuzzySearch.isFuzzyMatch(resource.title, searchQuery)) {
            return true;
          }
        } else if (resource.title.toLowerCase().contains(searchQuery.toLowerCase())) {
          return true;
        }
      }

      if (searchInDescriptions && resource.description.isNotEmpty) {
        if (useFuzzySearch) {
          if (FuzzySearch.isFuzzyMatch(resource.description, searchQuery)) {
            return true;
          }
        } else if (resource.description.toLowerCase().contains(searchQuery.toLowerCase())) {
          return true;
        }
      }

      if (searchInUploaders && resource.uploadedBy.isNotEmpty) {
        if (useFuzzySearch) {
          if (FuzzySearch.isFuzzyMatch(resource.uploadedBy, searchQuery)) {
            return true;
          }
        } else if (resource.uploadedBy.toLowerCase().contains(searchQuery.toLowerCase())) {
          return true;
        }
      }

      if (searchInFileNames && resource.fileName.isNotEmpty) {
        if (useFuzzySearch) {
          if (FuzzySearch.isFuzzyMatch(resource.fileName, searchQuery)) {
            return true;
          }
        } else if (resource.fileName.toLowerCase().contains(searchQuery.toLowerCase())) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  // Secondary search for broader matches
  void _performSecondarySearch() {
    if (searchQuery.isEmpty) return;

    // Get a larger batch of resources
    FirebaseFirestore.instance
        .collection('resources')
        .limit(resourceBatchSize * 5)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // Convert to Resource objects with search relevance
        List<Resource> allResources = snapshot.docs.map((doc) =>
            Resource.fromFirestore(doc, searchQuery: searchQuery)).toList();

        // Apply fuzzy search with relaxed thresholds
        List<Resource> additionalMatches = allResources.where((resource) {
          // Skip resources we already have
          if (resources != null) {
            for (var existingResource in resources!) {
              if (existingResource.id == resource.id) return false;
            }
          }

          // Do a more lenient fuzzy search
          if (FuzzySearch.isFuzzyMatch(resource.title, searchQuery, threshold: 60.0)) {
            return true;
          }

          if (FuzzySearch.isFuzzyMatch(resource.description, searchQuery, threshold: 60.0)) {
            return true;
          }

          if (FuzzySearch.isFuzzyMatch(resource.uploadedBy, searchQuery, threshold: 60.0)) {
            return true;
          }

          if (FuzzySearch.isFuzzyMatch(resource.fileName, searchQuery, threshold: 60.0)) {
            return true;
          }

          return false;
        }).toList();

        if (additionalMatches.isNotEmpty) {
          // Sort by relevance
          additionalMatches.sort((a, b) => b.searchRelevance.compareTo(a.searchRelevance));

          setState(() {
            resources = (resources ?? []) + additionalMatches;

            if (snapshot.docs.isNotEmpty) {
              lastDocument = snapshot.docs.last;
            }

            hasMoreResources = snapshot.docs.length >= resourceBatchSize * 5;
          });

          // Show result notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Found ${resources!.length} resources that might match "${searchQuery}"'),
                ],
              ),
              backgroundColor: ResourceTheme.success,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if ((resources?.length ?? 0) == 0) {
          // If we still found nothing, suggest spelling correction
          _suggestSpellingCorrection();
        }
      }
    });
  }

  // Suggest spelling correction
  void _suggestSpellingCorrection() {
    // List of common academic terms
    final List<String> commonTerms = [
      'Mathematics', 'Math', 'Physics', 'Chemistry', 'Biology',
      'History', 'English', 'Geography', 'Science', 'Computer',
      'Economics', 'Business', 'Accounting', 'Notes', 'Paper',
      'Exam', 'Test', 'Quiz', 'Assignment', 'Homework', 'Project',
      'Tutorial', 'Guide', 'Book', 'Textbook', 'Reference',
      'Model', 'Past', 'Term', 'Answer', 'Solution', 'Key', 'Formula'
    ];

    // Find potential corrections
    List<Map<String, dynamic>> potentialCorrections = [];

    for (String term in commonTerms) {
      double similarity = FuzzySearch.calculateSimilarity(term.toLowerCase(), searchQuery.toLowerCase());
      if (similarity >= 60.0) {
        potentialCorrections.add({
          'term': term,
          'similarity': similarity,
        });
      }
    }

    // Sort corrections by similarity
    potentialCorrections.sort((a, b) => b['similarity'].compareTo(a['similarity']));

    // If we have potential corrections, suggest the top one
    if (potentialCorrections.isNotEmpty) {
      final String suggestedTerm = potentialCorrections.first['term'];

      // Show suggestion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber),
              SizedBox(width: 8),
              Text('Did you mean "$suggestedTerm"?'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: ResourceTheme.primaryDark,
          action: SnackBarAction(
            label: 'SEARCH',
            textColor: ResourceTheme.accentColor,
            onPressed: () {
              // Apply the suggestion
              setState(() {
                searchController.text = suggestedTerm;
                searchQuery = suggestedTerm;
              });
              _loadResources();
            },
          ),
        ),
      );
    }
  }

  // Load more resources for infinite scrolling
  void _loadMoreResources() {
    if (!hasMoreResources || isLoadingResources || lastDocument == null) return;

    setState(() {
      isLoadingResources = true;
    });

    Query query = FirebaseFirestore.instance.collection('resources');

    // Apply filters
    if (selectedStream != 'All Resources') {
      query = query.where('stream', isEqualTo: selectedStream);
    }

    if (selectedCategory != 'All Categories') {
      query = query.where('category', isEqualTo: selectedCategory);

      if (selectedCategory == 'Exam Papers' &&
          selectedSubcategory != null &&
          selectedSubcategory != 'All Exam Papers') {
        query = query.where('subcategory', isEqualTo: selectedSubcategory);
      }
    }

    // Apply sorting
    query = _applySorting(query);

    // Start after the last document
    query = query.startAfterDocument(lastDocument!);

    // Adjust batch size for search
    int queryLimit = searchQuery.isNotEmpty ? resourceBatchSize * 3 : resourceBatchSize;
    query = query.limit(queryLimit);

    // Get more resources
    query.get().then((snapshot) {
      if (searchQuery.isNotEmpty) {
        // Process with search relevance
        List<Resource> allResources = snapshot.docs.map((doc) =>
            Resource.fromFirestore(doc, searchQuery: searchQuery)).toList();

        // Apply search filtering
        List<Resource> filteredResources = _filterResourcesBySearchCriteria(allResources);

        // Sort by relevance if needed
        if (sortOption == 'Search Relevance') {
          filteredResources.sort((a, b) => b.searchRelevance.compareTo(a.searchRelevance));
        }

        setState(() {
          // Add new resources
          resources = (resources ?? []) + filteredResources;
          isLoadingResources = false;

          if (snapshot.docs.isNotEmpty) {
            lastDocument = snapshot.docs.last;
          }

          hasMoreResources = snapshot.docs.length >= queryLimit;
        });
      } else {
        // No search query
        final List<Resource> loadedResources = snapshot.docs
            .map((doc) => Resource.fromFirestore(doc))
            .toList();

        setState(() {
          resources = (resources ?? []) + loadedResources;
          isLoadingResources = false;

          if (snapshot.docs.isNotEmpty) {
            lastDocument = snapshot.docs.last;
          }

          hasMoreResources = snapshot.docs.length >= resourceBatchSize;
        });
      }
    }).catchError((error) {
      print('Error loading more resources: $error');
      setState(() {
        isLoadingResources = false;
      });
    });
  }

  // Apply sorting to query
  Query _applySorting(Query query) {
    switch (sortOption) {
      case 'Newest First':
        return query.orderBy('uploadDate', descending: true);
      case 'Oldest First':
        return query.orderBy('uploadDate', descending: false);
      case 'Most Viewed':
        return query.orderBy('viewCount', descending: true);
      case 'Title A-Z':
        return query.orderBy('title', descending: false);
      case 'Title Z-A':
        return query.orderBy('title', descending: true);
      case 'Search Relevance':
      // For relevance sorting, we need a consistent base ordering
        return query.orderBy('uploadDate', descending: true);
      default:
        return query.orderBy('uploadDate', descending: true);
    }
  }

  // Handle search query changes with debounce
  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      showRecentSearches = isSearchFocused && value.isEmpty;

      // Update search suggestions
      if (value.isNotEmpty) {
        searchSuggestions = _getSearchSuggestions(value);
      } else {
        searchSuggestions = [];
      }
    });

    final now = DateTime.now();
    _lastSearchTime = now;

    Future.delayed(searchDebounceTime, () {
      // Only reload if this is still the most recent request
      if (_lastSearchTime == now) {
        _loadResources();
        if (value.isNotEmpty) {
          _saveSearchQuery(value);
        }
      }
    });
  }

  // Handle search suggestion selection
  void _onSearchSuggestionSelected(String suggestion) {
    setState(() {
      searchController.text = suggestion;
      searchQuery = suggestion;
      searchSuggestions = [];
      showRecentSearches = false;
    });
    _loadResources();
    _saveSearchQuery(suggestion);
    searchFocusNode.unfocus();
  }

  // Toggle advanced search options
  void _toggleAdvancedSearch() {
    setState(() {
      isAdvancedSearch = !isAdvancedSearch;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: ResourceTheme.backgroundColor,
      body: Stack(
        children: [
          // Main content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 160.0,
                  floating: true,
                  pinned: true,
                  backgroundColor: ResourceTheme.primaryColor,
                  elevation: 4,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: ResourceTheme.primaryGradient,
                      ),
                      child: Stack(
                        children: [
                          // Decorative pattern overlay


                          // Decorative elements
                          Positioned(
                            top: -20,
                            right: -30,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color:  ResourceTheme.accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: -40,
                            left: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: ResourceTheme.tertiaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // Title and subtitle
                          Positioned(
                            top: 105,
                            left: 38,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resource Center',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Find educational materials and resources',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Search bar
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20,
                            child: AnimatedContainer(
                              duration: ResourceTheme.animMedium,
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: ResourceTheme.shadowMedium,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildEnhancedSearchBar(),

                                  // Advanced search options expander
                                  AnimatedContainer(
                                    duration: ResourceTheme.animMedium,
                                    height: isAdvancedSearch ? 100 : 0,
                                    color: Colors.white,
                                    child: SingleChildScrollView(
                                      physics: NeverScrollableScrollPhysics(),
                                      child: _buildAdvancedSearchOptions(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  actions: [
                    // Filter button
                    IconButton(
                      icon: Icon(
                        isFilterVisible ? Icons.filter_list_off : Icons.filter_list,
                        color: Colors.white,
                      ),
                      tooltip: isFilterVisible ? 'Hide filters' : 'Show filters',
                      onPressed: () {
                        setState(() {
                          isFilterVisible = !isFilterVisible;
                          if (isFilterVisible) {
                            _filtersAnimationController.forward();
                          } else {
                            _filtersAnimationController.reverse();
                          }
                        });
                      },
                    ),
                    // Admin actions
                    if (isAdmin)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.white),
                        tooltip: 'More options',
                        onSelected: (value) {
                          if (value == 'add') {
                            _showAddResourceDialog(context);
                          } else if (value == 'dashboard') {
                            Navigator.pushNamed(context, '/resource_management');
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'add',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: ResourceTheme.tertiaryColor),
                                SizedBox(width: 12),
                                Text('Add Resource'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'dashboard',
                            child: Row(
                              children: [
                                Icon(Icons.dashboard_outlined, color: ResourceTheme.secondaryColor),
                                SizedBox(width: 12),
                                Text('Resource Dashboard'),
                              ],
                            ),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                  ],
                ),

                // Filter section
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverFilterDelegate(
                    minHeight: isFilterVisible ? 160 : 0,
                    maxHeight: isFilterVisible ? 160 : 0,
                    child: AnimatedContainer(
                      duration:ResourceTheme.animMedium,
                      height: isFilterVisible ? 160 : 0,
                      color: Colors.white,
                      child: Opacity(
                        opacity: _filtersAnimation.value,
                        child: SingleChildScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          child: _buildEnhancedFilters(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Active filters chip display
                if (_hasActiveFilters() && !isFilterVisible)
                  SliverPersistentHeader(
                    pinned: false,
                    floating: true,
                    delegate: _SliverFilterDelegate(
                      minHeight: 60,
                      maxHeight: 60,
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildActiveFiltersChips(),
                      ),
                    ),
                  ),
              ];
            },
            body: _buildResourceList(),
          ),

          // Search suggestions overlay
          if (showRecentSearches || searchSuggestions.isNotEmpty)
            Positioned(
              top: 170, // Position below search bar
              left: 20,
              right: 20,
              child: AnimatedContainer(
                duration: ResourceTheme.animFast,
                curve: Curves.easeOutQuint,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ResourceTheme.shadowMedium,
                ),
                child: _buildSearchSuggestionsPanel(),
              ),
            ),

          // Floating action buttons
          AnimatedPositioned(
            duration: ResourceTheme.animMedium,
            curve: Curves.easeInOut,
            right: 16,
            bottom: 16,
            child: _buildFloatingActionButtons(),
          ),
        ],
      ),
    );
  }

  // Enhanced search bar
  Widget _buildEnhancedSearchBar() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            style: ResourceTheme.bodyLarge.copyWith(color: ResourceTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search for resources...',
              hintStyle: TextStyle(color: ResourceTheme.textHint, fontStyle: FontStyle.italic),
              prefixIcon: Icon(
                Icons.search,
                color: isSearchFocused ? ResourceTheme.tertiaryColor : Colors.grey.shade500,
                size: 24,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voice search icon
                  if (isSearchFocused && searchController.text.isEmpty)
                    IconButton(
                      icon: Icon(Icons.keyboard_voice, color: ResourceTheme.tertiaryColor),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Voice search not implemented'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      splashRadius: 24,
                    ),
                  // Clear text icon
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          searchQuery = '';
                          _loadResources();
                        });
                      },
                      splashRadius: 24,
                    ),
                  // Advanced search toggle
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: ResourceTheme.animFast,
                      child: Icon(
                        isAdvancedSearch ? Icons.tune : Icons.tune_outlined,
                        key: ValueKey(isAdvancedSearch),
                        color: isAdvancedSearch ? ResourceTheme.tertiaryColor : Colors.grey.shade600,
                      ),
                    ),
                    tooltip: 'Advanced search options',
                    onPressed: _toggleAdvancedSearch,
                    splashRadius: 24,
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ResourceTheme.tertiaryColor, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: _onSearchChanged,
            onTap: () {
              if (!isSearchFocused) {
                searchFocusNode.requestFocus();
              }
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _loadResources();
              if (value.isNotEmpty) {
                _saveSearchQuery(value);
              }
              searchFocusNode.unfocus();
            },
          ),
        ],
      ),
    );
  }

  // Advanced search options panel
  Widget _buildAdvancedSearchOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),
          Row(
            children: [
              Icon(Icons.search, size: 16, color: ResourceTheme.tertiaryDark),
              SizedBox(width: 8),
              Text(
                'Search In:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ResourceTheme.tertiaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAdvancedSearchOption(
                label: 'Titles',
                value: searchInTitles,
                onChanged: (value) {
                  setState(() {
                    searchInTitles = value;
                    if (searchQuery.isNotEmpty) {
                      _loadResources();
                    }
                  });
                },
              ),
              _buildAdvancedSearchOption(
                label: 'Descriptions',
                value: searchInDescriptions,
                onChanged: (value) {
                  setState(() {
                    searchInDescriptions = value;
                    if (searchQuery.isNotEmpty) {
                      _loadResources();
                    }
                  });
                },
              ),
              _buildAdvancedSearchOption(
                label: 'Uploaders',
                value: searchInUploaders,
                onChanged: (value) {
                  setState(() {
                    searchInUploaders = value;
                    if (searchQuery.isNotEmpty) {
                      _loadResources();
                    }
                  });
                },
              ),
              _buildAdvancedSearchOption(
                label: 'Filenames',
                value: searchInFileNames,
                onChanged: (value) {
                  setState(() {
                    searchInFileNames = value;
                    if (searchQuery.isNotEmpty) {
                      _loadResources();
                    }
                  });
                },
              ),
              _buildAdvancedSearchOption(
                label: 'Fuzzy Match',
                value: useFuzzySearch,
                onChanged: (value) {
                  setState(() {
                    useFuzzySearch = value;
                    if (searchQuery.isNotEmpty) {
                      _loadResources();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Check if there are active filters
  bool _hasActiveFilters() {
    return selectedStream != 'All Resources' ||
        selectedCategory != 'All Categories' ||
        (selectedCategory == 'Exam Papers' &&
            selectedSubcategory != null &&
            selectedSubcategory != 'All Exam Papers') ||
        sortOption != 'Newest First';
  }

  // Enhanced filters panel
  Widget _buildEnhancedFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_alt, size: 20, color: ResourceTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Filter Resources',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ResourceTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    isFilterVisible = false;
                    _filtersAnimationController.reverse();
                  });
                },
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
          SizedBox(height: 16),

          // Filter options in a grid layout
          Row(
            children: [
              Expanded(
                child: _buildFilterCard(
                  title: 'Stream',
                  currentValue: selectedStream,
                  icon: _getIconForStream(selectedStream),
                  color: _getColorForStream(selectedStream),
                  onTap: () => _showFilterOptionsDialog(
                    title: 'Select Stream',
                    options: streamIcons.keys.toList(),
                    getIcon: (item) => streamIcons[item] ?? Icons.folder,
                    getColor: (item) => streamColors[item] ?? Colors.grey,
                    currentSelection: selectedStream,
                    onSelected: (value) {
                      setState(() {
                        selectedStream = value;
                        _loadResources();
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterCard(
                  title: 'Category',
                  currentValue: selectedCategory,
                  icon: _getIconForCategory(selectedCategory),
                  color: _getColorForCategory(selectedCategory),
                  onTap: () => _showFilterOptionsDialog(
                    title: 'Select Category',
                    options: categoryIcons.keys.toList(),
                    getIcon: (item) => categoryIcons[item] ?? Icons.folder,
                    getColor: (item) => categoryColors[item] ?? Colors.grey,
                    currentSelection: selectedCategory,
                    onSelected: (value) {
                      setState(() {
                        selectedCategory = value;
                        selectedSubcategory = 'All Exam Papers';
                        _loadResources();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              if (selectedCategory == 'Exam Papers')
                Expanded(
                  child: _buildFilterCard(
                    title: 'Paper Type',
                    currentValue: selectedSubcategory ?? 'All Exam Papers',
                    icon: subcategoryIcons[selectedSubcategory ?? 'All Exam Papers'] ?? Icons.description,
                    color: Colors.blue.shade700,
                    onTap: () => _showFilterOptionsDialog(
                      title: 'Select Paper Type',
                      options: subcategoryIcons.keys.toList(),
                      getIcon: (item) => subcategoryIcons[item] ?? Icons.description,
                      getColor: (item) => Colors.blue.shade700,
                      currentSelection: selectedSubcategory ?? 'All Exam Papers',
                      onSelected: (value) {
                        setState(() {
                          selectedSubcategory = value;
                          _loadResources();
                        });
                      },
                    ),
                  ),
                )
              else
                Expanded(child: SizedBox()), // Placeholder for layout balance
              SizedBox(width: 12),
              Expanded(
                child: _buildFilterCard(
                  title: 'Sort By',
                  currentValue: sortOption,
                  icon: _getIconForSortOption(sortOption),
                  color: ResourceTheme.tertiaryColor,
                  onTap: () => _showFilterOptionsDialog(
                    title: 'Sort Resources By',
                    options: sortOptions,
                    getIcon: (item) => _getIconForSortOption(item),
                    getColor: (item) => ResourceTheme.tertiaryColor,
                    currentSelection: sortOption,
                    onSelected: (value) {
                      setState(() {
                        sortOption = value;
                        _loadResources();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Filter card widget
  Widget _buildFilterCard({
    required String title,
    required String currentValue,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentValue,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ResourceTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Show filter options dialog
  void _showFilterOptionsDialog({
    required String title,
    required List<String> options,
    required IconData Function(String) getIcon,
    required Color Function(String) getColor,
    required String currentSelection,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ResourceTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(),

              // Options list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == currentSelection;

                    return Material(
                      color: isSelected ? Colors.green.withOpacity(0.05) : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onSelected(option);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: getColor(option).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  getIcon(option),
                                  size: 18,
                                  color: getColor(option),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? getColor(option) : ResourceTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: getColor(option),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper to get icon for stream
  IconData _getIconForStream(String stream) {
    return streamIcons[stream] ?? Icons.folder;
  }

  // Helper to get color for stream
  Color _getColorForStream(String stream) {
    return streamColors[stream] ?? Colors.grey;
  }

  // Helper to get icon for category
  IconData _getIconForCategory(String category) {
    return categoryIcons[category] ?? Icons.folder;
  }

  // Helper to get color for category
  Color _getColorForCategory(String category) {
    return categoryColors[category] ?? Colors.grey;
  }

  // Helper to get icon for sort option
  IconData _getIconForSortOption(String option) {
    switch (option) {
      case 'Newest First': return Icons.arrow_downward;
      case 'Oldest First': return Icons.arrow_upward;
      case 'Most Viewed': return Icons.visibility;
      case 'Title A-Z': return Icons.sort_by_alpha;
      case 'Title Z-A': return Icons.sort_by_alpha;
      case 'Search Relevance': return Icons.star;
      default: return Icons.sort;
    }
  }

  // Active filters chips display
  Widget _buildActiveFiltersChips() {
    return Row(
      children: [
        Icon(Icons.filter_list, size: 16, color: ResourceTheme.primaryColor),
        SizedBox(width: 8),
        Text(
          'Active Filters:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ResourceTheme.primaryColor,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (selectedStream != 'All Resources')
                  _buildFilterChip(
                    label: selectedStream,
                    icon: streamIcons[selectedStream] ?? Icons.folder,
                    color: streamColors[selectedStream] ?? Colors.grey,
                    onTap: () {
                      setState(() {
                        selectedStream = 'All Resources';
                        _loadResources();
                      });
                    },
                  ),
                if (selectedCategory != 'All Categories')
                  _buildFilterChip(
                    label: selectedCategory,
                    icon: categoryIcons[selectedCategory] ?? Icons.folder,
                    color: categoryColors[selectedCategory] ?? Colors.grey,
                    onTap: () {
                      setState(() {
                        selectedCategory = 'All Categories';
                        selectedSubcategory = null;
                        _loadResources();
                      });
                    },
                  ),
                if (selectedCategory == 'Exam Papers' &&
                    selectedSubcategory != null &&
                    selectedSubcategory != 'All Exam Papers')
                  _buildFilterChip(
                    label: selectedSubcategory!,
                    icon: subcategoryIcons[selectedSubcategory] ?? Icons.description,
                    color: Colors.blue.shade700,
                    onTap: () {
                      setState(() {
                        selectedSubcategory = 'All Exam Papers';
                        _loadResources();
                      });
                    },
                  ),
                if (sortOption != 'Newest First')
                  _buildFilterChip(
                    label: 'Sort: $sortOption',
                    icon: _getIconForSortOption(sortOption),
                    color: ResourceTheme.tertiaryColor,
                    onTap: () {
                      setState(() {
                        sortOption = 'Newest First';
                        _loadResources();
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        if (_hasActiveFilters())
          TextButton(
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: 12,
                color: ResourceTheme.tertiaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(60, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              setState(() {
                selectedStream = 'All Resources';
                selectedCategory = 'All Categories';
                selectedSubcategory = null;
                sortOption = 'Newest First';
                _loadResources();
              });
            },
          ),
      ],
    );
  }

  // Enhanced filter chip
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: color.withOpacity(0.1),
            labelPadding: EdgeInsets.symmetric(horizontal: 2),
            avatar: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(2),
              child: Icon(icon, size: 14, color: color),
            ),
            label: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            deleteIcon: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: color),
            ),
            onDeleted: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withOpacity(0.3)),
            ),
          ),
        ),
      ),
    );
  }

  // Search suggestions panel
  Widget _buildSearchSuggestionsPanel() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRecentSearches && recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: ResourceTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Recent Searches',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ResourceTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: ResourceTheme.tertiaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _clearRecentSearches,
                  ),
                ],
              ),
            ),
            AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: math.min(5, recentSearches.length),
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: Duration(milliseconds: 200),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.history, color: Colors.grey.shade500),
                          title: Text(
                            recentSearches[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onSearchSuggestionSelected(recentSearches[index]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (searchSuggestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: ResourceTheme.tertiaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ResourceTheme.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimationLimiter(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: math.min(5, searchSuggestions.length),
                itemBuilder: (context, index) {
                  final suggestion = searchSuggestions[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: Duration(milliseconds: 200),
                    child: SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.search, color: ResourceTheme.tertiaryColor),
                          title: Text(
                            suggestion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onSearchSuggestionSelected(suggestion),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 12),
        ],
      ),
    );
  }

  // Advanced search option toggle
  Widget _buildAdvancedSearchOption({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return AnimatedContainer(
      duration: ResourceTheme.animFast,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: value ? ResourceTheme.tertiaryColor.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: value ? ResourceTheme.tertiaryColor.withOpacity(0.5) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: ResourceTheme.animFast,
                child: value
                    ? Icon(
                  Icons.check_circle,
                  key: ValueKey('checked'),
                  size: 16,
                  color: ResourceTheme.tertiaryColor,
                )
                    : Icon(
                  Icons.circle_outlined,
                  key: ValueKey('unchecked'),
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: value ? ResourceTheme.tertiaryColor : Colors.grey.shade700,
                  fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading screen with animation
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: ResourceTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: ResourceTheme.shadowMedium,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated loading indicator
                  SpinKitChasingDots(color: Color(0xff722626),),
                  SizedBox(height: 16),
                  Text(
                    'Loading Resources',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ResourceTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Resource list with animations and loading states
  Widget _buildResourceList() {
    if (isLoadingResources && resources == null) {
      return _buildResourcesLoadingState();
    }

    if (resources == null || resources!.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            !isLoadingResources &&
            hasMoreResources) {
          _loadMoreResources();
        }
        return true;
      },
      child: AnimationLimiter(
        child: ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: resources!.length + (hasMoreResources ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == resources!.length) {
              return _buildBottomLoader();
            }

            final resource = resources![index];

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildResourceItem(resource),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading effect for resources
  Widget _buildResourcesLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              height: 12,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Bottom loader animation for infinite scrolling
  Widget _buildBottomLoader() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ResourceTheme.tertiaryColor),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Loading more resources...',
            style: TextStyle(
              fontSize: 14,
              color: ResourceTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced resource item card
  Widget _buildResourceItem(Resource resource) {
    // Determine icon and color
    IconData resourceIcon = categoryIcons[resource.category] ?? Icons.insert_drive_file;
    Color resourceColor = categoryColors[resource.category] ?? Colors.grey;

    if (resource.category == 'Exam Papers' && resource.subcategory != null) {
      resourceIcon = subcategoryIcons[resource.subcategory!] ?? resourceIcon;
    }

    // Format date in more readable format
    String formattedDate = _getFormattedDate(resource.uploadDate);

    // Get time ago string (e.g. "2 days ago")
    String timeAgo = _getTimeAgo(resource.uploadDate);

    // Check if recently uploaded (within 7 days)
    bool isRecent = DateTime.now().difference(resource.uploadDate).inDays < 7;

    // Check if title matches search query for highlighting
    bool shouldHighlight = searchQuery.isNotEmpty &&
        resource.title.toLowerCase().contains(searchQuery.toLowerCase());

    // File extension for icon
    String fileExtension = resource.fileName.isNotEmpty
        ? resource.fileName.split('.').last.toLowerCase()
        : '';

    // Build the enhanced resource item with glass morphism effect
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: (context, _) => ResourceDetailScreen(resourceId: resource.id),
      closedElevation: 0,
      closedColor: ResourceTheme.backgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      openColor: ResourceTheme.backgroundColor,
      middleColor: ResourceTheme.backgroundColor,
      transitionDuration: Duration(milliseconds: 700),
      closedBuilder: (context, openContainer) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 16, left: 2, right: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: resourceColor.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 5,
                offset: Offset(0, -2),
                spreadRadius: -1,
              ),
            ],
            border: Border.all(
              color: shouldHighlight || isRecent
                  ? resourceColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: shouldHighlight || isRecent
                  ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Material(
                color: shouldHighlight || isRecent
                    ? resourceColor.withOpacity(0.015)
                    : Colors.white,
                child: InkWell(
                  splashColor: resourceColor.withOpacity(0.1),
                  highlightColor: resourceColor.withOpacity(0.05),
                  onTap: openContainer,
                  child: Stack(
                    children: [
                      // Subtle pattern background
                      if (isRecent || shouldHighlight)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.03,
                            child: CustomPaint(
                              painter: PatternPainter(
                                color: resourceColor,
                                pattern: isRecent ? PatternType.dots : PatternType.lines,
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top section with title and icon
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Resource icon with enhanced 3D styling
                                Hero(
                                  tag: 'resource-icon-${resource.id}',
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          resourceColor.withOpacity(0.1),
                                          resourceColor.withOpacity(0.25),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: resourceColor.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: resourceColor.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                          spreadRadius: -2,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.9),
                                          blurRadius: 10,
                                          offset: Offset(-5, -5),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Shadow effect
                                          Icon(
                                            resourceIcon,
                                            size: 30,
                                            color: Colors.black.withOpacity(0.2),
                                          ),
                                          // Main icon
                                          Positioned(
                                            top: -1,
                                            left: -1,
                                            child: Icon(
                                              resourceIcon,
                                              size: 30,
                                              color: resourceColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),

                                // Title and badges section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title with highlighting and NEW badge
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: shouldHighlight
                                                ? _buildHighlightedText(
                                              text: resource.title,
                                              query: searchQuery,
                                              baseStyle: GoogleFonts.poppins(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: ResourceTheme.textPrimary,
                                                height: 1.3,
                                              ),
                                            )
                                                : Text(
                                              resource.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: ResourceTheme.textPrimary,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // Admin actions
                                          if (isAdmin)
                                            _buildAdminActions(resource),
                                        ],
                                      ),

                                      SizedBox(height: 6),

                                      // Enhanced metadata row with icons
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          // Date info
                                          _buildMetadataItem(
                                            icon: Icons.access_time,
                                            text: timeAgo,
                                            color: Colors.grey.shade700,
                                            tooltip: formattedDate,
                                          ),

                                          // View count
                                          _buildMetadataItem(
                                            icon: Icons.visibility,
                                            text: _formatCount(resource.viewCount),
                                            color: Colors.grey.shade700,
                                            tooltip: '${resource.viewCount} views',
                                          ),

                                          // Added by (with highlight if matches search)
                                          if (resource.uploadedBy.isNotEmpty)
                                            _buildMetadataItem(
                                              icon: Icons.person,
                                              text: resource.uploadedBy,
                                              color: Colors.grey.shade700,
                                              tooltip: 'Added by ${resource.uploadedBy}',
                                              highlight: searchQuery.isNotEmpty &&
                                                  resource.uploadedBy.toLowerCase().contains(searchQuery.toLowerCase()),
                                              query: searchQuery,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16),

                            // Bottom section with enhanced badges
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Category and stream badges
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildEnhancedBadge(
                                          label: resource.category,
                                          icon: categoryIcons[resource.category] ?? Icons.folder,
                                          color: resourceColor,
                                        ),
                                        SizedBox(width: 8),
                                        _buildEnhancedBadge(
                                          label: resource.stream,
                                          icon: streamIcons[resource.stream] ?? Icons.category,
                                          color: streamColors[resource.stream] ?? Colors.grey,
                                        ),
                                        if (resource.subcategory != null) ...[
                                          SizedBox(width: 8),
                                          _buildEnhancedBadge(
                                            label: resource.subcategory!,
                                            icon: subcategoryIcons[resource.subcategory!] ?? Icons.description,
                                            color: Colors.blue.shade700,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                                // File type button with animation
                                if (resource.fileName.isNotEmpty)
                                  _buildFileTypeButton(
                                    fileName: resource.fileName,
                                    fileExtension: fileExtension,
                                    highlight: searchQuery.isNotEmpty &&
                                        resource.fileName.toLowerCase().contains(searchQuery.toLowerCase()),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // NEW badge with pulsating animation
                      if (isRecent)
                        Positioned(
                          top: 0,
                          right: 16,
                          child: AnimatedBuilder(
                            animation: _highlightAnimation,
                            builder: (context, child) {
                              return Container(
                                height: 28,
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ResourceTheme.tertiaryColor,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ResourceTheme.tertiaryColor.withOpacity(
                                        0.3 * _highlightAnimation.value,
                                      ),
                                      blurRadius: 4 + (4 * _highlightAnimation.value),
                                      spreadRadius: 0 + (1 * _highlightAnimation.value),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fiber_new,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'NEW',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      // Search match indicator (left border)
                      if (searchQuery.isNotEmpty && resource.searchRelevance > 0)
                        Positioned(
                          left: 0,
                          top: 16,
                          bottom: 16,
                          child: Container(
                            width: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  ResourceTheme.tertiaryColor,
                                  ResourceTheme.tertiaryColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ResourceTheme.tertiaryColor.withOpacity(0.2),
                                  blurRadius: 3,
                                  offset: Offset(1, 0),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Search relevance indicator (small badge)
                      if (sortOption == 'Search Relevance' &&
                          resource.searchRelevance > 0 &&
                          searchQuery.isNotEmpty)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber.shade800,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  resource.searchRelevance.toStringAsFixed(0) + '%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

// Enhanced admin actions with better UI
  Widget _buildAdminActions(Resource resource) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey.shade500,
        size: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      offset: Offset(0, 40),
      onSelected: (value) {
        if (value == 'edit') {
          _handleEditResource(resource.id, resource);
        } else if (value == 'delete') {
          _showDeleteConfirmation(resource.id, resource.title);
        } else if (value == 'info') {
          _showResourceInfo(resource);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: ResourceTheme.primaryColor,
              ),
              SizedBox(width: 12),
              Text('View Info'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: ResourceTheme.secondaryColor,
              ),
              SizedBox(width: 12),
              Text('Edit Resource'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red.shade600,
              ),
              SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Enhanced metadata item with tooltip and highlighting
  Widget _buildMetadataItem({
    required IconData icon,
    required String text,
    required Color color,
    String? tooltip,
    bool highlight = false,
    String query = '',
  }) {
    final textWidget = highlight
        ? _buildHighlightedText(
      text: text,
      query: query,
      baseStyle: TextStyle(
        fontSize: 12,
        color: color,
      ),
    )
        : Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Tooltip(
      message: tooltip ?? text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 4),
          textWidget,
        ],
      ),
    );
  }

// Enhanced badges with gradient background
  Widget _buildEnhancedBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

// Enhanced file type button with animation
  Widget _buildFileTypeButton({
    required String fileName,
    required String fileExtension,
    bool highlight = false,
  }) {
    // Get file type info
    final IconData icon = _getFileIcon(fileExtension);
    final Color color = _getFileColor(fileExtension);
    final String label = fileExtension.toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show file details in a tooltip or dialog
          print('File: $fileName');
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                highlight ? ResourceTheme.tertiaryColor.withOpacity(0.1) : color.withOpacity(0.1),
                highlight ? ResourceTheme.tertiaryColor.withOpacity(0.2) : color.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? ResourceTheme.tertiaryColor.withOpacity(0.4) : color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: highlight ? ResourceTheme.tertiaryColor.withOpacity(0.1) : color.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: highlight ? ResourceTheme.tertiaryColor : color,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: highlight ? ResourceTheme.tertiaryColor : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to get file icon
  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

// Helper method to get file color
  Color _getFileColor(String extension) {
    switch (extension) {
      case 'pdf':
        return Colors.red.shade600;
      case 'doc':
      case 'docx':
        return Colors.blue.shade600;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade600;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade600;
      case 'zip':
      case 'rar':
        return Colors.purple.shade600;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.cyan.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

// Format date in a more readable way
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();

    // Today
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${_formatTime(date)}';
    }

    // Yesterday
    final yesterday = now.subtract(Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday, ${_formatTime(date)}';
    }

    // This week
    if (now.difference(date).inDays < 7) {
      return '${_getDayName(date)}, ${_formatTime(date)}';
    }

    // This year
    if (date.year == now.year) {
      return '${date.day} ${_getMonthName(date.month)}';
    }

    // Older
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

// Get relative time ago string
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

// Helper for day name
  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

// Helper for month name
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }

// Format time
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

// Format count with K/M suffix
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

// Show resource info dialog
  void _showResourceInfo(Resource resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Resource Information',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ResourceTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Title', resource.title),
            _buildInfoRow('Category', resource.category),
            if (resource.subcategory != null)
              _buildInfoRow('Type', resource.subcategory!),
            _buildInfoRow('Stream', resource.stream),
            _buildInfoRow('Added by', resource.uploadedBy),
            _buildInfoRow('Date added', _getFormattedDate(resource.uploadDate)),
            _buildInfoRow('Views', resource.viewCount.toString()),
            if (resource.fileName.isNotEmpty)
              _buildInfoRow('File', resource.fileName),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

// Info row for resource info dialog
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: ResourceTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// Custom painter for background patterns


  // Highlighted text for search results
  Widget _buildHighlightedText({
    required String text,
    required String query,
    TextStyle? baseStyle,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle ?? GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ResourceTheme.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final style = baseStyle ?? GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: ResourceTheme.textPrimary,
    );

    final highlightStyle = style.copyWith(
      color: ResourceTheme.tertiaryColor,
      backgroundColor: ResourceTheme.tertiaryColor.withOpacity(0.1),
      fontWeight: FontWeight.w700,
    );

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    // Find matches
    List<int> matches = [];
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      matches.add(index);
      start = index + lowerQuery.length;
    }

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Build spans
    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (int matchIndex in matches) {
      // Add text before match
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, matchIndex),
          style: style,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: highlightStyle,
      ));

      currentIndex = matchIndex + query.length;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // File type badge with icon
  Widget _buildFileTypeBadge(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    IconData icon;
    Color color;
    String label = extension.toUpperCase();

    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red.shade700;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue.shade700;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        color = Colors.orange.shade700;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green.shade700;
        break;
      case 'zip':
      case 'rar':
        icon = Icons.folder_zip;
        color = Colors.purple.shade700;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        icon = Icons.image;
        color = Colors.cyan.shade700;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey.shade700;
    }

    // Check if filename matches search
    final bool shouldHighlight = searchQuery.isNotEmpty &&
        fileName.toLowerCase().contains(searchQuery.toLowerCase());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: shouldHighlight
            ? ResourceTheme.tertiaryColor.withOpacity(0.2)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: shouldHighlight
                ? ResourceTheme.tertiaryColor.withOpacity(0.5)
                : color.withOpacity(0.3)
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              icon,
              size: 10,
              color: shouldHighlight ? ResourceTheme.tertiaryColor : color
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: shouldHighlight ? ResourceTheme.tertiaryColor : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Empty state with illustrations and suggestions
  Widget _buildEmptyState() {
    String messageTitle = 'No resources found';
    String messageSubtitle = '';
    String svgAsset = 'assets/images/empty_folder.svg';

    if (searchQuery.isNotEmpty) {
      messageTitle = 'No results found';
      messageSubtitle = 'No resources match "$searchQuery"';
      svgAsset = 'assets/images/no_results.svg';
    } else if (selectedStream != 'All Resources') {
      if (selectedCategory != 'All Categories') {
        if (selectedCategory == 'Exam Papers' &&
            selectedSubcategory != null &&
            selectedSubcategory != 'All Exam Papers') {
          messageSubtitle = 'No $selectedSubcategory found in $selectedStream';
        } else {
          messageSubtitle = 'No $selectedCategory found in $selectedStream';
        }
      } else {
        messageSubtitle = 'No resources found in $selectedStream';
      }
    } else if (selectedCategory != 'All Categories') {
      if (selectedCategory == 'Exam Papers' &&
          selectedSubcategory != null &&
          selectedSubcategory != 'All Exam Papers') {
        messageSubtitle = 'No $selectedSubcategory found';
      } else {
        messageSubtitle = 'No $selectedCategory found';
      }
    }

    if (messageSubtitle.isEmpty) {
      messageSubtitle = 'Try different search criteria or add new resources';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG illustration
            Container(
              width: 200,
              height: 200,
              child: SvgPicture.asset(
                svgAsset,
                placeholderBuilder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              messageTitle,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ResourceTheme.primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(maxWidth: 320),
              child: Text(
                messageSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: ResourceTheme.textSecondary,
                ),
              ),
            ),
            SizedBox(height: 32),

            // Search suggestions for empty search results
            if (searchQuery.isNotEmpty) ...[
              _buildEmptySearchSuggestions(),
              SizedBox(height: 24),
            ],

            // Action buttons
            if ((selectedStream != 'All Resources' ||
                selectedCategory != 'All Categories' ||
                searchQuery.isNotEmpty) &&
                !isFilterVisible)
              Container(
                width: 200,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.filter_alt_off),
                  label: Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ResourceTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedStream = 'All Resources';
                      selectedCategory = 'All Categories';
                      selectedSubcategory = null;
                      searchController.clear();
                      searchQuery = '';
                      _loadResources();
                    });
                  },
                ),
              ),
            if (isAdmin) SizedBox(height: 16),
            if (isAdmin)
              Container(
                width: 200,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Resource'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ResourceTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _showAddResourceDialog(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Empty search suggestions
  Widget _buildEmptySearchSuggestions() {
    // List of common academic terms
    final List<String> commonTerms = [
      'Mathematics', 'Math', 'Physics', 'Chemistry', 'Biology',
      'History', 'English', 'Geography', 'Science', 'Computer',
      'Economics', 'Business', 'Accounting', 'Notes', 'Paper',
      'Exam', 'Test', 'Quiz', 'Assignment', 'Homework', 'Project',
      'Tutorial', 'Guide', 'Book', 'Textbook', 'Reference',
      'Model', 'Past', 'Term', 'Answer', 'Solution', 'Key', 'Formula'
    ];

    // Find potential corrections
    List<Map<String, dynamic>> potentialCorrections = [];

    for (String term in commonTerms) {
      double similarity = FuzzySearch.calculateSimilarity(term.toLowerCase(), searchQuery.toLowerCase());
      if (similarity >= 60.0) {
        potentialCorrections.add({
          'term': term,
          'similarity': similarity,
        });
      }
    }

    // Sort corrections by similarity
    potentialCorrections.sort((a, b) => b['similarity'].compareTo(a['similarity']));

    // Take top 3 suggestions
    final suggestions = potentialCorrections.take(3).toList();

    if (suggestions.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ResourceTheme.tertiaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber.shade700,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Did you mean:',
                style: TextStyle(
                  fontSize: 14,
                  color: ResourceTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ElevatedButton(
                child: Text(suggestion['term']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ResourceTheme.tertiaryColor.withOpacity(0.1),
                  foregroundColor: ResourceTheme.tertiaryColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: ResourceTheme.tertiaryColor.withOpacity(0.3)),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    searchController.text = suggestion['term'];
                    searchQuery = suggestion['term'];
                  });
                  _loadResources();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Floating action buttons with animations
  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Scroll to top button (only when scrolled down)
        if (showScrollToTop)
          ScaleTransition(
            scale: _fabAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.white,
                foregroundColor: ResourceTheme.tertiaryColor,
                child: Icon(Icons.arrow_upward),
                tooltip: 'Scroll to top',
                onPressed: () {
                  scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                elevation: 4,
              ),
            ),
          ),

        // Add resource button (admin only)
        if (isAdmin)
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: ResourceTheme.tertiaryColor,
              foregroundColor: Colors.white,
              child: Icon(Icons.add),
              tooltip: 'Add new resource',
              onPressed: () => _showAddResourceDialog(context),
              elevation: 4,
            ),
          ),

        // Search button when not focused
        if (!isSearchFocused && searchQuery.isEmpty)
          ScaleTransition(
            scale: _fabAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FloatingActionButton(
                heroTag: 'search',
                backgroundColor: ResourceTheme.secondaryColor,
                foregroundColor: Colors.white,
                child: Icon(Icons.search),
                tooltip: 'Search resources',
                onPressed: () {
                  searchFocusNode.requestFocus();
                },
                elevation: 4,
              ),
            ),
          ),
      ],
    );
  }

  // Admin functions
  void _handleEditResource(String resourceId, Resource resource) {
    Navigator.pushNamed(
      context,
      '/resource_management',
      arguments: {'editing': true, 'resourceId': resourceId},
    ).then((_) => _loadResources());
  }

  // Enhanced delete confirmation
  void _showDeleteConfirmation(String resourceId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Delete Resource',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this resource?',
                style: ResourceTheme.bodyLarge,
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resource Name:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: ResourceTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. The resource and its file will be permanently deleted.',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 14,
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
          TextButton(
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade800,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete_outline, size: 18),
            label: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteResource(resourceId);
            },
          ),
        ],
        actionsPadding: EdgeInsets.all(16),
      ),
    );
  }

  // Delete resource with animation
  void _deleteResource(String resourceId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ResourceTheme.shadowMedium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ResourceTheme.tertiaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'Deleting resource...',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await ResourceUtils.deleteResource(resourceId);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Refresh resources
      _loadResources();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Resource deleted successfully'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      print('Error deleting resource: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Error deleting resource: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Enhanced add resource dialog
  void _showAddResourceDialog(BuildContext context) {
    // Only allow admins to add resources
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only administrators can add resources'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Resource form data
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedResourceStream = 'Science Stream';
    String selectedResourceCategory = 'Exam Papers';
    String? selectedResourceSubcategory = 'Term Papers';
    File? selectedFile;
    String? fileName;
    bool isUploading = false;
    double uploadProgress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while uploading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickFile() async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  allowMultiple: false,
                );
                if (result != null) {
                  setState(() {
                    selectedFile = File(result.files.single.path!);
                    fileName = result.files.single.name;
                  });
                }
              } catch (e) {
                print('Error picking file: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error selecting file: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }

            Future<void> uploadResource() async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a title'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              if (selectedFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please select a file'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              setState(() {
                isUploading = true;
                uploadProgress = 0.0;
              });

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  throw Exception('User not logged in');
                }

                // Create a unique filename
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final fileExtension = fileName!.split('.').last;
                final uniqueFileName = '${titleController.text.replaceAll(' ', '_')}_$timestamp.$fileExtension';

                // Upload file to Firebase Storage
                final storageRef = FirebaseStorage.instance
                    .ref()
                    .child('resources')
                    .child(uniqueFileName);

                // Upload with progress monitoring
                final uploadTask = storageRef.putFile(selectedFile!);

                // Monitor upload progress
                uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
                  final progress = snapshot.bytesTransferred / snapshot.totalBytes;
                  setState(() {
                    uploadProgress = progress;
                  });
                  print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
                });

                // Wait for upload to complete
                await uploadTask.whenComplete(() => {});
                final fileUrl = await storageRef.getDownloadURL();

                // Get user information
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                final userName = userDoc.data()?['name'] ?? user.displayName ?? user.email;

                // Prepare resource data
                Map<String, dynamic> resourceData = {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': selectedResourceCategory,
                  'stream': selectedResourceStream,
                  'fileUrl': fileUrl,
                  'fileName': fileName,
                  'fileSize': await selectedFile!.length(),
                  'uploadDate': Timestamp.now(),
                  'uploadedBy': userName,
                  'uploaderId': user.uid,
                  'viewCount': 0,
                };

                // Add subcategory for Exam Papers
                if (selectedResourceCategory == 'Exam Papers' &&
                    selectedResourceSubcategory != null) {
                  resourceData['subcategory'] = selectedResourceSubcategory;
                }

                // Add resource to Firestore
                final docRef = await FirebaseFirestore.instance
                    .collection('resources')
                    .add(resourceData);

                // Close dialog
                Navigator.pop(context);

                // Refresh resources
                _loadResources();

                // Show success message with animation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.check, color: Colors.green, size: 16),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Resource uploaded successfully'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    action: SnackBarAction(
                      label: 'VIEW',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResourceDetailScreen(resourceId: docRef.id),
                          ),
                        );
                      },
                    ),
                  ),
                );
              } catch (e) {
                print('Error uploading resource: $e');

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Error uploading resource: $e'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              } finally {
                setState(() {
                  isUploading = false;
                });
              }
            }

            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ResourceTheme.primaryColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New Resource',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Upload educational materials for students',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isUploading)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Close',
                            ),
                        ],
                      ),
                    ),

                    // Form content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title field with validation
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resource Title *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ResourceTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: titleController,
                                  decoration: ResourceTheme.getInputDecoration(
                                    hintText: 'Enter resource title',
                                    prefixIcon: Icons.title,
                                  ),
                                  maxLength: 100,
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Stream selection
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Academic Stream *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ResourceTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildDropdownField(
                                  currentValue: selectedResourceStream,
                                  items: streamIcons.keys
                                      .where((stream) => stream != 'All Resources')
                                      .map((stream) => _buildDropdownItem(
                                    value: stream,
                                    icon: streamIcons[stream] ?? Icons.folder,
                                    color: streamColors[stream] ?? Colors.grey,
                                  ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedResourceStream = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Category selection
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resource Category *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ResourceTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildDropdownField(
                                  currentValue: selectedResourceCategory,
                                  items: categoryIcons.keys
                                      .where((category) => category != 'All Categories')
                                      .map((category) => _buildDropdownItem(
                                    value: category,
                                    icon: categoryIcons[category] ?? Icons.folder,
                                    color: categoryColors[category] ?? Colors.grey,
                                  ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedResourceCategory = value;

                                        // Reset subcategory if category is not Exam Papers
                                        if (value != 'Exam Papers') {
                                          selectedResourceSubcategory = null;
                                        } else {
                                          selectedResourceSubcategory = 'Term Papers';
                                        }
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Subcategory selection for Exam Papers
                            if (selectedResourceCategory == 'Exam Papers') ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Exam Paper Type *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: ResourceTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildDropdownField(
                                    currentValue: selectedResourceSubcategory ?? 'Term Papers',
                                    items: subcategoryIcons.keys
                                        .where((subcat) => subcat != 'All Exam Papers')
                                        .map((subcat) => _buildDropdownItem(
                                      value: subcat,
                                      icon: subcategoryIcons[subcat] ?? Icons.description,
                                      color: Colors.blue.shade700,
                                    ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedResourceSubcategory = value;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                            ],

                            // Description field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ResourceTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: descriptionController,
                                  decoration: ResourceTheme.getInputDecoration(
                                    hintText: 'Enter resource description (optional)',
                                    helperText: 'Provide additional details about this resource',
                                  ),
                                  maxLines: 4,
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ],
                            ),
                            SizedBox(height: 24),

                            // File selection
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.attach_file, color: ResourceTheme.primaryColor),
                                      SizedBox(width: 10),
                                      Text(
                                        'Resource File *',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: ResourceTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Show selected file or file selection button
                                  if (fileName != null) ...[
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.check, color: Colors.green, size: 24),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fileName!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green.shade700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Selected file ready for upload',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.change_circle, color: Colors.green.shade700),
                                            onPressed: pickFile,
                                            tooltip: 'Change file',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      width: double.infinity,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          style: BorderStyle.solid,
                                          width: 2,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: pickFile,
                                          borderRadius: BorderRadius.circular(16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.cloud_upload,
                                                size: 40,
                                                color: ResourceTheme.tertiaryColor,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Click to select file',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: ResourceTheme.tertiaryColor,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'PDF, DOC, PPT, XLS, ZIP, JPG, etc.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
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
                    ),

                    // Upload progress indicator
                    if (isUploading) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Uploading Resource...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ResourceTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  '${(uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: ResourceTheme.tertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Stack(
                              children: [
                                // Background
                                Container(
                                  width: double.infinity,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Progress indicator
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: MediaQuery.of(context).size.width * uploadProgress,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ResourceTheme.tertiaryColor,
                                        ResourceTheme.tertiaryLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Dialog actions
                    if (!isUploading)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              child: Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: Icon(Icons.cloud_upload),
                              label: Text('Upload Resource'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ResourceTheme.tertiaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: uploadResource,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper to build dropdown field
  Widget _buildDropdownField({
    required String currentValue,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: currentValue,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          borderRadius: BorderRadius.circular(12),
          itemHeight: 50,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
          iconSize: 30,
        ),
      ),
    );
  }

  // Helper to build dropdown item
  DropdownMenuItem<String> _buildDropdownItem({
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for SliverAppBar delegate
class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverFilterDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _SliverFilterDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}
class PatternPainter extends CustomPainter {
  final Color color;
  final PatternType pattern;

  PatternPainter({
    required this.color,
    required this.pattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    if (pattern == PatternType.dots) {
      _drawDots(canvas, size, paint);
    } else {
      _drawLines(canvas, size, paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    final dotSize = 2.0;
    final spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      }
    }
  }

  void _drawLines(Canvas canvas, Size size, Paint paint) {
    final spacing = 20.0;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pattern types
enum PatternType {
  dots,
  lines,
}