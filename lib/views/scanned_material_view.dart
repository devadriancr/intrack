import 'package:flutter/material.dart';
import 'package:intrack/services/database_service.dart';
import 'package:intrack/services/api_service.dart';

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
  late ApiService _apiService;
  final TextEditingController _inputController = TextEditingController();
  late FocusNode _focusNode;
  List<Map<String, dynamic>> _records = [];
  bool _isProcessing = false;
  String? _partNo;
  int? _partQty;
  String? _supplier;
  String? _serial;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _databaseService = DatabaseService();
    _apiService = ApiService();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _databaseService.initializeDatabase();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await _databaseService.loadRecords(widget.containerId);
      setState(() {
        _records = records;
      });
      print('Registros cargados: ${_records.length}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los registros: $e')),
      );
    }
  }

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
      _loadRecords();
    }
  }

  Future<void> _uploadScanData() async {
    if (_partNo != null &&
        _partQty != null &&
        _supplier != null &&
        _serial != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final response = await _apiService.uploadScannedMaterial(
          _partNo!,
          _partQty!,
          _supplier!,
          _serial!,
          widget.containerId,
        );

        if (response) {
          await _databaseService.updateStatus(_partNo!, widget.containerId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Escaneo cargado correctamente.')),
          );
          _clearFields();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar el escaneo.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el escaneo: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _processInput() {
    String input = _inputController.text.trim().toUpperCase();
    List<String> dataParts = input.split(',');

    if (dataParts.length > 13) {
      setState(() {
        _partQty = int.tryParse(dataParts[10]) ?? 0;
        _supplier = dataParts[11];
        _serial = dataParts[13];
        _partNo = dataParts.last;
      });

      _insertData(_partNo!, _partQty!, _supplier!, _serial!);

      _inputController.clear();
      _focusNode.requestFocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de entrada inválido.')),
      );
    }
  }

  void _clearFields() {
    setState(() {
      _partNo = null;
      _partQty = null;
      _supplier = null;
      _serial = null;
    });
    _inputController.clear();
    _focusNode.requestFocus();
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
              focusNode: _focusNode,
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
              onPressed: _isProcessing ? null : _uploadScanData,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Cargar escaneo'),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(record['part_no'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(record['part_qty'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Serial: ${record['supplier']}${record['serial']}'),
                                Text('Estado: ${record['status']}'),
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
    _focusNode.dispose();
    _databaseService.closeDatabase();
    super.dispose();
  }
}
