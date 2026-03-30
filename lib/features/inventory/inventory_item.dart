import '../shop/shop_item.dart';

class InventoryItem {
  final ShopItem item;
  final int quantity;

  InventoryItem({required this.item, required this.quantity});
}

class ShopItem {
  final int id;
  final String? image;
  final String tag;
  final String name;
  final int price;
  final String description;
  final ItemStats stats;

  ShopItem({
    required this.id,
    required this.image,
    required this.tag,
    required this.name,
    required this.price,
    required this.description,
    required this.stats,
  });

  // Convert a Database row into a ShopItem
  factory ShopItem.fromMap(Map<String, dynamic> map) {
    return ShopItem(
      id: map['id'],
      image: map['image'],
      tag: map['tag'],
      name: map['name'],
      price: map['price'],
      description: map['description'],
      stats: ItemStats(
        hunger: map['hunger'] ?? 0,
        health: map['health'] ?? 0,
      ),
    );
  }

  // Flatten the object for SQLite
  Map<String, dynamic> toMap(int quantity) {
    return {
      'id': id,
      'image': image,
      'tag': tag,
      'name': name,
      'price': price,
      'description': description,
      'hunger': stats.hunger,
      'health': stats.health,
      'quantity': quantity,
    };
  }
}