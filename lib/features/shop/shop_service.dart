import 'dart:convert';
import 'package:flutter/services.dart';
import './shop_item.dart';

class ShopService {
  static Future<List<ShopItem>> loadShopAssets() async {
    final String response = await rootBundle.loadString('shop_items.json');
    
    final Map<String, dynamic> data = json.decode(response);
    
    return (data['items'] as List)
        .map((item) => ShopItem.fromJson(item))
        .toList();
  }
}