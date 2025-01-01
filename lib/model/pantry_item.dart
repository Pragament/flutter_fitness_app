import 'package:hive/hive.dart';

part 'pantry_item.g.dart'; // Required for Hive type adapters

@HiveType(typeId: 0)
class PantryItem {
  @HiveField(0)
  final String id; // Unique identifier

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String imageUri;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final DateTime lastModified;

  @HiveField(6)
  final bool modified;

  PantryItem({
    required this.id,
    required this.name,
    required this.imageUri,
    required this.quantity,
    required this.unit,
    required this.lastModified,
    required this.modified
  });

  PantryItem copyWith({
    String? id,
    String? name,
    String? imageUri,
    int? quantity,
    String? unit,
    DateTime? lastModified,
    bool? modified,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUri: imageUri ?? this.imageUri,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lastModified: lastModified ?? this.lastModified,
      modified: modified ?? this.modified
    );
  }
}