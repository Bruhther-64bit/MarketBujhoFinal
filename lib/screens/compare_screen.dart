import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/compare_provider.dart';
import 'product_details_screen.dart';

class CompareScreen extends StatelessWidget {
  final List<Product> products;

  const CompareScreen({
    Key? key,
    required this.products,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Limit to 4 items for readability
    final items = products.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear comparison',
            onPressed: () {
              context.read<CompareProvider>().clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: items.length < 2
          ? Center(
              child: Text(
                'Select at least two products to compare.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    _buildComparisonTable(context, items),
              ),
            ),
    );
  }

  Widget _buildComparisonTable(
      BuildContext context, List<Product> items) {
    final headerStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
            );

    const labelWidth = 120.0;

    Widget buildRow(String label, List<Widget> cells) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: headerStyle,
              ),
            ),
            ...cells
                .map(
                  (w) => SizedBox(
                    width: 200,
                    child: w,
                  ),
                )
                .toList(),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRow(
          'Title',
          items
              .map(
                (p) => Text(
                  p.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(),
        ),
        const Divider(),
        buildRow(
          'Price',
          items
              .map(
                (p) => Text(
                  p.price ?? 'N/A',
                  style: TextStyle(
                    color: p.priceValue != null
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
        const Divider(),
        buildRow(
          'Source',
          items
              .map(
                (p) => Text(
                  p.source ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade700),
                ),
              )
              .toList(),
        ),
        const Divider(),
        buildRow(
          'Description',
          items
              .map(
                (p) => Text(
                  p.snippet ?? '',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade700),
                ),
              )
              .toList(),
        ),
        const Divider(),
        buildRow(
          'Link',
          items
              .map(
                (p) => Text(
                  p.link,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        buildRow(
          'Action',
          items
              .map(
                (p) => ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(
                                product: p),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new,
                      size: 18),
                  label: const Text('View'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}