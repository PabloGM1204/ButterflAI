import 'dart:convert';

/// Clase que contiene la información de una mariposa
class ButterflyInfo {
  /// Nombre común de la mariposa
  final String commonName;

  /// Nombre científico de la mariposa
  final String scientificName;

  /// Descripción de la mariposa
  final String description;

  /// Hábitat de la mariposa
  final List<String> habitat;

  /// Constructor de la clase
  ButterflyInfo({
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.habitat,
  });

  /// Constructor de la clase con valores por defecto
  ButterflyInfo.empty(name)
      : commonName = name,
        scientificName = "Unknown",
        description = "No description available",
        habitat = ["Unknown"];

  /// Método para convertir un JSON en una instancia de ButterflyInfo
  factory ButterflyInfo.fromJson(Map<String, dynamic> json) {
    return ButterflyInfo(
      commonName: json["Nombre común"] ?? "Desconocido",
      scientificName: json["Nombre científico"] ?? "Desconocido",
      description: json["Descripción"] ?? "Sin descripción",
      habitat: List<String>.from(json["Hábitat"] ?? []),
    );
  }

  /// Método para convertir una lista de JSON en una lista de mariposas
  static List<ButterflyInfo> fromJsonList(String jsonStr) {
    final decoded = jsonDecode(utf8.decode(jsonStr.codeUnits));
    return decoded
        .map<ButterflyInfo>((json) => ButterflyInfo.fromJson(json))
        .toList();
  }
}
