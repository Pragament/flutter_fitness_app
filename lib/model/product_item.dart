import 'package:hive/hive.dart';

part 'product_item.g.dart'; // This will be generated

@HiveType(typeId: 1) // Use a unique typeId for Product
class ProductItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String imageUrl;

  ProductItem({required this.name, required this.imageUrl});

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      name: json['name'],
      imageUrl: 'https://staticapis.pragament.com/' + json['img'],
    );
  }
}
