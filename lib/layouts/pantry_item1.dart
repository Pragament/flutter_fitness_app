// Necessary Imports
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:just_another_workout_timer/layouts/product_item_screen.dart';
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

    // Extracting filtered items/products
    final List<PantryItem> filteredPantryItems = filterSortState['filteredItems'];

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
              },

              decoration: InputDecoration(
                hintText: "Search items...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    filterSortState['sortCriteria']='';
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductItemScreen()));
                  },
                  icon: const Icon(Icons.add),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // List of Items or Products
          Expanded(
            child: _buildPantryList(filteredPantryItems.isEmpty? ref.watch(pantryItemsProvider): filteredPantryItems, ref)
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
                  child: Image.network(
                    pantryItems[index].imageUri,
                    width: 40,
                  ),
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
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () => ref
                                .read(pantryItemsProvider.notifier)
                                .saveUpdatedItem(pantryItems[index]),
                          ),
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




