import 'package:hive/hive.dart';

part 'pantry_item.g.dart';

@HiveType(typeId: 0)
class PantryItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  String unit;

  @HiveField(3)
  DateTime lastModified;

  @HiveField(4)
  final String imageUri;

  PantryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lastModified,
    required this.imageUri,
  });
}
