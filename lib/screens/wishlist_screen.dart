import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/product_card.dart';
import '../models/product_model.dart';
import '../services/local_notification_service.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() =>
      _WishlistScreenState();
}

class _WishlistScreenState
    extends State<WishlistScreen> {
  // Category options (for grouping)
  static const List<String> _categoryOptions = [
    'All',
    'Uncategorized',
    'Phones',
    'Laptops',
    'Accessories',
    'For later',
    'Gift',
    'Other',
  ];

  String _selectedCategory = 'All';

  Future<void> _editNoteDialog(
    BuildContext context, {
    required String userId,
    required Product product,
    required WishlistProvider wishlistProvider,
  }) async {
    final controller = TextEditingController(text: product.note ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Add a note about this product (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final note = controller.text.trim();
              await wishlistProvider.updateNote(
                  userId, product, note);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text('Note updated'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCategorySheet(
    BuildContext context, {
    required String userId,
    required Product product,
    required WishlistProvider wishlistProvider,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final currentCategory =
            product.category ?? 'Uncategorized';
        final options = _categoryOptions
            .where((c) => c != 'All')
            .toList();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Select category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...options.map((cat) {
                final isSelected = cat == currentCategory;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(cat),
                  onTap: () async {
                    final newCategory =
                        (cat == 'Uncategorized')
                            ? null
                            : cat;
                    await wishlistProvider.updateCategory(
                        userId, product, newCategory);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                              'Category set to ${cat == 'Uncategorized' ? 'None' : cat}'),
                          duration: const Duration(
                              seconds: 1),
                        ),
                      );
                    }
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();
    final wishlistProvider =
        context.watch<WishlistProvider>();
    final notificationProvider =
        context.watch<NotificationProvider>();
    final user = authProvider.user;

    final allItems = wishlistProvider.wishlist;

    List<Product> filtered = allItems;
    if (_selectedCategory != 'All') {
      if (_selectedCategory == 'Uncategorized') {
        filtered = allItems
            .where((p) =>
                p.category == null || p.category!.isEmpty)
            .toList();
      } else {
        filtered = allItems
            .where(
                (p) => p.category == _selectedCategory)
            .toList();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset demo prices',
            onPressed: () {
              context
                  .read<WishlistProvider>()
                  .resetPriceDropSimulation();
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                      'Prices reset to original (demo).'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.price_change),
            tooltip: 'Simulate Price Drop (demo)',
            onPressed: () async {
              final wishlistProvider =
                  context.read<WishlistProvider>();

              final count =
                  await wishlistProvider.simulatePriceDropForAll();

              // In-app notifications
              for (final product
                  in wishlistProvider.wishlist) {
                final productId =
                    product.link.hashCode.toString();
                final oldPrice =
                    wishlistProvider.getOldPrice(productId);
                final newPrice = product.priceValue;

                if (oldPrice != null &&
                    newPrice != null &&
                    newPrice < oldPrice) {
                  notificationProvider
                      .addPriceDropNotification(
                    product,
                    oldPrice,
                    newPrice,
                  );
                }
              }

              // Device-level (system) notification
              await LocalNotificationService
                  .showPriceDropSummary(
                changedCount: count,
              );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    count == 0
                        ? 'No prices to update.'
                        : 'Price dropped on $count item${count == 1 ? '' : 's'} (demo).',
                  ),
                  duration:
                      const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: allItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your wishlist is empty',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Category chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8),
                  child: Row(
                    children:
                        _categoryOptions.map((cat) {
                      final selected =
                          _selectedCategory == cat;
                      return Padding(
                        padding:
                            const EdgeInsets.only(
                                right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory =
                                  cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),

                // Grouped / filtered wishlist
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder:
                        (context, index) {
                      final product = filtered[index];
                      final productId =
                          product.link.hashCode
                              .toString();
                      final oldPrice =
                          wishlistProvider
                              .getOldPrice(
                                  productId);

                      final categoryLabel =
                          product.category ??
                              'Uncategorized';

                      return Column(
                        children: [
                          ProductCard(
                            product: product,
                            isInWishlist: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(
                                    product: product,
                                  ),
                                ),
                              );
                            },
                            onWishlistTap: () {
                              if (user == null)
                                return;
                              wishlistProvider
                                  .toggleWishlist(
                                user.uid,
                                product,
                              );
                            },
                          ),

                          // PRICE DROP BANNER (demo)
                          if (oldPrice != null &&
                              product.priceValue !=
                                  null &&
                              product.priceValue! <
                                  oldPrice)
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets
                                        .all(8),
                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .green.shade50,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              8),
                                  border:
                                      Border.all(
                                    color: Colors
                                        .green
                                        .shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .arrow_downward,
                                      color: Colors
                                          .green
                                          .shade700,
                                      size: 18,
                                    ),
                                    const SizedBox(
                                        width: 8),
                                    Expanded(
                                      child: Text(
                                        'Price dropped from ৳${oldPrice.toStringAsFixed(0)} to ${product.price ?? '৳${product.priceValue!.toStringAsFixed(0)}'}',
                                        style:
                                            TextStyle(
                                          color: Colors
                                              .green
                                              .shade800,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Category row
                          Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 24,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.category,
                                    size: 18),
                                const SizedBox(
                                    width: 8),
                                Expanded(
                                  child: Text(
                                    'Category: $categoryLabel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors
                                          .grey
                                          .shade700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      user == null
                                          ? null
                                          : () =>
                                              _editCategorySheet(
                                                context,
                                                userId: user
                                                    .uid,
                                                product:
                                                    product,
                                                wishlistProvider:
                                                    wishlistProvider,
                                              ),
                                  child:
                                      const Text(
                                          'Change'),
                                ),
                              ],
                            ),
                          ),

                          // Note section
                          Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .center,
                              children: [
                                const Icon(
                                    Icons.note,
                                    size: 18),
                                const SizedBox(
                                    width: 8),
                                Expanded(
                                  child: Text(
                                    (product.note ==
                                                null ||
                                            product.note!
                                                .isEmpty)
                                        ? 'Add a note...'
                                        : product
                                            .note!,
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontStyle: (product
                                                      .note ==
                                                  null ||
                                              product.note!
                                                  .isEmpty)
                                          ? FontStyle
                                              .italic
                                          : FontStyle
                                              .normal,
                                      color: (product
                                                      .note ==
                                                  null ||
                                              product.note!
                                                  .isEmpty)
                                          ? Colors
                                              .grey
                                              .shade600
                                          : Colors
                                              .grey
                                              .shade800,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      user == null
                                          ? null
                                          : () =>
                                              _editNoteDialog(
                                                context,
                                                userId: user
                                                    .uid,
                                                product:
                                                    product,
                                                wishlistProvider:
                                                    wishlistProvider,
                                              ),
                                  child:
                                      const Text(
                                          'Edit'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}