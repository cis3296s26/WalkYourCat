import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseService {
  // Singleton Alert!?
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static const _firebaseDatabaseUrl = String.fromEnvironment('FIREBASE_DB_URL');

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          databaseURL: String.fromEnvironment('FIREBASE_DB_URL'),
        ),
      );
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Inventory table
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
        happiness INTEGER NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    // Challenges table
    await db.execute('''
      CREATE TABLE active_challenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        targetValue INTEGER NOT NULL,
        progress INTEGER NOT NULL,
        rewardCoins INTEGER NOT NULL,
        metaTarget TEXT
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        completionCount INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  FirebaseDatabase get firebaseDb {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _firebaseDatabaseUrl,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
