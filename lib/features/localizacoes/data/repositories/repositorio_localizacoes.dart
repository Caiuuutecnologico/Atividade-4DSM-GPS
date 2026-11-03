import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/localizacao.dart';
import '../database/banco_localizacoes.dart';
import '../../services/seed_localizacoes.dart';

class RepositorioLocalizacoes {
  RepositorioLocalizacoes({
    BancoLocalizacoes? banco,
    bool? habilitarSeedDemonstracao,
  }) : _banco = banco ?? BancoLocalizacoes.instancia,
       _habilitarSeedForcado = habilitarSeedDemonstracao;

  final BancoLocalizacoes _banco;
  final bool? _habilitarSeedForcado;

  bool get _seedPermitida {
    if (_habilitarSeedForcado != null) return _habilitarSeedForcado;
    final desktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return kDebugMode && (desktop || kIsWeb) && seedDemonstracaoHabilitada;
  }

  /// Tenta inserir a seed apenas na primeira criação do banco e se estiver vazio.
  Future<void> inicializarDesenvolvimento() async {
    final db = await _banco.database;
    if (!_seedPermitida || !_banco.consumirElegibilidadeSeed()) return;

    await db.transaction((transacao) async {
      final existentes = await transacao.query(
        'localizacoes',
        columns: ['id'],
        limit: 1,
      );
      if (existentes.isNotEmpty) return;

      for (final localizacao in localizacoesDeDemonstracao) {
        await _salvarEm(transacao, localizacao);
      }
    });
  }

  /// Reconhece o conjunto completo de registros de demonstração para identificá-lo na UI.
  Future<bool> possuiSeedDemonstracao() async {
    final db = await _banco.database;
    for (final localizacao in localizacoesDeDemonstracao) {
      final mapa = localizacao.toMap();
      final linhas = await db.query(
        'localizacoes',
        columns: ['id'],
        where:
            'latitude = ? AND longitude = ? AND precisao = ? AND data_hora = ?',
        whereArgs: [
          mapa['latitude'],
          mapa['longitude'],
          mapa['precisao'],
          mapa['data_hora'],
        ],
        limit: 1,
      );
      if (linhas.isEmpty) return false;
    }
    return true;
  }

  Future<List<Localizacao>> listar() async {
    final db = await _banco.database;
    final linhas = await db.query(
      'localizacoes',
      orderBy: 'data_hora DESC, id DESC',
      limit: 100,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  Future<Localizacao> salvar(Localizacao localizacao) async {
    final db = await _banco.database;
    return _salvarEm(db, localizacao);
  }

  Future<Localizacao> _salvarEm(
    DatabaseExecutor executor,
    Localizacao localizacao,
  ) async {
    final id = await executor.insert('localizacoes', localizacao.toMap());
    return Localizacao(
      id: id,
      latitude: localizacao.latitude,
      longitude: localizacao.longitude,
      dataHora: localizacao.dataHora,
      precisao: localizacao.precisao,
    );
  }

  Future<void> remover(int id) async {
    final db = await _banco.database;
    await db.delete('localizacoes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> limparTudo() async {
    final db = await _banco.database;
    await db.delete('localizacoes');
  }
}
