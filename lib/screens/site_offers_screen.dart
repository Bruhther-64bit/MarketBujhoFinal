import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/offer_scraper_service.dart';
import '../widgets/product_card.dart';
import 'offer_details_screen.dart';

class SiteOffersScreen extends StatefulWidget {
  final String siteKey; // 'startech', 'techland', etc.
  final String title;

  const SiteOffersScreen({
    Key? key,
    required this.siteKey,
    required this.title,
  }) : super(key: key);

  @override
  State<SiteOffersScreen> createState() =>
      _SiteOffersScreenState();
}

class _SiteOffersScreenState
    extends State<SiteOffersScreen> {
  final OfferScraperService _offerScraperService =
      OfferScraperService();

  bool _isLoading = false;
  String? _errorMessage;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadSiteOffers();
  }

  Future<void> _loadSiteOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _products = [];
    });

    try {
      List<Product> results = [];

      switch (widget.siteKey) {
        case 'startech':
          results =
              await _offerScraperService.fetchStartechOffers();
          break;
        case 'techland':
          results =
              await _offerScraperService.fetchTechlandOffers();
          break;
        case 'applegadgets':
          results = await _offerScraperService
              .fetchAppleGadgetsOffers();
          break;
        case 'ryans':
          results =
              await _offerScraperService.fetchRyansOffers();
          break;
        case 'sumashtech':
          results =
              await _offerScraperService.fetchSumashtechOffers();
          break;
        default:
          results = [];
      }

      setState(() {
        _products = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to load offers. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();
    final wishlistProvider =
        context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSiteOffers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading offers...',
                    style: TextStyle(
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadSiteOffers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 80,
                              color: Colors
                                  .grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No offers found',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try again later.',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSiteOffers,
                      child: ListView.builder(
                        itemCount: _products.length,
                        padding:
                            const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final product =
                              _products[index];
                          final productId =
                              product.link.hashCode
                                  .toString();
                          final isInWishlist =
                              wishlistProvider
                                  .isInWishlist(
                                      productId);

                          return ProductCard(
                            product: product,
                            isInWishlist: isInWishlist,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OfferDetailsScreen(
                                    offer: product,
                                  ),
                                ),
                              );
                            },
                            onWishlistTap: () {
                              final userId =
                                  authProvider.user!.uid;
                              wishlistProvider
                                  .toggleWishlist(
                                      userId, product);
                            },
                            showCompare: false,
                          );
                        },
                      ),
                    ),
    );
  }
}