import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  BancoLocalizacoes._();
  factory BancoLocalizacoes.forTesting(
    Database database, {
    bool criadoNestaExecucao = false,
  }) {
    final banco = BancoLocalizacoes._();
    banco._banco = database;
    banco._criadoNestaExecucao = criadoNestaExecucao;
    return banco;
  }
  static final BancoLocalizacoes instancia = BancoLocalizacoes._();
  static const _nomeBanco = 'localizacoes.db';
  Database? _banco;
  bool _criadoNestaExecucao = false;
  bool _seedTentada = false;

  bool consumirElegibilidadeSeed() {
    if (!_criadoNestaExecucao || _seedTentada) return false;
    _seedTentada = true;
    return true;
  }

  Future<Database> get database async {
    if (_banco != null) return _banco!;
    final caminho = p.join(await getDatabasesPath(), _nomeBanco);
    _banco = await openDatabase(
      caminho,
      version: 2,
      onCreate: (db, _) async {
        _criadoNestaExecucao = true;
        await db.execute('''
        CREATE TABLE localizacoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          data_hora TEXT NOT NULL,
          precisao REAL NOT NULL
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE localizacoes_nova (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              data_hora TEXT NOT NULL,
              precisao REAL NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO localizacoes_nova (id, latitude, longitude, data_hora, precisao)
            SELECT id, latitude, longitude, data_hora, COALESCE(precisao, 0.0)
            FROM localizacoes
          ''');
          await db.execute('DROP TABLE localizacoes');
          await db.execute(
            'ALTER TABLE localizacoes_nova RENAME TO localizacoes',
          );

          final registros = await db.query(
            'localizacoes',
            columns: ['id', 'data_hora'],
          );
          for (final registro in registros) {
            final dataUtc = DateTime.parse(registro['data_hora'] as String)
                .toUtc()
                .toIso8601String();
            await db.update(
              'localizacoes',
              {'data_hora': dataUtc},
              where: 'id = ?',
              whereArgs: [registro['id']],
            );
          }
        }
      },
    );
    return _banco!;
  }
}
