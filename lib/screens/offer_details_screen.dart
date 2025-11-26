import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';
import 'full_image_screen.dart';

class OfferDetailsScreen extends StatelessWidget {
  final Product offer;

  const OfferDetailsScreen({
    Key? key,
    required this.offer,
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    final url = offer.link;

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No offer link available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔗 Attempting to open offer URL: $url');

    try {
      final Uri uri = Uri.parse(url);

      // Check if URL can be launched
      final bool canLaunch = await canLaunchUrl(uri);

      print('✅ Can launch URL: $canLaunch');

      if (canLaunch) {
        // Try external browser first
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('✅ Offer URL launched successfully');
        } else {
          print('❌ Failed to launch offer URL (external app)');
          _showErrorOrCopyDialog(
            context,
            'Could not open the offer link in external browser.',
            url,
          );
        }
      } else {
        print('❌ Cannot launch URL with canLaunchUrl, trying platformDefault');

        // Fallback: let the platform decide how to open it
        try {
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          if (!launched) {
            print('❌ Failed to launch offer URL (platformDefault)');
            _showErrorOrCopyDialog(
              context,
              'Could not open the offer link.',
              url,
            );
          }
        } catch (e) {
          print('❌ Alternative launch failed: $e');
          _showErrorOrCopyDialog(
            context,
            'Error opening the offer link.',
            url,
          );
        }
      }
    } catch (e) {
      print('❌ Error parsing or launching URL: $e');
      _showErrorOrCopyDialog(
        context,
        'Error opening the offer link.',
        url,
      );
    }
  }

  void _showErrorOrCopyDialog(
    BuildContext context,
    String message,
    String url,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offer Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
                'You can copy the offer link below and open it in your browser:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offer link copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final site = offer.source ?? _extractDomain(offer.link);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () =>
                _showErrorOrCopyDialog(context, 'Offer link', offer.link),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Offer Image / Banner with tap-to-view-full
            if (offer.thumbnail != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageScreen(
                        imageUrl: offer.thumbnail!,
                        title: offer.title,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 260,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    offer.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image,
                              size: 80,
                              color:
                                  Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Offer image not available',
                            style: TextStyle(
                                color:
                                    Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 260,
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer,
                          size: 80,
                          color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No banner available',
                        style: TextStyle(
                            color:
                                Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    offer.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Site name
                  if (site.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.store,
                            size: 18),
                        const SizedBox(width: 6),
                        Text(
                          site,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Snippet / Description
                  if (offer.snippet != null &&
                      offer.snippet!.trim().isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offer details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.all(
                                  12),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .grey.shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(12),
                            border: Border.all(
                                color: Colors
                                    .grey.shade300),
                          ),
                          child: Text(
                            offer.snippet!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors
                                  .grey.shade800,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Offer Link
                  if (offer.link.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offer link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.all(
                                  10),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .blue.shade50,
                            borderRadius:
                                BorderRadius
                                    .circular(8),
                            border: Border.all(
                                color: Colors
                                    .blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link,
                                  color: Colors
                                      .blue.shade700,
                                  size: 20),
                              const SizedBox(
                                  width: 8),
                              Expanded(
                                child: Text(
                                  offer.link,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .blue.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  color: Colors
                                      .blue.shade700,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(
                                          text: offer
                                              .link));
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Offer link copied!'),
                                      duration:
                                          Duration(
                                              seconds:
                                                  1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // View Offer Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _launchURL(context),
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 22,
                      ),
                      label: const Text(
                        'View Offer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            theme.primaryColor,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                      ),
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

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (_) {
      return '';
    }
  }
}