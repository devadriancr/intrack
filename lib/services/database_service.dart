import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  late Database _database;

  // Inicializar la base de datos
  Future<void> initializeDatabase() async {
    String path = p.join(await getDatabasesPath(), 'scanned_material.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scanned_material (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            part_no TEXT,
            part_qty INTEGER,
            supplier TEXT,
            serial TEXT,
            container_id INTEGER,
            status BOOLEAN,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
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

  // Insertar datos en la base de datos
  Future<void> insertData(int containerId, String partNo, int partQty,
      String supplier, String serial) async {
    final createdAt = DateTime.now().toIso8601String();
    await _database.insert('scanned_material', {
      'part_no': partNo,
      'part_qty': partQty,
      'supplier': supplier,
      'serial': serial,
      'container_id': containerId,
      'status': true,
      'created_at': createdAt, // Insertar la fecha y hora exacta
    });
  }

  // Cargar registros desde la base de datos
  Future<List<Map<String, dynamic>>> loadRecords(int containerId) async {
    return await _database.query(
      'scanned_material',
      where: 'container_id = ?',
      whereArgs: [containerId],
    );
  }

  // Cerrar la base de datos
  Future<void> closeDatabase() async {
    await _database.close();
  }
}
