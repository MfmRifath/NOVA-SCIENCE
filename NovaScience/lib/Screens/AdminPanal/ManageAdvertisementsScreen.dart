// screens/advertisement_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../Modals/Advertisment.dart';
import '../../Service/AdvertisementProvider.dart';
import 'AdvertisementForm.dart';
import 'AdvertismenrtCourousal.dart';

class AdvertisementManagementScreen extends StatefulWidget {
  @override
  _AdvertisementManagementScreenState createState() => _AdvertisementManagementScreenState();
}

class _AdvertisementManagementScreenState extends State<AdvertisementManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load advertisements when screen initializes
    Future.microtask(() =>
        Provider.of<AdvertisementProvider>(context, listen: false).loadAdvertisements()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advertisement Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AdvertisementProvider>(context, listen: false).loadAdvertisements();
            },
            tooltip: 'Refresh Advertisements',
          ),
        ],
      ),
      body: Consumer<AdvertisementProvider>(
        builder: (context, advertisementProvider, child) {
          if (advertisementProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final allAds = advertisementProvider.allAdvertisements;
          final activeAds = advertisementProvider.advertisements;

          return Column(
            children: [
              // Preview of what users will see
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Live Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${activeAds.length} active ad(s)',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Live preview of the carousel
                    if (activeAds.isEmpty)
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Text(
                            'No active advertisements to display',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      )
                    else
                      AdvertisementCarousel(
                        advertisementProvider: advertisementProvider,
                        height: 180,
                      ),
                  ],
                ),
              ),

              // Advertisement management list
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Advertisements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${allAds.length} total',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // List of all advertisements
                      Expanded(
                        child: allAds.isEmpty
                            ? Center(
                          child: Text(
                            'No advertisements added yet',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        )
                            : ListView.builder(
                          itemCount: allAds.length,
                          itemBuilder: (context, index) {
                            final ad = allAds[index];
                            return _buildAdvertisementCard(context, ad, advertisementProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAdvertisementForm(context);
        },
        icon: Icon(Icons.add),
        label: Text('Add Advertisement'),
      ),
    );
  }

  Widget _buildAdvertisementCard(
      BuildContext context,
      Advertisement ad,
      AdvertisementProvider provider
      ) {
    // Check if ad is currently active based on date and status
    final now = DateTime.now();
    final isCurrentlyActive = ad.isActive && ad.startDate.isBefore(now) && ad.endDate.isAfter(now);

    return Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentlyActive ? Colors.green.shade300 : Colors.grey.shade300,
            width: isCurrentlyActive ? 2 : 1,
          ),
        ),
        child: Column(
            children: [
        // Header with title and status indicator
        Padding(
        padding: EdgeInsets.all(12),
        child: Row(
            children: [
        // Ad type icon
        Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
        color: _getAdTypeColor(ad.type).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
          child: Icon(
            _getAdTypeIcon(ad.type),
            color: _getAdTypeColor(ad.type),
            size: 20,
          ),
        ),
              SizedBox(width: 12),

              // Ad title and type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title.isEmpty ? 'Untitled Advertisement' : ad.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getAdTypeText(ad.type),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentlyActive
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentlyActive
                        ? Colors.green.shade400
                        : Colors.grey.shade400,
                  ),
                ),
                child: Text(
                  isCurrentlyActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isCurrentlyActive
                        ? Colors.green.shade800
                        : Colors.grey.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
        ),
        ),

              // Ad content preview
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: _buildAdPreview(ad),
              ),

              // Ad details and actions
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Schedule info
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Schedule: ${DateFormat('MMM dd').format(ad.startDate)} - ${DateFormat('MMM dd, yyyy').format(ad.endDate)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Link info if available
                    if (ad.link.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Link: ${ad.link}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Toggle active status
                        OutlinedButton.icon(
                          onPressed: () async {
                            await provider.toggleAdvertisementStatus(ad.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ad.isActive
                                      ? 'Advertisement deactivated'
                                      : 'Advertisement activated',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            ad.isActive ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                          ),
                          label: Text(ad.isActive ? 'Disable' : 'Enable'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 8),

                        // Edit button
                        OutlinedButton.icon(
                          onPressed: () {
                            _showAdvertisementForm(context, advertisement: ad);
                          },
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 8),

                        // Delete button
                        OutlinedButton.icon(
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, ad, provider);
                          },
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          label: Text('Delete', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
        ),
    );
  }

  // Helper method to show the advertisement form dialog
  void _showAdvertisementForm(BuildContext context, {Advertisement? advertisement}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AdvertisementForm(advertisement: advertisement);
      },
    );
  }

  // Helper method to show delete confirmation dialog
  void _showDeleteConfirmationDialog(
      BuildContext context,
      Advertisement advertisement,
      AdvertisementProvider provider,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Advertisement'),
          content: Text(
            'Are you sure you want to delete this advertisement? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await provider.deleteAdvertisement(advertisement.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Advertisement deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete advertisement: $e')),
                  );
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build advertisement preview in the management list
  Widget _buildAdPreview(Advertisement ad) {
    switch (ad.type) {
      case AdvertisementType.image:
        if (ad.imageUrl.isEmpty) {
          return Center(child: Text('No image available'));
        }
        return Image.network(
          ad.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('Failed to load image'));
          },
        );

      case AdvertisementType.video:
        final videoId = YoutubePlayer.convertUrlToId(ad.videoUrl) ?? '';
        if (videoId.isEmpty) {
          return Center(child: Text('Invalid YouTube video'));
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$videoId/0.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Center(child: Text('Failed to load video thumbnail'));
              },
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );

      case AdvertisementType.whatsapp:
        return Container(
          color: Color(0xFF25D366), // WhatsApp green
          child: ad.imageUrl.isNotEmpty
              ? Stack(
            children: [
              Opacity(
                opacity: 0.7,
                child: Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox();
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.whatshot,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'WhatsApp Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.whatshot,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'WhatsApp Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );

      case AdvertisementType.telegram:
        return Container(
          color: Color(0xFF0088CC), // Telegram blue
          child: ad.imageUrl.isNotEmpty
              ? Stack(
            children: [
              Opacity(
                opacity: 0.7,
                child: Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox();
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Telegram Channel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'Telegram Channel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  // Helper methods for advertisement type information
  IconData _getAdTypeIcon(AdvertisementType type) {
    switch (type) {
      case AdvertisementType.image:
        return Icons.image;
      case AdvertisementType.video:
        return Icons.videocam;
      case AdvertisementType.whatsapp:
        return Icons.whatshot;
      case AdvertisementType.telegram:
        return Icons.send;
    }
  }

  Color _getAdTypeColor(AdvertisementType type) {
    switch (type) {
      case AdvertisementType.image:
        return Colors.blue;
      case AdvertisementType.video:
        return Colors.red;
      case AdvertisementType.whatsapp:
        return Colors.green;
      case AdvertisementType.telegram:
        return Colors.blue.shade700;
    }
  }

  String _getAdTypeText(AdvertisementType type) {
    switch (type) {
      case AdvertisementType.image:
        return 'Image Advertisement';
      case AdvertisementType.video:
        return 'YouTube Video Advertisement';
      case AdvertisementType.whatsapp:
        return 'WhatsApp Chat Link';
      case AdvertisementType.telegram:
        return 'Telegram Channel Link';
    }
  }
}

