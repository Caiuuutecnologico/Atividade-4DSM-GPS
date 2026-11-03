import '../models/localizacao.dart';

/// Mantém em memória a última lista usada pela visualização do mapa.
class CacheMapa {
  List<Localizacao> _localizacoes = const [];

  List<Localizacao> get localizacoes => List.unmodifiable(_localizacoes);

  void atualizar(Iterable<Localizacao> localizacoes) {
    _localizacoes = List.unmodifiable(localizacoes);
  }

  void limpar() => _localizacoes = const [];
}
