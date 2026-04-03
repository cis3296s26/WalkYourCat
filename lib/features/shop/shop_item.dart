class ItemStats {
  final int hunger;
  final int health;
  final int happiness;

  ItemStats({required this.hunger, required this.health, required this.happiness});

  factory ItemStats.fromJson(Map<String, dynamic> json) {
    return ItemStats(
      hunger: json['hunger'] ?? 0,
      health: json['health'] ?? 0,
      happiness: json['happiness'] ?? 0,

    );
  }
}

class ShopItem {
  final int id;
  final String? image; // Optional image path
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

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      image: json['image'],
      tag: json['tag'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      stats: ItemStats.fromJson(json['stats']),
    );
  }

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
        happiness: map['happiness'] ?? 0,
      ),
    );
  }

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
      'happiness': stats.happiness,
      'quantity': quantity,
    };
  }

  // Future helper once our artist gets more done
  String get assetPath {
    String sanitizedName = name.toLowerCase().replaceAll(' ', '_');
    return 'assets/images/${tag}_$sanitizedName.png';
  }
}