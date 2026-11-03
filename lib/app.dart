import 'package:flutter/material.dart';

import 'features/localizacoes/presentation/screens/tela_localizacoes.dart';

class AplicacaoLocalizacoes extends StatelessWidget {
  const AplicacaoLocalizacoes({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Minhas localizações',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const TelaLocalizacoes(),
      );
}
