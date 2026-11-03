import 'package:flutter_test/flutter_test.dart';
import 'package:atividade_avaliativa_dispositivos_moveis/features/localizacoes/models/localizacao.dart';

void main() {
  group('Localizacao', () {
    test('normaliza e serializa data e hora em UTC', () {
      final horarioComFuso = DateTime.parse('2025-03-10T09:30:00-03:00');
      final localizacao = Localizacao(
        latitude: -23.5,
        longitude: -46.6,
        dataHora: horarioComFuso,
        precisao: 4.25,
      );

      final mapa = localizacao.toMap();
      final restaurada = Localizacao.fromMap(mapa);

      expect(localizacao.dataHora.isUtc, isTrue);
      expect(mapa['data_hora'], '2025-03-10T12:30:00.000Z');
      expect(restaurada.dataHora.isUtc, isTrue);
      expect(restaurada.dataHora, DateTime.utc(2025, 3, 10, 12, 30));
      expect(restaurada.precisao, 4.25);
    });

    test('converte precisão numérica do SQLite para double', () {
      final localizacao = Localizacao.fromMap({
        'id': 8,
        'latitude': -23,
        'longitude': -46,
        'data_hora': '2025-03-10T12:30:00Z',
        'precisao': 5,
      });

      expect(localizacao.precisao, 5.0);
      expect(localizacao.id, 8);
    });
  });
}
