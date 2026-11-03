import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:atividade_avaliativa_dispositivos_moveis/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:atividade_avaliativa_dispositivos_moveis/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:atividade_avaliativa_dispositivos_moveis/features/localizacoes/models/localizacao.dart';

void main() {
  late _BancoEmMemoria bancoMemoria;
  late RepositorioLocalizacoes repositorio;

  setUp(() {
    bancoMemoria = _BancoEmMemoria();
    repositorio = RepositorioLocalizacoes(
      banco: BancoLocalizacoes.forTesting(bancoMemoria),
    );
  });

  test(
    'consulta ordenada limita os resultados aos 100 mais recentes',
    () async {
      for (var minuto = 0; minuto < 105; minuto++) {
        await repositorio.salvar(_localizacao(minuto));
      }

      final resultados = await repositorio.listar();

      expect(bancoMemoria.ultimoLimite, 100);
      expect(bancoMemoria.ultimaOrdenacao, 'data_hora DESC, id DESC');
      expect(resultados, hasLength(100));
      expect(resultados.first.dataHora, DateTime.utc(2025, 1, 1, 1, 44));
      expect(resultados.last.dataHora, DateTime.utc(2025, 1, 1, 0, 5));
      for (var i = 1; i < resultados.length; i++) {
        expect(
          resultados[i - 1].dataHora.isAfter(resultados[i].dataHora),
          isTrue,
        );
      }
    },
  );

  test('limparTudo remove todos os registros sem filtro', () async {
    await repositorio.salvar(_localizacao(1));
    await repositorio.salvar(_localizacao(2));

    await repositorio.limparTudo();

    expect(bancoMemoria.linhas, isEmpty);
    expect(bancoMemoria.ultimaClausulaDelete, isNull);
    expect(await repositorio.listar(), isEmpty);
  });

  test(
    'seed insere uma vez no banco recém-criado e preserva registros',
    () async {
      final bancoNovo = _BancoEmMemoria();
      final repositorioNovo = RepositorioLocalizacoes(
        banco: BancoLocalizacoes.forTesting(
          bancoNovo,
          criadoNestaExecucao: true,
        ),
        habilitarSeedDemonstracao: true,
      );

      await repositorioNovo.inicializarDesenvolvimento();
      await repositorioNovo.inicializarDesenvolvimento();

      expect(bancoNovo.linhas, hasLength(4));
      expect(bancoNovo.linhas.map((linha) => linha['id']), [1, 2, 3, 4]);
      expect(await repositorioNovo.possuiSeedDemonstracao(), isTrue);

      final bancoComDados = _BancoEmMemoria();
      await bancoComDados.insert('localizacoes', {
        'latitude': 1.25,
        'longitude': 2.5,
        'precisao': 7.0,
        'data_hora': '2026-10-30T13:00:00.000Z',
      });
      final registroOriginal = Map<String, Object?>.from(
        bancoComDados.linhas.single,
      );
      final repositorioExistente = RepositorioLocalizacoes(
        banco: BancoLocalizacoes.forTesting(
          bancoComDados,
          criadoNestaExecucao: true,
        ),
        habilitarSeedDemonstracao: true,
      );

      await repositorioExistente.inicializarDesenvolvimento();

      expect(bancoComDados.linhas, [registroOriginal]);
    },
  );
}

Localizacao _localizacao(int minuto) => Localizacao(
  latitude: -23.5,
  longitude: -46.6,
  dataHora: DateTime.utc(2025, 1, 1).add(Duration(minutes: minuto)),
  precisao: 3.5,
);

class _BancoEmMemoria implements Database {
  final List<Map<String, Object?>> linhas = [];
  int _proximoId = 1;
  int? ultimoLimite;
  String? ultimaOrdenacao;
  String? ultimaClausulaDelete;

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) async => action(_TransacaoEmMemoria(this));

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = _proximoId++;
    linhas.add({...values, 'id': id});
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    ultimoLimite = limit;
    ultimaOrdenacao = orderBy;
    var resultados = [...linhas];
    if (whereArgs != null) {
      final colunas = where!
          .split(' AND ')
          .map((condicao) => condicao.split(' = ').first)
          .toList();
      resultados = resultados.where((linha) {
        for (var i = 0; i < whereArgs.length; i++) {
          if (linha[colunas[i]] != whereArgs[i]) return false;
        }
        return true;
      }).toList();
    }
    resultados.sort((a, b) {
      final dataA = a['data_hora'] as String? ?? '';
      final dataB = b['data_hora'] as String? ?? '';
      final comparacao = dataB.compareTo(dataA);
      return comparacao != 0
          ? comparacao
          : (b['id'] as int).compareTo(a['id'] as int);
    });
    return resultados.take(limit ?? resultados.length).toList();
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    ultimaClausulaDelete = where;
    if (where == null) {
      final quantidade = linhas.length;
      linhas.clear();
      return quantidade;
    }
    throw UnsupportedError('Este fake só implementa a limpeza total.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TransacaoEmMemoria implements Transaction {
  _TransacaoEmMemoria(this.banco);

  final _BancoEmMemoria banco;

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) => banco.insert(
    table,
    values,
    nullColumnHack: nullColumnHack,
    conflictAlgorithm: conflictAlgorithm,
  );

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) => banco.query(
    table,
    distinct: distinct,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    groupBy: groupBy,
    having: having,
    orderBy: orderBy,
    limit: limit,
    offset: offset,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
