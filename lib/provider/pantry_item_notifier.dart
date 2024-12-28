import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../model/pantry_item.dart';
import '../provider/providers.dart';

class PantryItemNotifier extends StateNotifier<List<PantryItem>> {
  PantryItemNotifier() : super([]);

  // Load items from the Hive box
  Future<void> loadItems() async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    state = List.from(box.values); // Create a new list to trigger state update
  }

  // Add a new item to the pantry
  Future<void> addItem(PantryItem item) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    final newItem = item.copyWith(id: const Uuid().v4()); // Assign a unique ID
    await box.put(newItem.id, newItem);
    state = List.from(box.values);
  }

  // Delete an item by ID
  Future<void> deleteItem(String id) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    await box.delete(id);
    state = List.from(box.values);
  }

  void incrementQuantity(WidgetRef ref, int index) async {
    if (index >= 0 && index < state.length) {
      final updatedItem = state[index].copyWith(
        quantity: state[index].quantity + 1,
        lastModified: DateTime.now(),
      );
      if (ref.read(filterSortProvider.notifier).isShoppingMode) {
        await _saveToHive(updatedItem);
      }
      state = [
        for (final item in state)
          if (item.id == updatedItem.id) updatedItem else item
      ];
    }
  }

  void decrementQuantity(WidgetRef ref, int index) async {
    if (index >= 0 && index < state.length && state[index].quantity > 0) {
      final updatedItem = state[index].copyWith(
        quantity: state[index].quantity - 1,
        lastModified: DateTime.now(),
      );
      if (ref.read(filterSortProvider.notifier).isShoppingMode) {
        await _saveToHive(updatedItem);
      }
      state = [
        for (final item in state)
          if (item.id == updatedItem.id) updatedItem else item
      ];
    }
  }


  void saveUpdatedItem(PantryItem updatedItem) {
    final updatedList = state.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    state = updatedList;
    _saveToHive(updatedItem);
  }

  Future<void> _saveToHive(PantryItem item) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    await box.put(item.id, item);
  }
}
