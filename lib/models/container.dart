class ContainerModel {
  final int id;
  final String code;
  final String arrivalDate;
  final String arrivalTime;

  ContainerModel({
    required this.id,
    required this.code,
    required this.arrivalDate,
    required this.arrivalTime,
  });

  // Convertir JSON a objeto
  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      id: json['id'],
      code: json['code'],
      arrivalDate: json['arrival_date'],
      arrivalTime: json['arrival_time'],
    );
  }
}
