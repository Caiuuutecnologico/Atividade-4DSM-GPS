import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key, required this.localizacoes});

  final List<Localizacao> localizacoes;

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final _controlador = MapController();
  final _repositorio = RepositorioLocalizacoes();
  final _provedorDeTiles = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 100 * 1024 * 1024,
    ),
  );
  late List<Localizacao> _localizacoes;
  bool _carregando = false;
  bool _mapaPronto = false;

  @override
  void initState() {
    super.initState();
    _localizacoes = widget.localizacoes.take(100).toList();
  }

  List<LatLng> get _coordenadas => _localizacoes
      .map((ponto) => LatLng(ponto.latitude, ponto.longitude))
      .toList();

  void _enquadrarPontos() {
    final coordenadas = _coordenadas;
    if (!_mapaPronto || coordenadas.isEmpty) return;
    final todosIguais = coordenadas.every((ponto) =>
        ponto.latitude == coordenadas.first.latitude &&
        ponto.longitude == coordenadas.first.longitude);
    if (todosIguais) {
      _controlador.move(coordenadas.first, 15);
    } else {
      _controlador.fitCamera(CameraFit.coordinates(
        coordinates: coordenadas,
        padding: const EdgeInsets.all(64),
        maxZoom: 16,
      ));
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _atualizar() async {
    setState(() => _carregando = true);
    try {
      final registros = await _repositorio.listar();
      if (!mounted) return;
      setState(() => _localizacoes = registros.take(100).toList());
      WidgetsBinding.instance.addPostFrameCallback((_) => _enquadrarPontos());
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar o mapa: $erro')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiro = _localizacoes.isEmpty
        ? const LatLng(0, 0)
        : LatLng(_localizacoes.first.latitude, _localizacoes.first.longitude);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de localizações'),
        actions: [
          IconButton(
            tooltip: 'Atualizar registros',
            onPressed: _carregando ? null : _atualizar,
            icon: _carregando
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controlador,
            options: MapOptions(
              initialCenter: primeiro,
              initialZoom: 13,
              onMapReady: () {
                _mapaPronto = true;
                _enquadrarPontos();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.atividade_avaliativa_dispositivos_moveis',
                tileProvider: _provedorDeTiles,
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _localizacoes.length; i++)
                    Marker(
                      point: LatLng(_localizacoes[i].latitude, _localizacoes[i].longitude),
                      width: 42,
                      height: 48,
                      child: Icon(
                        Icons.location_on,
                        size: 42,
                        color: i == 0 ? Colors.red : Theme.of(context).colorScheme.primary,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'enquadrar_pontos',
              tooltip: 'Enquadrar todos os pontos',
              onPressed: _enquadrarPontos,
              child: const Icon(Icons.fit_screen),
            ),
          ),
          if (_localizacoes.isEmpty)
            Align(
              alignment: Alignment.topCenter,
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 72, 16, 0),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Nenhuma localização salva para exibir.'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
