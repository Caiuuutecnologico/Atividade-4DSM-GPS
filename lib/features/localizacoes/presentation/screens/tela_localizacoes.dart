import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/repositorio_localizacoes.dart';
import '../../models/localizacao.dart';
import '../../services/cache_mapa.dart';
import '../widgets/item_localizacao.dart';
import 'tela_coleta.dart';
import 'tela_mapa.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key});

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final _repositorio = RepositorioLocalizacoes();
  final _cacheMapa = CacheMapa();
  late Future<List<Localizacao>> _localizacoes;
  bool _exibirAvisoDemonstracao = false;

  @override
  void initState() {
    super.initState();
    _localizacoes = _carregarInicialmente();
  }

  Future<List<Localizacao>> _carregarInicialmente() async {
    await _repositorio.inicializarDesenvolvimento();
    return _carregarRegistros();
  }

  Future<List<Localizacao>> _carregarRegistros() async {
    final registros = await _repositorio.listar();
    final demonstracao = await _repositorio.possuiSeedDemonstracao();
    if (mounted) setState(() => _exibirAvisoDemonstracao = demonstracao);
    return registros;
  }

  void _recarregar() => setState(() => _localizacoes = _carregarRegistros());

  Future<void> _abrirColeta() async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TelaColeta(repositorio: _repositorio)),
    );
    if (salvou == true) _recarregar();
  }

  Future<void> _abrirMapa(List<Localizacao> localizacoes) async {
    _cacheMapa.atualizar(localizacoes);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TelaMapa(localizacoes: _cacheMapa.localizacoes),
      ),
    );
  }

  Future<void> _confirmarLimpeza() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar localizações?'),
        content: const Text('Todos os registros salvos serão removidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      await _repositorio.limparTudo();
      _cacheMapa.limpar();
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Minhas localizações'),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _recarregar,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Localizacao>>(
      future: _localizacoes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EstadoDeErro(
            erro: snapshot.error.toString(),
            onTentarNovamente: _recarregar,
          );
        }
        final itens = snapshot.data ?? const <Localizacao>[];
        if (itens.isEmpty) {
          return _EstadoVazio(onColetar: _abrirColeta);
        }
        final deslocamento = _exibirAvisoDemonstracao ? 1 : 0;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: itens.length + 1 + deslocamento,
          itemBuilder: (context, index) {
            if (_exibirAvisoDemonstracao && index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.science_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DADOS DE DEMONSTRAÇÃO · Registros fictícios para visualizar a interface; não representam sua localização atual.',
                      ),
                    ),
                  ],
                ),
              );
            }
            if (index == deslocamento) {
              return Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _confirmarLimpeza,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Limpar tudo'),
                ),
              );
            }
            final item = itens[index - deslocamento - 1];
            return ItemLocalizacao(
              localizacao: item,
              onExcluir: item.id == null
                  ? null
                  : () async {
                      await _repositorio.remover(item.id!);
                      _recarregar();
                    },
            );
          },
        );
      },
    ),
    floatingActionButton: FutureBuilder<List<Localizacao>>(
      future: _localizacoes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'mapa',
              onPressed: () => _abrirMapa(snapshot.data!),
              tooltip: 'Ver mapa',
              child: const Icon(Icons.map_outlined),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'coletar',
              onPressed: _abrirColeta,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Coletar'),
            ),
          ],
        );
      },
    ),
  );
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.onColetar});

  final VoidCallback onColetar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cores.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 64,
                    color: cores.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Suas localizações começam aqui',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Registre sua posição atual para criar seu histórico e visualizar os pontos no mapa.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: cores.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onColetar,
                icon: const Icon(Icons.my_location),
                label: const Text('Registrar primeira localização'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoDeErro extends StatelessWidget {
  const _EstadoDeErro({required this.erro, required this.onTentarNovamente});

  final String erro;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Não foi possível abrir seu histórico',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tente carregar os registros novamente.',
            textAlign: TextAlign.center,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            SelectableText(
              erro,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onTentarNovamente,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}
