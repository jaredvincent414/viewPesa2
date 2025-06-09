// lib/database/dbhelper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_models.dart';
import '../models/user_models.dart';

class DBHelper {
  static Database? _database;
  static const String _dbName = 'viewpesa.db';
  static const int _dbVersion = 4; // Incremented to 4 for party column migration

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        sender TEXT NOT NULL,
        receiver TEXT NOT NULL,
        amount REAL NOT NULL,
        cost REAL NOT NULL,
        balance REAL NOT NULL,
        time TEXT NOT NULL,
        tags TEXT NOT NULL,
        party TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        phoneNumber TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN sender TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE transactions ADD COLUMN receiver TEXT NOT NULL DEFAULT ""');
      await db.execute('UPDATE transactions SET sender = party, receiver = party');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions RENAME TO transactions_old');
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          sender TEXT NOT NULL,
          receiver TEXT NOT NULL,
          amount REAL NOT NULL,
          cost REAL NOT NULL,
          balance REAL NOT NULL,
          time TEXT NOT NULL,
          tags TEXT NOT NULL,
          party TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO transactions (id, type, sender, receiver, amount, cost, balance, time, tags, party)
        SELECT id, type, sender, receiver, amount, cost, balance, time, tag AS tags, party
        FROM transactions_old
      ''');
      await db.execute('DROP TABLE transactions_old');
    }
    if (oldVersion < 4) {
      // Add party column if missing
      await db.execute('ALTER TABLE transactions ADD COLUMN party TEXT NOT NULL DEFAULT "Unknown"');
    }
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    try {
      await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting transaction: $e, Transaction: ${transaction.toMap()}');
      rethrow;
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'time DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'sender LIKE ? OR receiver LIKE ? OR tags LIKE ? OR party LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'time DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String phoneNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}