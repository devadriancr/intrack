import '../models/container.dart';
import '../services/api_service.dart';

class ContainerController {
  final ApiService _apiService = ApiService();

  Future<List<ContainerModel>> getContainers() async {
    return await _apiService.fetchContainers();
  }
}
