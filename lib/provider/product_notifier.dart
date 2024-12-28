// State Notifier for Products
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:just_another_workout_timer/provider/pantry_item_notifier.dart';
import 'package:just_another_workout_timer/provider/providers.dart';
import 'package:uuid/uuid.dart';
import '../model/pantry_item.dart';
import '../model/product_item.dart';

// State Notifier for Products
class ProductNotifier extends StateNotifier<List<ProductItem>> {
  ProductNotifier() : super([]);

  Future<void> loadProducts() async {
    var box = await Hive.openBox<ProductItem>('productsBox');
    if (box.isEmpty) {
      await fetchAndCacheProducts();
    }
    state = box.values.toList();
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
      state = products;
    } else {
      throw Exception('Failed to load products');
    }
  }
  Future<void> addProductToPantry(WidgetRef ref, ProductItem product) async {
    final pantryNotifier = ref.read(pantryItemsProvider.notifier);
    PantryItem newItem = PantryItem(
      id: const Uuid().v4(), // Generate a unique ID
      name: product.name,
      quantity: 1,
      unit: 'Count',
      lastModified: DateTime.now(),
      imageUri: product.imageUrl,
    );
    await pantryNotifier.addItem(newItem);
  }

}