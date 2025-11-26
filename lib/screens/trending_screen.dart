import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/offer_scraper_service.dart';
import '../widgets/product_card.dart';
import 'offer_details_screen.dart';
import 'site_offers_screen.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  @override
  State<TrendingScreen> createState() =>
      _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final OfferScraperService _offerScraperService =
      OfferScraperService();

  bool _isLoading = false;
  String? _errorMessage;
  List<_OfferSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadAllTrending();
  }

  Future<void> _loadAllTrending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sections = [];
    });

    try {
      // Fetch all 5 sites in parallel
      final results = await Future.wait<List<Product>>([
        _offerScraperService.fetchStartechOffers(),
        _offerScraperService.fetchTechlandOffers(),
        _offerScraperService.fetchAppleGadgetsOffers(),
        _offerScraperService.fetchRyansOffers(),
        _offerScraperService.fetchSumashtechOffers(),
      ]);

      final startech = results[0];
      final techland = results[1];
      final applegadgets = results[2];
      final ryans = results[3];
      final sumashtech = results[4];

      final sections = <_OfferSection>[
        _OfferSection(
          key: 'startech',
          title: 'Latest Offers in Startech',
          source: 'startech.com.bd',
          products: startech,
        ),
        _OfferSection(
          key: 'techland',
          title: 'Latest Offers in Techland',
          source: 'techlandbd.com',
          products: techland,
        ),
        _OfferSection(
          key: 'applegadgets',
          title: 'Latest Offers in Apple Gadgets',
          source: 'applegadgetsbd.com',
          products: applegadgets,
        ),
        _OfferSection(
          key: 'ryans',
          title: 'Latest Offers in Ryans',
          source: 'ryans.com',
          products: ryans,
        ),
        _OfferSection(
          key: 'sumashtech',
          title: 'Latest Offers in Sumash Tech',
          source: 'sumashtech.com',
          products: sumashtech,
        ),
      ];

      setState(() {
        _sections =
            sections.where((s) => s.products.isNotEmpty).toList();
      });

      if (_sections.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No trending offers found right now for any site.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to load trending offers. Please try again.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Trending Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllTrending,
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
                    'Loading trending offers...',
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
                          onPressed: _loadAllTrending,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _sections.isEmpty
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
                              'No trending offers found',
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
                      onRefresh: _loadAllTrending,
                      child: ListView.builder(
                        itemCount: _sections.length,
                        padding:
                            const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final section = _sections[index];
                          final products =
                              section.products.take(3).toList();

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Section header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        section.title,
                                        style:
                                            const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SiteOffersScreen(
                                              siteKey:
                                                  section.key,
                                              title:
                                                  section.title,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                          'See more'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Up to 3 offers for this section
                                ...products.map((product) {
                                  final productId =
                                      product.link.hashCode
                                          .toString();
                                  final isInWishlist =
                                      wishlistProvider
                                          .isInWishlist(
                                              productId);

                                  return ProductCard(
                                    product: product,
                                    isInWishlist:
                                        isInWishlist,
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
                                      final userId = authProvider
                                          .user!.uid;
                                      wishlistProvider
                                          .toggleWishlist(
                                        userId,
                                        product,
                                      );

                                      final nowInWishlist =
                                          wishlistProvider
                                              .isInWishlist(
                                                  productId);

                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            nowInWishlist
                                                ? 'Added to wishlist'
                                                : 'Removed from wishlist',
                                          ),
                                          duration:
                                              const Duration(
                                                  seconds:
                                                      1),
                                        ),
                                      );
                                    },
                                    showCompare: false,
                                  );
                                }).toList(),
                                const SizedBox(height: 8),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _OfferSection {
  final String key; // 'startech', 'techland', etc.
  final String title;
  final String source;
  final List<Product> products;

  _OfferSection({
    required this.key,
    required this.title,
    required this.source,
    required this.products,
  });
}