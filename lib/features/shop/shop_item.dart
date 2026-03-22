class ItemStats {
  final int hunger;
  final int health;

  ItemStats({required this.hunger, required this.health});

  factory ItemStats.fromJson(Map<String, dynamic> json) {
    return ItemStats(
      hunger: json['hunger'] ?? 0,
      health: json['health'] ?? 0,
    );
  }
}

class ShopItem {
  final int id;
  final String tag;
  final String name;
  final int price;
  final String description;
  final ItemStats stats;

  ShopItem({
    required this.id,
    required this.tag,
    required this.name,
    required this.price,
    required this.description,
    required this.stats,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      tag: json['tag'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      stats: ItemStats.fromJson(json['stats']),
    );
  }

  // Future helper once our artist gets more done
  String get assetPath {
    String sanitizedName = name.toLowerCase().replaceAll(' ', '_');
    return 'assets/images/${tag}_$sanitizedName.png';
  }
}