import 'package:atividade_avaliativa_dispositivos_moveis/app.dart';
import 'package:flutter/widgets.dart';

import 'features/localizacoes/data/database/sqlite_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSqliteFactory();

  runApp(const AplicacaoLocalizacoes());
}
