// widgets/advertisement_carousel.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Modals/Advertisment.dart';
import '../../Service/AdvertisementProvider.dart';


class AdvertisementCarousel extends StatefulWidget {
  final AdvertisementProvider advertisementProvider;
  final double height;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Duration autoScrollDuration;

  const AdvertisementCarousel({
    Key? key,
    required this.advertisementProvider,
    this.height = 180,
    this.margin = const EdgeInsets.only(bottom: 24),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.autoScrollDuration = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  _AdvertisementCarouselState createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);

    // Auto-scroll advertisements
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(widget.autoScrollDuration, () {
      if (mounted) {
        final advertisements = widget.advertisementProvider.advertisements;
        if (advertisements.length > 1) {
          final nextPage = (_currentPage + 1) % advertisements.length;
          _pageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Function to handle ad clicks and navigate to the link
  Future<void> _navigateToAdLink(Advertisement ad) async {
    if (ad.link.isEmpty) return;

    final link = ad.link;

    try {
      // Determine the type of link
      Uri? uri;
      LaunchMode mode = LaunchMode.externalApplication;

      // Handle special app links
      if (ad.type == AdvertisementType.whatsapp) {
        // Format WhatsApp link properly if it's just a phone number
        if (RegExp(r'^\+?[0-9]+$').hasMatch(link)) {
          uri = Uri.parse('https://wa.me/${link.replaceAll(RegExp(r'[^0-9]'), '')}');
        } else if (link.contains('wa.me') || link.contains('whatsapp')) {
          uri = Uri.parse(link);
        } else {
          uri = Uri.parse('https://wa.me/$link');
        }
      } else if (ad.type == AdvertisementType.telegram) {
        // Format Telegram link properly
        if (link.startsWith('@') || !link.contains('/')) {
          // Username format
          final username = link.startsWith('@') ? link.substring(1) : link;
          uri = Uri.parse('https://t.me/$username');
        } else if (link.contains('t.me') || link.contains('telegram')) {
          uri = Uri.parse(link);
        } else {
          uri = Uri.parse('https://t.me/$link');
        }
      } else {
        // Standard web link handling
        if (link.startsWith('http://') || link.startsWith('https://')) {
          uri = Uri.parse(link);
        } else {
          uri = Uri.parse('https://$link');
        }
      }

      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: mode);
        return;
      }

      // If all attempts fail, show an error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $link')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the advertisements list from the provider
    final advertisements = widget.advertisementProvider.advertisements;

    // Check if there are any advertisements to display
    if (widget.advertisementProvider.isLoading) {
      return Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: Colors.grey[200],
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (advertisements.isEmpty) {
      return SizedBox(height: 0);  // Don't show anything if no ads
    }

    return Container(
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            // Page View for advertisements
            PageView.builder(
              controller: _pageController,
              itemCount: advertisements.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final ad = advertisements[index];
                // GestureDetector to handle taps on the advertisement
                return GestureDetector(
                  onTap: () => _navigateToAdLink(ad),
                  child: Stack(
                    children: [
                      _buildAdvertisementContent(ad),

                      // Title and description overlay (if available)
                      if (ad.title.isNotEmpty || ad.description.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ad.title.isNotEmpty)
                                  Text(
                                    ad.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (ad.description.isNotEmpty)
                                  Text(
                                    ad.description,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),

                      // App-specific icons for WhatsApp and Telegram links
                      if (ad.type == AdvertisementType.whatsapp || ad.type == AdvertisementType.telegram)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ad.type == AdvertisementType.whatsapp
                                  ? Icons.whatshot  // Using similar icon for WhatsApp
                                  : Icons.send,     // Using similar icon for Telegram
                              color: ad.type == AdvertisementType.whatsapp
                                  ? Colors.green
                                  : Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Page indicator dots
            if (advertisements.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    advertisements.length,
                        (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build the content of the advertisement based on its type
  Widget _buildAdvertisementContent(Advertisement ad) {
    switch (ad.type) {
      case AdvertisementType.image:
        return Image.network(
          ad.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );

      case AdvertisementType.video:
        final videoId = YoutubePlayer.convertUrlToId(ad.videoUrl) ?? '';
        return Stack(
          alignment: Alignment.center,
          children: [
            // YouTube thumbnail
            Image.network(
              'https://img.youtube.com/vi/$videoId/0.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: widget.height,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
            // Play button overlay
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                size: 36,
                color: Colors.white,
              ),
            ),
          ],
        );

      case AdvertisementType.whatsapp:
      case AdvertisementType.telegram:
      // For WhatsApp and Telegram ads, we'll use both the image and special styling
        return Stack(
          children: [
            // Base image
            if (ad.imageUrl.isNotEmpty)
              Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: widget.height,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: ad.type == AdvertisementType.whatsapp
                        ? Color(0xFF25D366)  // WhatsApp green
                        : Color(0xFF0088CC), // Telegram blue
                    child: Center(
                      child: Icon(
                        ad.type == AdvertisementType.whatsapp
                            ? Icons.whatshot
                            : Icons.send,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: ad.type == AdvertisementType.whatsapp
                    ? Color(0xFF25D366)  // WhatsApp green
                    : Color(0xFF0088CC), // Telegram blue
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ad.type == AdvertisementType.whatsapp
                            ? Icons.whatshot
                            : Icons.send,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        ad.type == AdvertisementType.whatsapp
                            ? 'Chat with us on WhatsApp'
                            : 'Message us on Telegram',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );

      default:
        return Container(
          height: widget.height,
          color: Colors.grey[200],
          child: Center(
            child: Text('Unknown advertisement type'),
          ),
        );
    }
  }
}
