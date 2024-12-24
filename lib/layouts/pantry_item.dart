import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../model/pantry_item.dart';
import '../model/product_item.dart'; // Make sure this matches your actual file name
import 'package:http/http.dart' as http;

class PantryItemScreen extends StatefulWidget {
  const PantryItemScreen({Key? key}) : super(key: key);

  @override
  State<PantryItemScreen> createState() => _PantryItemState();
}

class _PantryItemState extends State<PantryItemScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<PantryItem> _items = [];
  List<PantryItem> _filteredItems = [];
  List<ProductItem> _products = [];
  List<ProductItem> _filteredProducts = [];

  bool isProductMode = false;
  bool isShoppingMode = false;
  String sortCriteria = 'Name';
  String quantityCriteria = 'Count';

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadProducts();

    _searchController.addListener(() {
      _filterAndSortItems(_searchController.text);
    });
  }

  void _filterAndSortItems(String query) {
    if (isProductMode) {
      _filterProducts(query);
    } else {
      _filterPantryItems(query);
    }
  }

  void _filterPantryItems(String query) {
    List<PantryItem> filtered = query.isEmpty
        ? _items
        : _items.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();

    switch (sortCriteria) {
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Stock Value':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'Last Modified':
        filtered.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = query.isEmpty
          ? _products
          : _products.where((product) => product.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _loadItems() async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    setState(() {
      _items = box.values.toList();
      _filteredItems = _items;
    });
  }

  Future<void> _loadProducts() async {
    var box = await Hive.openBox<ProductItem>('productsBox');
    if (box.isEmpty) {
      await fetchAndCacheProducts();
    }
    setState(() {
      _products = box.values.toList();
      _filteredProducts = _products;
    });
  }

  Future<void> fetchAndCacheProducts() async {
    final response = await http.get(Uri.parse(
        'https://staticapis.pragament.com/products/vegetables_fruits_minified.json'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      List<ProductItem> products =
      jsonData.map((item) => ProductItem.fromJson(item)).toList();

      var box = await Hive.openBox<ProductItem>('productsBox');
      await box.clear();
      await box.addAll(products);

      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> _addProductToPantry(ProductItem product) async {
    PantryItem newItem = PantryItem(
      name: product.name,
      quantity: 1,
      unit: 'Count',
      lastModified: DateTime.now(),
      imageUri: product.imageUrl,
    );
    await _saveItem(newItem);
  }

  Future<void> _saveItem(PantryItem item) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    await box.add(item);
    await _loadItems();
  }

  Future<void> _deleteItem(int index) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    await box.deleteAt(index);
    await _loadItems();
  }

  void _incrementQuantity(int index) {
    setState(() {
      _filteredItems[index].quantity++;
      // Save updated item back to Hive
      if(isShoppingMode) {
        _saveUpdatedItem(_filteredItems[index]);
      }

    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_filteredItems[index].quantity > 0) {
        _filteredItems[index].quantity--;
        // Save updated item back to Hive
        if(isShoppingMode) {
          _saveUpdatedItem(_filteredItems[index]);
        }
      }
    });
  }

  Future<void> _saveUpdatedItem(PantryItem item) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');

    int index = box.values.toList().indexOf(item);

    if (index != -1) {
      item.lastModified = DateTime.now(); // Update last modified date
      await box.putAt(index, item); // Update existing item in Hive
    }

    // Reload items after updating
    await _loadItems();
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Confirmation"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteItem(index); // Call the delete function
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pantry Items"),
        actions: [
          DropdownButton<String>(
            value: sortCriteria,
            items: ['Name', 'Stock Value', 'Last Modified'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sortCriteria = value!;
                _filterAndSortItems(_searchController.text);
              });
            },
          ),
          Switch(
            value: isShoppingMode,
            onChanged: (value) {
              setState(() {
                isShoppingMode = value;
                _filterAndSortItems(_searchController.text);
              });
            },
          ),
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
                suffixIcon: InkWell(
                  onTap: () {
                    setState(() {
                      isProductMode = !isProductMode;
                      _searchController.text = _searchController.text;
                    });
                  },
                    child: const Icon(Icons.add)
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: isProductMode
                ? ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.all(7),
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                  ),
                  child: ListTile(
                    leading: Image.network(
                      _filteredProducts[index].imageUrl,
                      width: 40,
                    ),
                    title: Text(_filteredProducts[index].name),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addProductToPantry(_filteredProducts[index]),
                    ),
                  ),
                );
              },
            )
            : Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[100],
                    ),
                    child: InkWell(
                      onLongPress: () {
                        _showDeleteConfirmationDialog(index);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 15,),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              _filteredItems[index].imageUri,
                              width: 40,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _filteredItems[index].name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Style for item name
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () => _decrementQuantity(index),
                                        ),
                                        Text('${_filteredItems[index].quantity}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => _incrementQuantity(index),
                                        ),
                                      ],
                                    ),
                                    DropdownButton<String>(
                                      value: _filteredItems[index].unit,
                                      items: ['Count', 'Grams', 'Kg'].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _filteredItems[index].unit = value!;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.save),
                                      onPressed: () => _saveUpdatedItem(_filteredItems[index]),
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
              ),
            )

          ),
        ],
      ),
    );
  }
}
