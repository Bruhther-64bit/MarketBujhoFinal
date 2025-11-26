import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;
  final bool isInWishlist;

  // NEW: comparison controls (optional)
  final bool showCompare;
  final bool isInCompare;
  final VoidCallback? onCompareTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onWishlistTap,
    this.isInWishlist = false,
    this.showCompare = false,
    this.isInCompare = false,
    this.onCompareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.thumbnail != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image, size: 40),
                        ),
                      )
                    : const Icon(Icons.image, size: 40),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.source != null)
                      Text(
                        product.source!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (product.price != null)
                      Text(
                        product.price!,
                        style: TextStyle(
                          color:
                              Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),

              // Wishlist + Compare buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isInWishlist
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isInWishlist
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: onWishlistTap,
                  ),
                  if (showCompare)
                    IconButton(
                      icon: Icon(
                        Icons.compare_arrows,
                        color: isInCompare
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : Colors.grey,
                      ),
                      tooltip: 'Add to compare',
                      onPressed: onCompareTap,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}