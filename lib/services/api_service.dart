import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/container.dart';

class ApiService {
  static const String baseUrl = "http://192.168.170.133:8000/api/containers";

  // Método para obtener todos los contenedores
  Future<List<ContainerModel>> fetchContainers() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          List<dynamic> containersJson = data['data'];
          return containersJson
              .map((json) => ContainerModel.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception("Error al obtener los datos: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }
}
