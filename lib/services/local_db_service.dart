import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/bet_model.dart';
import '../models/transaction_model.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, AppConstants.dbName);
    return openDatabase(
      fullPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        avatar_path TEXT,
        shekel_balance INTEGER NOT NULL DEFAULT 1000,
        total_won INTEGER NOT NULL DEFAULT 0,
        total_lost INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        emoji TEXT NOT NULL,
        price INTEGER NOT NULL,
        category TEXT NOT NULL,
        rarity TEXT NOT NULL DEFAULT 'comum',
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE user_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        purchased_at TEXT NOT NULL,
        UNIQUE(user_id, item_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        game_type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        payout INTEGER NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _seedItems(db);
  }

  static Future<void> _seedItems(Database db) async {
    const items = [
      (1, 'Coroa Dourada', 'Uma coroa majestosa banhada em ouro puro de Salomão', '👑', 500, 'acessório', 'raro'),
      (2, 'Diamante Azul', 'Um diamante precioso de cor azul profundo, achado no deserto', '💎', 1000, 'joia', 'épico'),
      (3, 'Estrela Brilhante', 'Uma estrela que nunca se apaga, símbolo de vitória', '⭐', 200, 'colecionável', 'comum'),
      (4, 'Troféu de Ouro', 'Para os maiores vencedores do cassino', '🏆', 2000, 'conquista', 'lendário'),
      (5, 'Chama Eterna', 'Uma chama que queima por toda a eternidade', '🔥', 300, 'colecionável', 'incomum'),
      (6, 'Foguete Espacial', 'Vá além das estrelas e das apostas', '🚀', 800, 'veículo', 'raro'),
      (7, 'Escudo Protetor', 'Proteja seus shekels com este escudo mágico', '🛡️', 600, 'proteção', 'incomum'),
      (8, 'Varinha Mágica', 'Talvez ela traga sorte nas apostas', '🪄', 750, 'especial', 'raro'),
      (9, 'Bolsa de Moedas', 'Mais espaço para guardar seus shekels', '👜', 400, 'utilitário', 'comum'),
      (10, 'Cristal Místico', 'Um cristal com poderes divinatórios misteriosos', '🔮', 1500, 'mágico', 'épico'),
      (11, 'Espada Sagrada', 'A espada dos guerreiros do templo de Jerusalém', '⚔️', 900, 'arma', 'raro'),
      (12, 'Livro Antigo', 'Contém os segredos dos antigos apostadores', '📜', 350, 'conhecimento', 'incomum'),
    ];

    for (final item in items) {
      await db.insert('items', {
        'id': item.$1,
        'name': item.$2,
        'description': item.$3,
        'emoji': item.$4,
        'price': item.$5,
        'category': item.$6,
        'rarity': item.$7,
        'is_available': 1,
      });
    }
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  static Future<void> createUser({
    required String id,
    required String username,
    required String displayName,
    required String email,
    required String passwordHash,
  }) async {
    final db = await _database;
    await db.insert('users', {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'password_hash': passwordHash,
      'shekel_balance': AppConstants.initialBalance,
      'total_won': 0,
      'total_lost': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _insertTransaction(
      db: db,
      userId: id,
      type: 'registration',
      amount: AppConstants.initialBalance,
      description: 'Bônus de registro - bem-vindo à ShekelStore!',
    );
  }

  static Future<String?> validateCredentials(
      String email, String passwordHash) async {
    final db = await _database;
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase(), passwordHash],
    );
    return rows.isEmpty ? null : rows.first['id'] as String;
  }

  static Future<bool> usernameExists(String username) async {
    final db = await _database;
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username.toLowerCase()],
    );
    return rows.isNotEmpty;
  }

  static Future<bool> emailExists(String email) async {
    final db = await _database;
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    return rows.isNotEmpty;
  }

  static Future<UserModel?> fetchProfile(String userId) async {
    final db = await _database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return _rowToUser(rows.first);
  }

  static Future<void> updateDisplayName(String userId, String name) async {
    final db = await _database;
    await db.update(
      'users',
      {'display_name': name},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<void> updateAvatarPath(String userId, String path) async {
    final db = await _database;
    await db.update(
      'users',
      {'avatar_path': path},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<void> adjustBalance(String userId, int delta) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE users SET shekel_balance = shekel_balance + ? WHERE id = ?',
      [delta, userId],
    );
  }

  static Future<void> incrementWon(String userId, int amount) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE users SET total_won = total_won + ? WHERE id = ?',
      [amount, userId],
    );
  }

  static Future<void> incrementLost(String userId, int amount) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE users SET total_lost = total_lost + ? WHERE id = ?',
      [amount, userId],
    );
  }

  // ── Items ──────────────────────────────────────────────────────────────────

  static Future<List<ItemModel>> fetchItems() async {
    final db = await _database;
    final rows =
        await db.query('items', where: 'is_available = 1', orderBy: 'price');
    return rows.map(_rowToItem).toList();
  }

  static Future<List<int>> fetchUserItemIds(String userId) async {
    final db = await _database;
    final rows = await db.query(
      'user_items',
      columns: ['item_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((r) => r['item_id'] as int).toList();
  }

  static Future<void> purchaseItem(
      String userId, int itemId, int price) async {
    final db = await _database;
    await db.insert('user_items', {
      'user_id': userId,
      'item_id': itemId,
      'purchased_at': DateTime.now().toIso8601String(),
    });
    await adjustBalance(userId, -price);
    await _insertTransaction(
      db: db,
      userId: userId,
      type: 'purchase',
      amount: -price,
      description: 'Compra de item #$itemId',
    );
  }

  // ── Bets ───────────────────────────────────────────────────────────────────

  static Future<void> recordBet({
    required String userId,
    required String gameType,
    required int amount,
    required String outcome,
    required int payout,
    Map<String, dynamic>? details,
  }) async {
    final db = await _database;
    await db.insert('bets', {
      'user_id': userId,
      'game_type': gameType,
      'amount': amount,
      'outcome': outcome,
      'payout': payout,
      'details': details != null ? jsonEncode(details) : null,
      'created_at': DateTime.now().toIso8601String(),
    });

    final delta = payout - amount;
    await adjustBalance(userId, delta);

    if (outcome == 'win') {
      await incrementWon(userId, payout);
    } else {
      await incrementLost(userId, amount);
    }

    final gameLabel = gameType == 'coin_flip'
        ? 'Cara ou Coroa'
        : gameType == 'dice'
            ? 'Dado'
            : 'Caça-Níquel';

    await _insertTransaction(
      db: db,
      userId: userId,
      type: outcome == 'win' ? 'bet_win' : 'bet_loss',
      amount: delta,
      description:
          '$gameLabel — ${outcome == "win" ? "Vitória" : "Derrota"}',
    );
  }

  static Future<List<BetModel>> fetchBets(String userId,
      {int limit = 20}) async {
    final db = await _database;
    final rows = await db.query(
      'bets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToBet).toList();
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  static Future<void> _insertTransaction({
    required Database db,
    required String userId,
    required String type,
    required int amount,
    String? description,
  }) async {
    await db.insert('transactions', {
      'user_id': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<TransactionModel>> fetchTransactions(String userId,
      {int limit = 30}) async {
    final db = await _database;
    final rows = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_rowToTransaction).toList();
  }

  // ── Daily bonus ────────────────────────────────────────────────────────────

  static Future<bool> claimDailyBonus(String userId, int amount) async {
    final db = await _database;
    final rows = await db.query(
      'transactions',
      columns: ['created_at'],
      where: "user_id = ? AND type = 'bonus'",
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final last =
          DateTime.parse(rows.first['created_at'] as String).toLocal();
      final now = DateTime.now();
      if (last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        return false;
      }
    }

    await adjustBalance(userId, amount);
    await _insertTransaction(
      db: db,
      userId: userId,
      type: 'bonus',
      amount: amount,
      description: 'Bônus diário',
    );
    return true;
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  static UserModel _rowToUser(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      username: row['username'] as String,
      displayName: row['display_name'] as String,
      avatarUrl: row['avatar_path'] as String?,
      shekelBalance: row['shekel_balance'] as int,
      totalWon: row['total_won'] as int,
      totalLost: row['total_lost'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static ItemModel _rowToItem(Map<String, dynamic> row) {
    return ItemModel(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String,
      emoji: row['emoji'] as String,
      price: row['price'] as int,
      category: row['category'] as String,
      rarity: row['rarity'] as String,
      isAvailable: (row['is_available'] as int) == 1,
    );
  }

  static BetModel _rowToBet(Map<String, dynamic> row) {
    final detailsStr = row['details'] as String?;
    return BetModel(
      id: row['id'] as int,
      userId: row['user_id'] as String,
      gameType: row['game_type'] as String,
      amount: row['amount'] as int,
      outcome: row['outcome'] as String,
      payout: row['payout'] as int,
      details: detailsStr != null
          ? jsonDecode(detailsStr) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static TransactionModel _rowToTransaction(Map<String, dynamic> row) {
    return TransactionModel(
      id: row['id'] as int,
      userId: row['user_id'] as String,
      type: row['type'] as String,
      amount: row['amount'] as int,
      description: row['description'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
