import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/servico_localizacao.dart';
import 'tela_localizacoes.dart';
import 'tela_mapa.dart';

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  final _repositorio = RepositorioLocalizacoes();
  final _servico = ServicoLocalizacao();
  StreamSubscription<Position>? _assinatura;
  bool _inicializando = true;
  bool _coletando = false;
  int _total = 0;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      await _repositorio.inicializarDesenvolvimento();
      final itens = await _repositorio.listar();
      if (mounted) setState(() => _total = itens.length);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro.toString());
    } finally {
      if (mounted) setState(() => _inicializando = false);
    }
  }

  Future<void> _iniciarColeta() async {
    try {
      await _servico.verificarPermissao();
      final configuracoes = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 20),
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationTitle: 'Coleta de localização ativa',
                notificationText: 'Registrando suas posições em segundo plano.',
                notificationChannelName: 'Coleta de localização',
                notificationIcon: AndroidResource(
                  name: 'ic_localizacoes',
                  defType: 'mipmap',
                ),
                setOngoing: true,
              ),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            );
      final stream = Geolocator.getPositionStream(
        locationSettings: configuracoes,
      );
      _assinatura = stream.listen((posicao) async {
        final localizacao = Localizacao(
          latitude: posicao.latitude,
          longitude: posicao.longitude,
          precisao: posicao.accuracy,
          dataHora: posicao.timestamp,
        );
        try {
          await _repositorio.salvar(localizacao);
          if (mounted) setState(() => _total++);
        } catch (erro) {
          _mostrarErro(erro);
          await _pararColeta();
        }
      }, onError: (Object erro) {
        _mostrarErro(erro);
        _pararColeta();
      });
      if (mounted) setState(() => _coletando = true);
    } catch (erro) {
      _mostrarErro(erro);
    }
  }

  Future<void> _pararColeta() async {
    await _assinatura?.cancel();
    _assinatura = null;
    if (mounted) setState(() => _coletando = false);
  }

  void _mostrarErro(Object erro) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(erro.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<List<Localizacao>> _obterLocalizacoes() => _repositorio.listar();

  Future<void> _abrirMapa() async {
    final itens = await _obterLocalizacoes();
    if (!mounted) return;
    if (itens.isEmpty) {
      _mostrarErro(Exception('Ainda não há localizações salvas para exibir.'));
      return;
    }
    await Navigator.push<void>(context, MaterialPageRoute(
      builder: (_) => TelaMapa(localizacoes: itens),
    ));
  }

  Future<void> _abrirPermissoes() async {
    var permissao = await Geolocator.checkPermission();
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permissões de localização'),
        content: Text('Permissão: ${_nomePermissao(permissao)}\n'
            'Serviço de localização: ${servicoAtivo ? 'ativado' : 'desativado'}'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              permissao = await Geolocator.requestPermission();
              if (mounted) setState(() {});
              _mostrarErro(Exception('Permissão: ${_nomePermissao(permissao)}'));
            },
            child: const Text('Solicitar permissão'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Geolocator.openAppSettings();
            },
            child: const Text('Abrir configurações'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Configurações de localização'),
          ),
        ],
      ),
    );
  }

  String _nomePermissao(LocationPermission permissao) => switch (permissao) {
    LocationPermission.denied => 'não concedida',
    LocationPermission.deniedForever => 'bloqueada nas configurações',
    LocationPermission.whileInUse => 'durante o uso',
    LocationPermission.always => 'sempre',
    LocationPermission.unableToDetermine => 'indeterminada',
  };

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas localizações')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cores.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(children: [
                  Icon(_coletando ? Icons.gps_fixed : Icons.location_on_outlined,
                      size: 56, color: cores.onPrimaryContainer),
                  const SizedBox(height: 12),
                  Text(_coletando ? 'Coleta em andamento' : 'Olá! Pronto para começar?',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(_inicializando ? 'Carregando histórico…' : '$_total localização(ões) no histórico',
                      textAlign: TextAlign.center),
                ]),
              ),
              const SizedBox(height: 24),
              if (_coletando)
                FilledButton.icon(
                  onPressed: _pararColeta,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Parar coleta'),
                  style: FilledButton.styleFrom(backgroundColor: cores.error,
                      foregroundColor: cores.onError, padding: const EdgeInsets.all(16)),
                )
              else
                FilledButton.icon(
                  onPressed: _inicializando ? null : _iniciarColeta,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Iniciar coleta'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push<void>(context,
                    MaterialPageRoute(builder: (_) => TelaLocalizacoes(coletaAtiva: _coletando))),
                icon: const Icon(Icons.history), label: const Text('Consultar histórico'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _abrirMapa,
                icon: const Icon(Icons.map_outlined), label: const Text('Ver mapa'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _abrirPermissoes,
                icon: const Icon(Icons.location_searching),
                label: const Text('Configurações de permissão'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                Text(_erro!, style: TextStyle(color: cores.error), textAlign: TextAlign.center),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
