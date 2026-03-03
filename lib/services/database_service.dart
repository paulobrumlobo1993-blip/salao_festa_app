import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/salao.dart';
import '../models/agendamento.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'saloes_festa.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE saloes (
            id TEXT PRIMARY KEY,
            nome TEXT NOT NULL,
            descricao TEXT,
            endereco TEXT,
            telefone TEXT,
            capacidade REAL,
            precoPorHora REAL,
            fotos TEXT,
            criadoEm TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE itens_catalogo (
            id TEXT PRIMARY KEY,
            nome TEXT NOT NULL,
            descricao TEXT,
            preco REAL,
            foto TEXT,
            salaoId TEXT,
            FOREIGN KEY (salaoId) REFERENCES saloes (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE agendamentos (
            id TEXT PRIMARY KEY,
            salaoId TEXT NOT NULL,
            nomeCliente TEXT NOT NULL,
            telefoneCliente TEXT,
            email TEXT,
            dataEvento TEXT NOT NULL,
            horaInicioH INTEGER,
            horaInicioM INTEGER,
            horaFimH INTEGER,
            horaFimM INTEGER,
            tipoEvento TEXT,
            numeroPessoas INTEGER,
            valorTotal REAL,
            status TEXT,
            observacoes TEXT,
            criadoEm TEXT,
            FOREIGN KEY (salaoId) REFERENCES saloes (id)
          )
        ''');
      },
    );
  }

  // ─── SALÕES ────────────────────────────────────────
  Future<List<Salao>> getSaloes() async {
    final db = await database;
    final maps = await db.query('saloes', orderBy: 'nome ASC');
    final saloes = maps.map((m) => Salao.fromMap(m)).toList();
    for (var s in saloes) {
      s.itens = await getItensBySalao(s.id);
    }
    return saloes;
  }

  Future<Salao?> getSalaoById(String id) async {
    final db = await database;
    final maps = await db.query('saloes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final salao = Salao.fromMap(maps.first);
    salao.itens = await getItensBySalao(id);
    return salao;
  }

  Future<void> insertSalao(Salao salao) async {
    final db = await database;
    await db.insert(
      'saloes',
      salao.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSalao(Salao salao) async {
    final db = await database;
    await db.update(
      'saloes',
      salao.toMap(),
      where: 'id = ?',
      whereArgs: [salao.id],
    );
  }

  Future<void> deleteSalao(String id) async {
    final db = await database;
    await db.delete('agendamentos', where: 'salaoId = ?', whereArgs: [id]);
    await db.delete('itens_catalogo', where: 'salaoId = ?', whereArgs: [id]);
    await db.delete('saloes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ITENS CATÁLOGO ────────────────────────────────
  Future<List<ItemCatalogo>> getItensBySalao(String salaoId) async {
    final db = await database;
    final maps = await db.query(
      'itens_catalogo',
      where: 'salaoId = ?',
      whereArgs: [salaoId],
    );
    return maps.map((m) => ItemCatalogo.fromMap(m)).toList();
  }

  Future<void> insertItem(ItemCatalogo item) async {
    final db = await database;
    await db.insert(
      'itens_catalogo',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItem(ItemCatalogo item) async {
    final db = await database;
    await db.update(
      'itens_catalogo',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('itens_catalogo', where: 'id = ?', whereArgs: [id]);
  }

  // ─── AGENDAMENTOS ──────────────────────────────────
  Future<List<Agendamento>> getAgendamentos() async {
    final db = await database;
    final maps = await db.query('agendamentos', orderBy: 'dataEvento ASC');
    return maps.map((m) => Agendamento.fromMap(m)).toList();
  }

  Future<List<Agendamento>> getAgendamentosBySalao(String salaoId) async {
    final db = await database;
    final maps = await db.query(
      'agendamentos',
      where: 'salaoId = ?',
      whereArgs: [salaoId],
      orderBy: 'dataEvento ASC',
    );
    return maps.map((m) => Agendamento.fromMap(m)).toList();
  }

  Future<List<Agendamento>> getAgendamentosByData(DateTime data) async {
    final db = await database;
    final dateStr = data.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'agendamentos',
      where: 'dataEvento LIKE ?',
      whereArgs: ['$dateStr%'],
    );
    return maps.map((m) => Agendamento.fromMap(m)).toList();
  }

  Future<List<DateTime>> getDatasOcupadas(String salaoId) async {
    final db = await database;
    final maps = await db.query(
      'agendamentos',
      columns: ['dataEvento'],
      where: 'salaoId = ? AND status != ?',
      whereArgs: [salaoId, 'cancelado'],
    );
    return maps.map((m) => DateTime.parse(m['dataEvento'] as String)).toList();
  }

  Future<void> insertAgendamento(Agendamento agendamento) async {
    final db = await database;
    await db.insert(
      'agendamentos',
      agendamento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAgendamento(Agendamento agendamento) async {
    final db = await database;
    await db.update(
      'agendamentos',
      agendamento.toMap(),
      where: 'id = ?',
      whereArgs: [agendamento.id],
    );
  }

  Future<void> deleteAgendamento(String id) async {
    final db = await database;
    await db.delete('agendamentos', where: 'id = ?', whereArgs: [id]);
  }
}
