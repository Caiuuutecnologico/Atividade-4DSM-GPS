import 'package:flutter/material.dart';

import '../../models/localizacao.dart';
import '../widgets/mapa_localizacoes.dart';

class TelaMapa extends StatelessWidget {
  const TelaMapa({super.key, required this.localizacoes});
  final List<Localizacao> localizacoes;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mapa de localizações')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MapaLocalizacoes(localizacoes: localizacoes),
        ),
      );
}
