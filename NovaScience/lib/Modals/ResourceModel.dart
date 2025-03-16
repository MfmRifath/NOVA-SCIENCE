// resource_model.dart
class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String stream;
  final String category;
  final String? subcategory;  // New field for subcategories
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final DateTime uploadDate;
  final String uploadedBy;
  final String uploaderId;
  final int viewCount;

  ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.stream,
    required this.category,
    this.subcategory,  // Optional field
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.uploadDate,
    required this.uploadedBy,
    required this.uploaderId,
    required this.viewCount,
  });

  // Convert Firestore document to ResourceModel
  factory ResourceModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ResourceModel(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      stream: data['stream'] ?? 'Unknown Stream',
      category: data['category'] ?? 'Uncategorized',
      subcategory: data['subcategory'],  // May be null
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? 'Unknown File',
      fileSize: data['fileSize'] ?? 0,
      uploadDate: data['uploadDate']?.toDate() ?? DateTime.now(),
      uploadedBy: data['uploadedBy'] ?? 'Unknown User',
      uploaderId: data['uploaderId'] ?? '',
      viewCount: data['viewCount'] ?? 0,
    );
  }

  // Convert ResourceModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'stream': stream,
      'category': category,
      'subcategory': subcategory,  // Include subcategory
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadDate': uploadDate,
      'uploadedBy': uploadedBy,
      'uploaderId': uploaderId,
      'viewCount': viewCount,
    };
  }
}