import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/recent_products_service.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    final url = product.link;

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No product link available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔗 Attempting to open URL: $url');

    try {
      final Uri uri = Uri.parse(url);

      // Check if URL can be launched
      final bool canLaunch = await canLaunchUrl(uri);

      print('✅ Can launch URL: $canLaunch');

      if (canLaunch) {
        // Launch in external browser
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          print('✅ URL launched successfully');
        } else {
          print('❌ Failed to launch URL');
          _showErrorDialog(
              context, 'Could not open the product link');
        }
      } else {
        print('❌ Cannot launch URL');

        // Try alternative launch mode
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          print('❌ Alternative launch failed: $e');
          _showCopyLinkDialog(context, url);
        }
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      _showCopyLinkDialog(context, url);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCopyLinkDialog(context, product.link);
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _showCopyLinkDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Cannot open link automatically. Copy the link below:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
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
                  content: Text('Link copied to clipboard!'),
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
    // Track this product as recently viewed
    RecentProductsService().addProduct(product);

    final authProvider = context.watch<AuthProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final productId = product.link.hashCode.toString();
    final isInWishlist =
        wishlistProvider.isInWishlist(productId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(
              isInWishlist
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: isInWishlist ? Colors.red : null,
            ),
            onPressed: () {
              wishlistProvider.toggleWishlist(
                authProvider.user!.uid,
                product,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isInWishlist
                        ? 'Removed from wishlist'
                        : 'Added to wishlist',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () =>
                _showCopyLinkDialog(context, product.link),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Product Image
            if (product.thumbnail != null)
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade200,
                child: Image.network(
                  product.thumbnail!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image,
                            size: 100,
                            color:
                                Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                              color:
                                  Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  loadingBuilder: (context, child,
                      loadingProgress) {
                    if (loadingProgress == null)
                      return child;
                    return Center(
                      child:
                          CircularProgressIndicator(
                        value: loadingProgress
                                    .expectedTotalBytes !=
                                null
                            ? loadingProgress
                                    .cumulativeBytesLoaded /
                                loadingProgress
                                    .expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image,
                          size: 100,
                          color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No image available',
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
                    product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  if (product.price != null)
                    Container(
                      padding: const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: Theme.of(context)
                                .primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.price!,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight:
                                  FontWeight.bold,
                              color: Theme.of(context)
                                  .primaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange
                              .withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors
                                .orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Price not available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors
                                  .orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Source
                  if (product.source != null)
                    Card(
                      elevation: 0,
                      color: Colors
                          .grey.shade100,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.store,
                                size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Available at',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors
                                          .grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 2),
                                  Text(
                                    product.source!,
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Description
                  if (product.snippet != null)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
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
                            product.snippet!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors
                                  .grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Product Link
                  if (product.link.isNotEmpty)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Link',
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
                                  12),
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
                                  product.link,
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
                                          text: product
                                              .link));
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Link copied!'),
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

                  // View Product Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL(context),
                      icon: const Icon(Icons.open_in_new,
                          size: 24),
                      label: const Text(
                        'View Product',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context)
                                .primaryColor,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Copy Link Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                              text: product.link),
                        );
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Link copied to clipboard!'),
                            backgroundColor:
                                Colors.green,
                            duration: Duration(
                                seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text(
                          'Copy Product Link'),
                      style: OutlinedButton
                          .styleFrom(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}