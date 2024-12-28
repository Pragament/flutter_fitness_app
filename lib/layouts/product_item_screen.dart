import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/pantry_item.dart';
import '../model/product_item.dart';
import '../provider/providers.dart';

class ProductItemScreen extends ConsumerWidget {
  final TextEditingController _searchController = TextEditingController();

  ProductItemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final filterSortState = ref.watch(filterSortProvider);

    final filteredProducts = filterSortState['filteredProducts'] as List<ProductItem>;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pantry Items"),
        actions: [
          DropdownButton<String>(
            value: filterSortState['sortCriteria']==''? null : filterSortState['sortCriteria'],
            hint: const Text("Select Sort By"),
            items: ['Name'].map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
            onChanged: (value) {
              ref.read(filterSortProvider.notifier).setSortCriteria(value!);
              ref.read(filterSortProvider.notifier).filterProducts(products);
            },
          ),
          SizedBox(width: 12,)
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),
              ),
              onChanged: (value) {
                ref.read(filterSortProvider.notifier).filterProducts(products);
                ref.read(searchQueryProvider.notifier).state = value;
                // ref.read(filterSortProvider.notifier).filterProducts(products);
              },
            ),
          ),
          Expanded(
            child: _buildProductList(filteredProducts.isEmpty? ref.watch(productsProvider): filteredProducts, ref)

          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<ProductItem> products, WidgetRef ref) {
    print("Length: ${products.length}");
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(7),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[100],
          ),
          child: ListTile(
            leading: Image.network(
              products[index].imageUrl,
              width: 40,
            ),
            title: Text(products[index].name),
            trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  ref.watch(pantryItemsProvider);
                  ref.read(productsProvider.notifier)
                      .addProductToPantry(ref, products[index]);
                  ref.read(filterSortProvider.notifier).toggleProductMode();
                  Navigator.pop(context);
                }

            ),
          ),
        );
      },
    );
  }

}
