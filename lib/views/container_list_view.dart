import 'package:flutter/material.dart';
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

  // Método para cargar contenedores
  Future<void> _loadContainers() async {
    setState(() {
      _containers = _controller.getContainers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contenedores')),
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
            onRefresh:
                _loadContainers, // Actualiza la lista cuando se hace pull down
            child: ListView.builder(
              itemCount: containers.length,
              itemBuilder: (context, index) {
                final container = containers[index];
                return ListTile(
                  title: Text('${container.code}'),
                  subtitle: Text(
                      'Fecha: ${container.arrivalDate} Hora: ${container.arrivalTime}'),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
