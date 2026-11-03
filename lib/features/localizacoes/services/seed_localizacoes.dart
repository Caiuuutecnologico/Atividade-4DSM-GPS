import '../models/localizacao.dart';

/// Pode ser desativado com:
/// --dart-define=LOCALIZACOES_SEED_DEMONSTRACAO=false
const bool seedDemonstracaoHabilitada = bool.fromEnvironment(
  'LOCALIZACOES_SEED_DEMONSTRACAO',
  defaultValue: true,
);

final List<Localizacao> localizacoesDeDemonstracao = [
  Localizacao(
    latitude: -23.550521,
    longitude: -46.633308,
    precisao: 12.5,
    dataHora: DateTime.utc(2026, 10, 30, 14, 30),
  ),
  Localizacao(
    latitude: -23.551842,
    longitude: -46.634912,
    precisao: 8.2,
    dataHora: DateTime.utc(2026, 10, 30, 14, 50),
  ),
  Localizacao(
    latitude: -23.552991,
    longitude: -46.632474,
    precisao: 15.0,
    dataHora: DateTime.utc(2026, 10, 30, 15, 10),
  ),
  Localizacao(
    latitude: -23.554117,
    longitude: -46.636025,
    precisao: 10.8,
    dataHora: DateTime.utc(2026, 10, 30, 15, 30),
  ),
];
