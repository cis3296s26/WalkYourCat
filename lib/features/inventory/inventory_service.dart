import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import './inventory_item.dart';
import '../shop/shop_item.dart';

class InventoryService {
  // Singleton Alert!?
  static final InventoryService instance = InventoryService._init();
  static Database? _database;

  InventoryService._init();

  /// Fetches or creates a new database and returns the connection
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  /// Creates a new database at the specified path and returns a connection
  Future<Database> _initDB(String filePath) async {
    String path;
    
    if (kIsWeb) {
      // Web uses a virtual path/indexedDB
      path = filePath; 
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// The initialization function used to generate the base of our app
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY,
        image TEXT,
        tag TEXT NOT NULL,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        description TEXT NOT NULL,
        hunger INTEGER NOT NULL,
        health INTEGER NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');
  }

  /// Add an item or increment quantity if it exists
  Future<void> addItem(ShopItem item) async {
    final db = await instance.database;

    // Check if item exists
    // This SQLite syntax is trash
    final maps = await db.query(
      'inventory',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [item.id],
    );

    if (maps.isNotEmpty) {
      // We already own the item so just increment
      int currentQty = maps.first['quantity'] as int;
      await db.update(
        'inventory',
        {'quantity': currentQty + 1},
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } else {
      // We dont own so insert new
      await db.insert('inventory', item.toMap(1));
    }
  }

  // Remove an item or decrement quantity
  Future<void> removeItem(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'inventory',
      columns: ['quantity'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      int currentQty = maps.first['quantity'] as int;
      if (currentQty > 1) {
        // We currently own more than one of this item so decrement
        await db.update(
          'inventory',
          {'quantity': currentQty - 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        // We are using out last so remove the item from the db
        await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  // Get all items in the inventory
  Future<List<InventoryItem>> fetchInventory() async {
    final db = await instance.database;
    final result = await db.query('inventory');

    return result.map((json) => InventoryItem(
      item: ShopItem.fromMap(json),
      quantity: json['quantity'] as int,
    )).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}