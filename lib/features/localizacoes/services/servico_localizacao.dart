import 'package:geolocator/geolocator.dart';

import '../models/localizacao.dart';

class ServicoLocalizacao {
  Future<Localizacao> obterLocalizacaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Ative o serviço de localização do dispositivo.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw Exception('A permissão de localização foi negada.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception('Permissão bloqueada. Habilite-a nas configurações.');
    }

    final posicao = await Geolocator.getCurrentPosition();
    return Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      dataHora: posicao.timestamp,
    );
  }
}
