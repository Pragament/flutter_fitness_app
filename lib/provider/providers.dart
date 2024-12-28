// Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_another_workout_timer/provider/pantry_item_notifier.dart';
import 'package:just_another_workout_timer/provider/product_notifier.dart';

import '../model/pantry_item.dart';
import '../model/product_item.dart';
import 'filter_sort_notifier.dart';

// Providers
final pantryItemsProvider =
StateNotifierProvider<PantryItemNotifier, List<PantryItem>>((ref) {
  return PantryItemNotifier()..loadItems();
});

final productsProvider =
StateNotifierProvider<ProductNotifier, List<ProductItem>>((ref) {
  return ProductNotifier()..loadProducts();
});

// Providers
final filterSortProvider = StateNotifierProvider<FilterSortNotifier, Map<String, dynamic>>((ref) {
  return FilterSortNotifier(ref: ref);
});


final searchQueryProvider = StateProvider<String>((ref) => "");
