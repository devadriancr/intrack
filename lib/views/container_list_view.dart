import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/container_controller.dart';
import '../models/container.dart';
import 'scanned_material_view.dart';

class ContainerListView extends StatefulWidget {
  @override
  _ContainerListViewState createState() => _ContainerListViewState();
}

class _ContainerListViewState extends State<ContainerListView> {
  final ContainerController _controller = ContainerController();
  late Future<List<ContainerModel>> _containers;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    setState(() {
      _containers = _controller.getContainers();
    });
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy')
          .format(parsedDate); // Formato de fecha DD-MM-YYYY
    } catch (e) {
      return date; // Si no se puede parsear la fecha, devuelvo el valor original
    }
  }

  String _formatTime(String time) {
    try {
      // Verificamos si la hora tiene una parte decimal (milisegundos) y la eliminamos
      DateTime parsedTime =
          DateTime.parse('1970-01-01 $time'); // Aseguramos un formato estándar
      return DateFormat('HH:mm:ss')
          .format(parsedTime); // Formato de hora HH:mm:ss
    } catch (e) {
      return time; // Si no se puede parsear la hora, devuelvo el valor original
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CONTENEDORES')),
      body: FutureBuilder<List<ContainerModel>>(
        future: _containers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data!.isEmpty) {
            return Center(child: Text('No containers available.'));
          }

          final containers = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _loadContainers,
            child: ListView.builder(
              itemCount: containers.length,
              itemBuilder: (context, index) {
                final container = containers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0), // Separación de los lados
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0), // Separación interna
                    title: Text(
                      '${container.code}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Text(
                      'Fecha: ${_formatDate(container.arrivalDate)} - Hora: ${_formatTime(container.arrivalTime)}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14.0),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16.0,
                      // color: Colors.blueAccent,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScannedMaterialView(
                            containerId: container.id,
                            containerCode: container.code,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
