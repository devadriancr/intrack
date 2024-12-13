import 'package:flutter/material.dart';
import 'package:intrack/services/database_service.dart';
import 'package:intl/intl.dart';

class ScannedMaterialView extends StatefulWidget {
  final int containerId;
  final String containerCode;

  const ScannedMaterialView({
    Key? key,
    required this.containerId,
    required this.containerCode,
  }) : super(key: key);

  @override
  _ScannedMaterialViewState createState() => _ScannedMaterialViewState();
}

class _ScannedMaterialViewState extends State<ScannedMaterialView> {
  late DatabaseService _databaseService;
  final TextEditingController _inputController = TextEditingController();
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _initializeDatabase(); // Llamar a un método que espera la inicialización de la base de datos
  }

  Future<void> _initializeDatabase() async {
    await _databaseService
        .initializeDatabase(); // Esperar a que la base de datos esté lista
    _loadRecords(); // Cargar los registros después de que la base de datos esté inicializada
  }

  // Cargar los registros desde la base de datos filtrados por container_id
  // y ordenados por created_at de forma descendente
  Future<void> _loadRecords() async {
    try {
      final records = await _databaseService.loadRecords(widget.containerId);
      setState(() {
        _records = records;
      });

      // Agregar depuración para ver si los datos se cargaron correctamente
      print('Registros cargados: ${_records.length}'); // Depuración
    } catch (e) {
      // Mostrar un mensaje de error si algo sale mal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los registros: $e')),
      );
    }
  }

  // Insertar los datos en la base de datos
  Future<void> _insertData(
      String partNo, int partQty, String supplier, String serial) async {
    final isRegistered = await _databaseService.isMaterialRegistered(
      widget.containerId,
      partNo,
      partQty,
      supplier,
      serial,
    );

    if (isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este material ya está registrado.')),
      );
    } else {
      await _databaseService.insertData(
        widget.containerId,
        partNo,
        partQty,
        supplier,
        serial,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados en la base de datos.')),
      );
      _loadRecords(); // Recargar los registros después de insertar
    }
  }

  // Procesar la entrada del usuario
  void _processInput() {
    String input = _inputController.text.trim().toUpperCase();
    List<String> dataParts = input.split(',');

    if (dataParts.length > 13) {
      int partQty = int.tryParse(dataParts[10]) ?? 0;
      String supplier = dataParts[11];
      String serial = dataParts[13];
      String partNo = dataParts.last;

      _insertData(partNo, partQty, supplier, serial);

      _inputController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de entrada inválido.')),
      );
    }
  }

  // Función para formatear la fecha
  String _formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.containerCode),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              autofocus: true,
              onSubmitted: (value) => _processInput(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Escanear código QR',
                hintText: 'Ingrese el código QR aquí...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processInput,
              child: const Text('Procesar'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _records.isEmpty
                  ? const Center(child: Text('No hay registros aún.'))
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // Esto hace que el texto se distribuya entre los extremos
                              children: [
                                Text(record['part_no'] ?? '',
                                    style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold)), // Texto a la izquierda
                                Text(record['part_qty'].toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight
                                            .bold)), // Número de parte a la derecha
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Serial: ${record['supplier']}${record['serial']}'),
                                // Text(
                                //     'Fecha: ${_formatTimestamp(record['created_at'] ?? '')}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _databaseService.closeDatabase();
    super.dispose();
  }
}
