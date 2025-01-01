// Necessary Imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:just_another_workout_timer/layouts/product_item_screen.dart';
import 'package:uuid/uuid.dart';
import '../model/pantry_item.dart'; // Model for PantryItem
import '../model/product_item.dart'; // Model for ProductItem
import 'package:http/http.dart' as http;
import '../provider/providers.dart';


class PantryItemScreen extends ConsumerWidget {
  // Text Controller for Search
  final TextEditingController _searchController = TextEditingController();
  PantryItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Watching state from providers
    final pantryItems = ref.watch(pantryItemsProvider);

    final filterSortState = ref.watch(filterSortProvider);

    final products = ref.watch(productsProvider);

    final filteredProducts = filterSortState['filteredProducts'] as List<ProductItem>;


    // Extracting filtered items/products
    List<PantryItem> filteredPantryItems = filterSortState['filteredItems'];


    // Placeholder lists for items/products
    List<PantryItem> _items = pantryItems.isNotEmpty
        ? pantryItems
        : ref.watch(filterSortProvider)['filteredItems'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pantry Items"),
        actions: [
          // Dropdown for sorting criteria
          DropdownButton<String>(
            value: filterSortState['sortCriteria']==''? null : filterSortState['sortCriteria'],
            hint: const Text("Select Sort By"),
            items: ['Name', 'Stock Value', 'Last Modified'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              ref.read(filterSortProvider.notifier).setSortCriteria(value!);
              ref.read(filterSortProvider.notifier).filterPantryItems(_items);
              ref.read(filterSortProvider.notifier).filterProducts(products);
            },
          ),
          // Switch for toggling shopping mode
          Switch(
            value: filterSortState['isShoppingMode'],
            onChanged: (value) {
              ref.read(filterSortProvider.notifier).toggleShoppingMode();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
                ref.read(filterSortProvider.notifier).filterPantryItems(_items);
                ref.read(filterSortProvider.notifier).filterProducts(products);
              },

              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.text = "";
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // List of Items or Products
          Expanded(
            child: filteredPantryItems.isNotEmpty
              ? _buildPantryList(filteredPantryItems, ref)
              : filteredProducts.isNotEmpty
                ? _buildProductList(filteredProducts, ref)
                : Center(
                child: ElevatedButton(
                    onPressed: () {
                      print("Clickeed");
                        final newItem = PantryItem(
                            id: const Uuid().v4(),
                            name: ref.read(searchQueryProvider.notifier).state,
                            imageUri: "",
                            quantity: 1,
                            unit: "Count",
                            lastModified: DateTime.now()
                        );
                      ref.read(pantryItemsProvider.notifier).addItem(newItem);
                      ref.read(searchQueryProvider.notifier).state = "";
                        filteredPantryItems = filterSortState['filteredItems'];
                    },
                    child: Text("Click to add it to pantry")
                )
            ),
          ),
        ],
      ),
    );
  }

  // Build the Pantry List
  Widget _buildPantryList(List<PantryItem> pantryItems, WidgetRef ref) {
    return pantryItems.isEmpty
    ? Center(child: Text("No items available."))
    : ListView.builder(
      itemCount: pantryItems.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[100],
          ),
          child: InkWell(
            onLongPress: () =>
                _showDeleteConfirmationDialog(ref, context, pantryItems[index].id),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10,),
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: pantryItems[index].imageUri.isNotEmpty
                      ? Image.network(
                    pantryItems[index].imageUri,
                    width: 40,
                  ) : Icon(Icons.shopping_bag, size: 40,),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        pantryItems[index].name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  ref
                                      .read(pantryItemsProvider.notifier)
                                      .decrementQuantity(ref, index);
                                }
                              ),
                              Text(pantryItems[index].quantity.toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => ref
                                    .read(pantryItemsProvider.notifier)
                                    .incrementQuantity(ref, index),
                              ),

                            ],
                          ),
                          DropdownButton<String>(
                            value: pantryItems[index].unit,
                            items: ['Count', 'Grams', 'Kg'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final updatedItem = pantryItems[index].copyWith(unit: value);
                                ref.read(pantryItemsProvider.notifier).saveUpdatedItem(updatedItem);
                              }
                            },
                          ),
                          // !ref.read(filterSortProvider.notifier).isShoppingMode
                               IconButton(
                            icon: const Icon(Icons.save, size: 25,),
                            onPressed: () => ref
                                .read(pantryItemsProvider.notifier)
                                .saveUpdatedItem(pantryItems[index]),
                          )
                              // : SizedBox(width: 25,),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  // Navigator.pop(context);
                }

            ),
          ),
        );
      },
    );
  }

  // Confirmation Dialog for Deletion
  void _showDeleteConfirmationDialog(WidgetRef ref, BuildContext context, String index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Confirmation"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                ref.read(pantryItemsProvider.notifier).deleteItem(index);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}




