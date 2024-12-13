import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  late Database _database;

  Future<void> initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'scanned_materials.db');
    _database = await openDatabase(path, version: 2, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE scanned_material (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      container_id INTEGER,
      part_no TEXT,
      part_qty INTEGER,
      supplier TEXT,
      serial TEXT,
      status INTEGER DEFAULT 1,
      created_at TEXT
    )
    ''');
  }

  // Cargar registros desde la base de datos, filtrados por container_id y status = true, y ordenados por created_at
  Future<List<Map<String, dynamic>>> loadRecords(int containerId) async {
    return await _database.query(
      'scanned_material',
      where:
          'container_id = ? AND status = 1', // Filtrar solo los registros con status = true (1)
      whereArgs: [containerId],
      orderBy: 'created_at DESC', // Ordenar por created_at en orden descendente
    );
  }

  // Verificar si el material ya está registrado
  Future<bool> isMaterialRegistered(int containerId, String partNo, int partQty,
      String supplier, String serial) async {
    final result = await _database.query(
      'scanned_material',
      where:
          'container_id = ? AND part_no = ? AND part_qty = ? AND supplier = ? AND serial = ?',
      whereArgs: [containerId, partNo, partQty, supplier, serial],
    );
    return result.isNotEmpty;
  }

  // Insertar nuevos datos en la base de datos
  Future<void> insertData(int containerId, String partNo, int partQty,
      String supplier, String serial) async {
    await _database.insert('scanned_material', {
      'container_id': containerId,
      'part_no': partNo,
      'part_qty': partQty,
      'supplier': supplier,
      'serial': serial,
      'status': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void closeDatabase() {
    _database.close();
  }
}
