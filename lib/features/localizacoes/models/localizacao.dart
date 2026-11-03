class Localizacao {
  Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required DateTime dataHora,
    required this.precisao,
  }) : dataHora = dataHora.toUtc();

  final int? id;
  final double latitude;
  final double longitude;
  final DateTime dataHora;
  final double precisao;

  Map<String, Object?> toMap() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'data_hora': dataHora.toUtc().toIso8601String(),
        'precisao': precisao,
      };

  factory Localizacao.fromMap(Map<String, Object?> map) => Localizacao(
        id: map['id'] as int?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        dataHora: DateTime.parse(map['data_hora'] as String).toUtc(),
        precisao: (map['precisao'] as num).toDouble(),
      );
}
