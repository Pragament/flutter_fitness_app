import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../model/pantry_item.dart';
import '../provider/providers.dart';

class PantryItemNotifier extends StateNotifier<List<PantryItem>> {
  PantryItemNotifier() : super([]);

  final Set<String> _modifiedItems = {};

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
    print("Click to add it to pantry");
    loadItems();
    state = List.from(box.values);
  }

  // Delete an item by ID
  Future<void> deleteItem(String id) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    await box.delete(id);
    state = List.from(box.values);
  }

  void incrementQuantity(WidgetRef ref, int index) {
    if (index >= 0 && index < state.length) {
      final updatedItem = state[index].copyWith(
        quantity: state[index].quantity + 1,
        lastModified: DateTime.now(),
      );
      _handleModification(ref, updatedItem);
    }
  }

  // Decrement quantity
  void decrementQuantity(WidgetRef ref, int index) {
    if (index >= 0 && index < state.length && state[index].quantity > 0) {
      final updatedItem = state[index].copyWith(
        quantity: state[index].quantity - 1,
        lastModified: DateTime.now(),
      );
      _handleModification(ref, updatedItem);
    }
  }

  // Save updated item
  Future<void> saveUpdatedItem(WidgetRef ref, PantryItem updatedItem) async {
    _modifiedItems.remove(updatedItem.id); // Mark item as saved
    await _saveToHive(updatedItem);
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item
    ];
    ref.read(filterSortProvider.notifier).toggleShoppingMode();
  }

  // Save updated item
  Future<void> saveUpdatedItemFromButton(PantryItem updatedItem) async {
    _modifiedItems.remove(updatedItem.id); // Mark item as saved
    await _saveToHive(updatedItem);
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item
    ];
  }

  Future<void> _saveToHive(PantryItem item) async {
    var box = await Hive.openBox<PantryItem>('pantryBox');
    await box.put(item.id, item);
  }

  // Handle item modification
  void _handleModification(WidgetRef ref, PantryItem updatedItem) {
    final isShoppingMode = ref.read(filterSortProvider.notifier).isShoppingMode;

    if (isShoppingMode) {
      saveUpdatedItem(ref, updatedItem); // Automatically save in shopping mode

    } else {
      _modifiedItems.add(updatedItem.id); // Mark as unsaved
      state = [
        for (final item in state)
          if (item.id == updatedItem.id) updatedItem else item
      ];
    }
  }

  // Check if an item has unsaved changes
  bool isModified(String id) {
    return _modifiedItems.contains(id);
  }

}
