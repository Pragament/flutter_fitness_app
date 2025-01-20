import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_another_workout_timer/provider/providers.dart';
import '../model/pantry_item.dart';
import '../model/product_item.dart';

class FilterSortNotifier extends StateNotifier<Map<String, dynamic>> {
  final Ref ref;

  FilterSortNotifier({required this.ref})
      : super({
    'sortCriteria': '',
    'isProductMode': false,
    'isShoppingMode': false,
    'filteredItems': ref.watch(pantryItemsProvider),
    'filteredProducts': ref.watch(productsProvider),
  }) {
    // Listen to changes in the search query and trigger filtering
    ref.listen<String>(searchQueryProvider, (_, searchQuery) {
      updateSearchQuery(searchQuery);
    });
  }

  String _searchQuery = '';

  bool get isProductMode => state['isProductMode'];
  bool get isShoppingMode => state['isShoppingMode'];


  /// Updates the search query and triggers filtering
  void updateSearchQuery(String query) {
    _searchQuery = query;
    // Trigger filtering based on the new query
    final pantryItems = state['pantryItems'] ?? <PantryItem>[];
    final products = state['products'] ?? <ProductItem>[];
    filterAndSortItems(pantryItems, products);
  }

  void toggleProductMode() {
    state = {
      ...state,
      'isProductMode': !state['isProductMode'],
    };
    // Reapply filtering and sorting
    filterAndSortItems(
      state['pantryItems'] ?? <PantryItem>[],
      state['products'] ?? <ProductItem>[],
    );
  }

  void toggleShoppingMode() {
    print("Toggled");
    state = {
      ...state,
      'isShoppingMode': !state['isShoppingMode'],
    };
  }

  void setSortCriteria(String criteria) {
    state = {
      ...state,
      'sortCriteria': criteria,
    };
    // Reapply filtering and sorting
    filterAndSortItems(
      state['pantryItems'] ?? <PantryItem>[],
      state['products'] ?? <ProductItem>[],
    );
  }

  void filterAndSortItems(List<PantryItem> pantryItems, List<ProductItem> products) {
    if (state['isProductMode']) {
      filterProducts(products);
    } else {
      filterPantryItems(pantryItems);
    }
  }

  void filterPantryItems(List<PantryItem> items) {
    List<PantryItem> filtered = _searchQuery.isEmpty
        ? List.from(items)
        : items.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    switch (state['sortCriteria']) {
      case 'Name -- Asc to Desc':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name -- Desc to Asc':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Stock Value -- Asc to Desc':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'Stock Value -- Desc to Asc':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Last Modif.  -- Asc to Desc':
        filtered.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
      case 'Last Modif.  -- Desc to Asc':
        filtered.sort((a, b) => a.lastModified.compareTo(b.lastModified));
        break;
    }

    state = {
      ...state,
      'filteredItems': filtered,
    };
  }

  void filterProducts(List<ProductItem> products) {
    List<ProductItem> filtered = _searchQuery.isEmpty
        ? List.from(products)
        : products.where((product) => product.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (state['sortCriteria'] == 'Name -- Asc to Desc') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (state['sortCriteria'] == 'Name -- Desc to Asc') {
      filtered.sort((a, b) => b.name.compareTo(a.name));
    }

    state = {
      ...state,
      'filteredProducts': filtered,
    };
  }
}
